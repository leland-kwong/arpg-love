local ColObj = require 'repl.components.level-editor.libs.collision'
local states = require 'repl.components.level-editor.states'
local Vec2 = require 'modules.brinevector'
local getFont = require 'components.font'
local msgBus = require 'components.msg-bus'
local getTextSize = require 'repl.components.level-editor.libs.get-text-size'
local getCursorPos = require 'repl.components.level-editor.libs.get-cursor-position'

local uiState = states.uiState

local function resetTextBoxClock()
  uiState:set('textBoxCursorClock', math.pi)
end

local TextBox = {
  active = nil,
  setActive = function(self, ref)
    self.active = ref
  end,
  getActive = function(self)
    return self.active
  end
}

local textBoxMt = {
  text = '',
  padding = 5,
  cursorPosition = 1,
  selectionRange = Vec2(0,0),
  focusable = true,
  enabled = false,
  getFont = function(self)
    return self.font or getFont.debug.font
  end,
  updateCharCollisions = function(self)
    if self.previousText == self.text then
      return
    end
    local parent = self
    local offsetX = 0
    for _,c in ipairs(self.charCollisions) do
      ColObj:remove(c.id)
    end
    self.charCollisions = {}
    local posX, posY = ColObj:getPosition(self.id)

    -- add an extra space at the end so we can handle range selection easier
    local collisionText = self.text..' '

    for i=1, #collisionText do
      local char = string.sub(collisionText, i, i)
      local charWidth, charHeight = getTextSize(char, self:getFont())
      local collision = ColObj({
        id = 'char-'..i..'-'..self.id,
        index = i,
        type = 'textInputCharacter',
        x = posX + offsetX,
        y = posY,
        w = charWidth,
        h = charHeight + (parent.padding * 2),
        MOUSE_PRESSED = function(self, ev)
          local presses = ev[5]
          local isDoubleClick = presses % 2 == 0
          if isDoubleClick then
            parent:enable()
            return {
              stopPropagation = true
            }
          end

          local mousePos = getCursorPos()
          local round = require 'utils.math'.round
          local x = ColObj:getPosition(self.id)
          local w = ColObj:getSize(self.id)
          local isLeftEdge = (mousePos.x - x)/w < 0.4
          local indexAdjust = isLeftEdge and -1 or 0

          parent:setRange(i + indexAdjust, i + indexAdjust)

          return {
            stopPropagation = true
          }
        end,
      }, parent.collisionWorld)
      table.insert(self.charCollisions, collision)
      offsetX = offsetX + charWidth
    end

    self.previousText = self.text
  end,
  clearRange = function(self)
    self.selectionRange = Vec2(0, 0)
  end,
  setRange = function(self, _start, _end)
    if (not self.enabled) then
      return
    end

    local clamp = require 'utils.math'.clamp
    local max = #self.text + 1
    _start = clamp(_start, 1, max)
    _end = _end and clamp(_end, _start, max) or _start
    self.selectionRange = Vec2(_start, _end)
    resetTextBoxClock()
  end,
  selectAll = function(self)
    self:setRange(1, #self.text + 1)
  end,
  enable = function(self)
    msgBus.send('SET_TEXT_INPUT', true)
    self.enabled = true
    self:selectAll()
    TextBox:setActive(self)
  end,
  setText = function(self, text)
    if (not self.enabled) then
      return
    end

    self.text = text
  end,
  MOUSE_PRESSED = function(self, ev)
    local isDoubleClick = ev[5]%2 == 0
    if isDoubleClick then
      self:enable()
      return
    end

    local mousePos = getCursorPos()
    local x = ColObj:getPosition(self.id)
    local w = ColObj:getSize(self.id)
    local isBeginning = (mousePos.x - x)/w < 0.2

    if isBeginning then
      self:setRange(1)
      return
    end

    local endOfText = #self.text + 1
    self:setRange(endOfText)
  end,
  MOUSE_MOVE = function(self)
    self:updateCharCollisions()
  end,
  GUI_TEXT_INPUT = function(self, nextChar)
    local rangeLength = math.abs(self.selectionRange.x - self.selectionRange.y)
    if rangeLength > 0 then
      self:setText((string.sub(self.text, 1, self.selectionRange.x - 1) or '') .. (string.sub(self.text, self.selectionRange.y) or ''))
      self:setText(self.text .. nextChar)
    else
      self:setText((string.sub(self.text, 1, self.selectionRange.x - 1) or '') .. nextChar .. (string.sub(self.text, self.selectionRange.y) or ''))
    end
    self:setRange(self.selectionRange.x + 1)
    self:updateCharCollisions()
    resetTextBoxClock()
  end,
  KEY_DOWN = function(self, ev)
    local rangeLength = math.abs(self.selectionRange.x - self.selectionRange.y)
    if 'escape' == ev.key then
      ColObj:setFocus()
      self:ON_BLUR()
    elseif 'backspace' == ev.key then
      local endFrag = (string.sub(self.text, self.selectionRange.y) or '')
      local isSelection = rangeLength > 0
      if isSelection then
        local startFrag = (string.sub(self.text, 1, self.selectionRange.x - 1) or '')
        self:setText(startFrag .. endFrag)
        self:setRange(self.selectionRange.x)
      elseif self.selectionRange.x > 1 then
        local startFrag = (string.sub(self.text, 1, self.selectionRange.x - 2) or '')
        self:setText(startFrag .. endFrag)
        self:setRange(self.selectionRange.x - 1)
      end
    elseif 'delete' == ev.key then
      local isSelection = rangeLength > 0
      if isSelection then
        local startFrag, endFrag = (string.sub(self.text, 1, self.selectionRange.x - 1) or ''),
          (string.sub(self.text, self.selectionRange.y) or '')
        self:setText(startFrag .. endFrag)
        self:setRange(self.selectionRange.x)
      else
        local startFrag, endFrag = (string.sub(self.text, 1, self.selectionRange.x - 1) or ''),
          (string.sub(self.text, self.selectionRange.y + 1) or '')
        self:setText(startFrag .. endFrag)
        self:setRange(self.selectionRange.x)
      end
    elseif 'left' == ev.key then
      if rangeLength > 0 then
        self:setRange(self.selectionRange.x)
      else
        self:setRange(self.selectionRange.x - 1)
      end
    elseif 'right' == ev.key then
      if rangeLength > 0 then
        self:setRange(self.selectionRange.y)
      else
        self:setRange(self.selectionRange.x + 1)
      end
    elseif 'home' == ev.key then
      self:setRange(1)
    elseif 'end' == ev.key then
      self:setRange(#self.text + 1)
    end
  end,
  MOUSE_DRAG = function(self, ev)
    local x,y,w,h = ev.startX, ev.startY, math.abs(ev.dx), math.max(1, ev.dy)
    if w <= 0 then
      return
    end
    if ev.dx < 0 then
      x = x + ev.dx
    end
    local items, len = colWorld:queryRect(x, y, w, h, function(item)
      return item.type == 'textInputCharacter'
    end)
    if len > 0 then
      table.sort(items, function(a, b)
        return a.index < b.index
      end)
      self:setRange(
        items[1].index,
        items[#items].index
      )
    end
  end,
  ON_BLUR = function(self)
    self.enabled = false
    self:clearRange()
    msgBus.send('SET_TEXT_INPUT', false)
    TextBox:setActive()
  end
}

return setmetatable(TextBox, {
  __call = function(_, props, colWorld)
    props.charCollisions = {}
    local textBox = ColObj(
      props,
      colWorld
    )
    -- make text box inherit from collision object
    setmetatable(textBoxMt, getmetatable(textBox))
    return setmetatable(textBox, {
      __index = textBoxMt
    })
  end
})