local Component = require 'modules.component'
local font = require 'components.font'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local msgBus = require 'components.msg-bus'
local GuiNode = require 'components.gui.gui-node'
local collisionObject = require 'modules.collision'
local scale = require 'config.config'.scaleFactor
local noop = require 'utils.noop'
local f = require 'utils.functional'
local InputContext = require 'modules.input-context'
local min, max = math.min, math.max
local O = require 'utils.object-utils'

local COLLISION_CROSS = 'cross'
local mouseCollisionFilter = function()
  return COLLISION_CROSS
end

local function toggleTextInput(enabled)
  love.keyboard.setTextInput(enabled)
end
msgBus.on(msgBus.SET_TEXT_INPUT, toggleTextInput)
msgBus.send(msgBus.SET_TEXT_INPUT, false)

local guiType = {
  INTERACT = 'INTERACT', -- a stateless gui node used only for event listening
  BUTTON = 'BUTTON',
  TOGGLE = 'TOGGLE',
  TEXT_INPUT = 'TEXT_INPUT',
  LIST = 'LIST',
}

local function getFocusedEntity()
  for id,entity in pairs(Component.groups.gui.getAll()) do
    if entity.focused then
      return entity
    end
  end
end

msgBus.on(msgBus.KEY_PRESSED, function(msg)
  local entity = getFocusedEntity()
  if entity then
    entity:onKeyPress(msg)
  end
end)

local Gui = {
  group = groups.gui,
  isGui = true,
  -- props
  x = 1,
  y = 1,
  -- inputContext = 'gui', -- the input context to set when the entity is hovered
  onClick = noop,
  onKeyPress = noop,
  onChange = noop,
  onCreate = noop,
  onFocus = noop,
  onBlur = noop,
  onScroll = noop,
  onPointerDown = noop,
  onPointerEnter = noop,
  onPointerLeave = noop,
  onUpdate = noop,
  onPointerMove = noop,
  onWheel = noop,
  onFinal = noop,
  collision = true,
  collisionGroup = nil,
  scale = 1,
  getMousePosition = function(self)
    return love.mouse.getX() / self.scale, love.mouse.getY() / self.scale
  end,
  render = noop,
  type = guiType.INTERACT,

  -- for LIST type to define what axis is scrollable
  scrollableX = false,
  scrollableY = true,
  -- scroll limits. The value here represents how far you can scroll in each direction.
  scrollHeight = 0,
  scrollWidth = 0,
  scrollSpeed = 1,
  -- array of children for the LIST component
  children = {},

  checked = false,
  text = '',

  -- built-in state; these should not be externally mutated
  hovered = false,
  focused = false,
  scrollTop = 0,
  scrollLeft = 0,
  eventsDisabled = false,
  prevHovered = false,

  -- statics
  types = guiType
}

local function handleFocusChange(self, newFocusState)
  local isFocusChange = self.focused ~= newFocusState
  self.focused = newFocusState
  if isFocusChange then
    if self.focused then
      self.onFocus(self)
    else
      self.onBlur(self)
    end

    if guiType.TEXT_INPUT == self.type then
      msgBus.send(msgBus.SET_TEXT_INPUT, self.focused)
    end
  end
end

function Gui.setFocus(entity)
  local focusedEntity = getFocusedEntity()
  if focusedEntity then
    handleFocusChange(focusedEntity, false)
  end
  handleFocusChange(entity, true)
end

local function handleScroll(self, dx, dy)
  self.scrollLeft = self.scrollableX and min(0, self.scrollLeft - dx * self.scrollSpeed) or 0
  local maxScrollLeft = -self.scrollWidth
  local maxScrollLeftReached = self.scrollLeft <= maxScrollLeft
  if maxScrollLeftReached then
    self.scrollLeft = maxScrollLeft
  end

  self.scrollTop = self.scrollableY and min(0, self.scrollTop + dy * self.scrollSpeed) or 0
  local maxScrollTop = -self.scrollHeight
  local maxScrollTopReached = self.scrollTop <= maxScrollTop
  if maxScrollTopReached then
    self.scrollTop = maxScrollTop
  end

  self.scrollNode:setPosition(
    self.scrollNode.parent.x + self.scrollLeft,
    self.scrollNode.parent.y + self.scrollTop
  )
  self.onScroll(self)
end

