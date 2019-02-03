local dynamicRequire = require 'utils.dynamic-require'
local bump = require 'modules.bump'
local EventsContext = dynamicRequire 'repl.libs.gui.events'

local id = 0

local collisionObjectMt = {
  x = 0,
  y = 0,
  w = 1,
  h = 1,
  offsetX = 0,
  offsetY = 0,
  hovered = false,
  focused = false,
  selectable = false,
  focusable = false,

  setPosition = function(self, x, y)
    local o = self
    o.x, o.y = x, y
    o.collisionWorld:update(o, o.x, o.y)
    return self
  end,

  setSize = function(self, w, h)
    local o = self
    o.w, o.h = w, h or w
    o.collisionWorld:update(o, o.x, o.y, o.w, o.h)
    return self
  end,

  remove = function(self)
    self.guiContext:remove(self)
  end
}
collisionObjectMt.__index = collisionObjectMt

local M = {
  __call = function(self, props)
    local o = setmetatable(props, collisionObjectMt)
    o.guiContext = self
    o.collisionWorld = self.collisionWorld
    self.collisionWorld:add(o, o.x, o.y, o.w, o.h)

    if (not o.id) then
      id = id + 1
      o.id = id
    end

    local duplicateObjectById = self.objectsList[o.id] ~= nil
    if duplicateObjectById then
      self:remove(o.id)
    end

    self.objectsList[o.id] = o
    return o
  end,
  destroy = function(self)
    self.cleanupEventsContext()
    for _,ref in pairs(self.objectsList) do
      ref:remove()
    end
  end,

  -- [[ INTERNAL METHODS - these should not be generally used ]]
  getFocused = function(self)
    return self.focusedObject
  end,
  setHover = function(self, item)
    self.hoveredObjects[item.id] = item
    item.hovered = true
    return self
  end,
  getAllHovered = function(self)
    return self.hoveredObjects
  end,
  clearHovered = function(self)
    for _,item in pairs(self.hoveredObjects) do
      item.hovered = false
    end
    self.hoveredObjects = {}
  end,
  setFocus = function(self, item)
    local previouslyFocused = self.focusedObject

    if item and (not item.focusable) then
      self.focusedObject = nil
    else
      self.focusedObject = item
      if previouslyFocused then
        previouslyFocused.focused = false
      end
      if item then
        item.focused = true
      end
    end

    return previouslyFocused
  end,
  remove = function(self, item)
    item.collisionWorld:remove(item)
    self.objectsList[item.id] = nil
    return self
  end,
}
M.__index = M

return function()
  local GuiContextFactory = setmetatable({
    collisionWorld = bump.newWorld(24),
    objectsList = {},
    focusedObject = nil,
    hoveredObjects = {},
  }, M)
  local eventContext = EventsContext(GuiContextFactory)
  GuiContextFactory.cleanupEventsContext = eventContext.cleanup
  GuiContextFactory.update = eventContext.update
  return GuiContextFactory
end