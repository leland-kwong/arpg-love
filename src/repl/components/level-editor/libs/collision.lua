local objectsList = {}
local focusedObject = nil
local hoveredObjects = {}

local M = {
  get = function(self, id)
    return objectsList[id]
  end,
  getFocused = function(self)
    return focusedObject
  end,
  setHover = function(self, id)
    hoveredObjects[id] = self:get(id)
    return self
  end,
  clearHovered = function()
    hoveredObjects = {}
  end,
  getHovered = function(self)
    return hoveredObjects
  end,
  setFocus = function(self, id)
    local previouslyFocused = focusedObject

    local item = self:get(id)
    if item and (not item.focusable) then
      focusedObject = nil
    else
      focusedObject = id
    end

    return previouslyFocused
  end,
  isFocused = function(self, id)
    return focusedObject == id
  end,
  isHovered = function(self, id)
    return hoveredObjects[id] ~= nil
  end,
  setTranslate = function(self, id, x, y)
    local o = self:get(id)
    o.offsetX, o.offsetY = x or o.offsetX, y or o.offsetY
    local x, y = self:getPosition(id)
    o.collisionWorld:update(o, x, y)
    return self
  end,
  getPosition = function(self, id)
    local o = self:get(id)
    return o.x + o.offsetX, o.y + o.offsetY
  end,
  getSize = function(self, id)
    local o = self:get(id)
    return o.w, o.h
  end,
  remove = function(self, id)
    local o = self:get(id)
    o.collisionWorld:remove(o)
    objectsList[id] = nil
    if (focusedObject == id) then
      focusedObject = nil
    end
    hoveredObjects[id] = nil
    return self
  end,
}

local collisionObjectMt = {
  x = 0,
  y = 0,
  w = 1,
  h = 1,
  offsetX = 0,
  offsetY = 0,
  selectable = false,
  focusable = false
}
collisionObjectMt.__index = collisionObjectMt

return setmetatable(M, {
  __call = function(self, props, collisionWorld)
    local o = setmetatable(props, collisionObjectMt)
    o.collisionWorld = collisionWorld
    collisionWorld:add(o, o.x, o.y, o.w, o.h)

    assert(props.id ~= nil, 'id must be provided for collision object')

    local duplicateObjectById = M:get(props.id)
    if duplicateObjectById then
      M:remove(props.id)
    end

    objectsList[props.id] = o
    return o
  end
})