local function triggerEvents(c, msgValue, msgType)
  local self = c

  if msgBus.MOUSE_WHEEL_MOVED == msgType and self.hovered then
    self.onWheel(self, msgValue)
    if guiType.LIST == self.type then
      handleScroll(self, msgValue[1], msgValue[2])
    end
  end

  if msgBus.MOUSE_CLICKED == msgType then
    if self.hovered then
      local mx, my = self:getMousePosition()
      self.onClick(self, O.assign({}, msgValue, {x = mx, y = my}))

      if guiType.TOGGLE == self.type then
        self.checked = not self.checked
        self.onChange(self, self.checked)
      end
    end
  end

  if msgBus.MOUSE_PRESSED == msgType then
    handleFocusChange(self, self.hovered)
  end

  if self.hovered and love.mouse.isDown(1) then
    local mx, my = self:getMousePosition()
    self.onPointerDown(self, O.assign({}, msgValue, {x = mx, y = my}))
  end

  if self.focused and guiType.TEXT_INPUT == self.type then
    if msgBus.GUI_TEXT_INPUT == msgType then
      local txt = msgValue
      self.text = self.text..txt
      self.onChange(self)
    end

    -- handle backspace for text input
    if msgBus.KEY_DOWN == msgType and msgValue.key == 'backspace' then
      self.text = string.sub(self.text, 1, #self.text - 1)
      self.onChange(self)
    end
  end
end

local function handleHoverEvents(self)
  if self.eventsDisabled then
    return false
  end

  local mx, my = self:getMousePosition()
  local mouseCollisions = collisionWorlds.gui:queryPoint(mx, my, mouseCollisionFilter)

  -- if the collided item is `self`, then we're hovered
  for i=1, #mouseCollisions do
    if mouseCollisions[i] == self.colObj then
      self.hovered = true
    end
  end

  if self.hovered then
    InputContext.set(self.inputContext)
    self.onPointerMove(self, {x = mx, y = my})
  end

  return self.hovered
end

local eventTypesFilter = {
  [msgBus.MOUSE_WHEEL_MOVED] = true,
  [msgBus.MOUSE_CLICKED] = true,
  [msgBus.MOUSE_PRESSED] = true,
  [msgBus.GUI_TEXT_INPUT] = true,
  [msgBus.KEY_DOWN] = true,
  [msgBus.UPDATE] = true,
}

Component.create({
  id = 'gui-system-init',
  init = function(self)
    local function latestEventPriority(a, b)
      return a.eventPriority > b.eventPriority
    end

    self.listeners = {
      msgBus.on('*', function(msgValue, msgType)
        local isInputEvent = eventTypesFilter[msgType]
        if (not isInputEvent) then
          return msgValue
        end

        local components = Component.groups.guiEventNode.getAll()
        local sortedComponents = {}
        for _,c in pairs(components) do
          if c.isGui then
            table.insert(sortedComponents, c)
          end
        end

        table.sort(sortedComponents, latestEventPriority)

        for i=1, #sortedComponents do
          local c = sortedComponents[i]
          c.hovered = false
          if (not c.inputContext) then
            error('gui component '..c:getId()..' has no input context')
          end
          if (
              InputContext.contains(c.inputContext) or
              InputContext.contains('any')
            ) and
            (not c.eventsDisabled)
          then
            local hovered = handleHoverEvents(c)
            if hovered or c.focused then
              triggerEvents(c, msgValue, msgType)
            end
          end
          local hoverStateChanged = c.hovered ~= c.prevHovered
          if hoverStateChanged then
            if c.hovered then
              c.onPointerEnter(c)
            else
              c.onPointerLeave(c)
            end
          end
          c.prevHovered = c.hovered
        end

        return msgValue
      end, 1),
      msgBus.on(msgBus.UPDATE_END, function()
        InputContext.set('any')
      end, 100)
    }
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})

-- event priorities are sorted by highest to lowest
local eventPriority = 0
local function getDefaultEventPriority()
  eventPriority = eventPriority + 1
  return eventPriority
end

function Gui.init(self)
  Component.addToGroup(self, 'guiEventNode')

  assert(guiType[self.type] ~= nil, 'invalid gui type'..tostring(self.type))

  if self.initialProps.update then
    error('may not override `update` method, use `onUpdate` instead')
  end

  self.inputContext = self.inputContext or self:getId()
  self.eventPriority = self.eventPriority or getDefaultEventPriority()
  self.w, self.h = self.w or self.width or 1, self.h or self.height or 1

  if guiType.LIST == self.type then
    assert(self.h <= love.graphics.getHeight() / self.scale, 'scrollable list height should not be greater than window height')
    self.scrollNode = GuiNode.create({
      x = self.x,
      y = self.y,
    }):setParent(self)
  end

  if guiType.TEXT_INPUT == self.type then
    assert(type(self.text) == 'string')
  end

  if guiType.TOGGLE == self.type then
    assert(type(self.checked) == 'boolean')
  end

  local posX, posY = self:getPosition()
  self.colObj = self:addCollisionObject(
    self.collisionGroup or self.type,
    posX, posY,
    self.w, self.h
  ):addToWorld(collisionWorlds.gui)

  self.onCreate(self)
end

local function isDifferent(a, b)
  return a ~= b
end

function Gui.setEventsDisabled(self, disabled)
  self.eventsDisabled = disabled
  return self
end

function Gui.update(self, dt)
  local gameScale = require('config.config').scale
  local hasChangedScale = self.scale ~= gameScale
  if (not self.initialProps.scale and hasChangedScale) then
    self.scale = gameScale
  end

  local posX, posY = self:getPosition()
  -- minimum width is needed for `bump` library to not fail for zero sized collision objects
  self.w, self.h = math.max(1, self.width or self.w), math.max(1, self.height or self.h)
  self.colObj:update(posX, posY, self.w, self.h)

  self.onUpdate(self, dt)

  if self.scrollNode then
    f.forEach(self.children, function(child)
      child:setParent(self.scrollNode)
    end)
  end

  self.prevColPosX = posX
  self.prevColPosY = posY
  self.prevX = self.x
  self.prevY = self.y
end

function Gui.draw(self)
  self.render(self)
end

function Gui.final(self)
  self.onFinal(self)
  InputContext.set('any')
end

local drawOrderByType = {
  [guiType.LIST] = 2,
  default = 3
}
function Gui.drawOrder(self)
  return drawOrderByType[self.type] or drawOrderByType.default
end

return Component.createFactory(Gui)