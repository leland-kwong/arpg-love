local objectsList = {}
local focusedObjects = {}
local hoveredobjects = {}

local M = {
  get = function(self, id)
    return objectsList[id]
  end,
  setHover = function(self, id)
    hoveredobjects[id] = self:get(id)
    return self
  end,
  setFocus = function(self, id)
    focusedObjects[id] = self:get(id)
    return self
  end,
  isFocused = function(self, id)
    return focusedObjects[id] ~= nil
  end,
  isHovered = function(self, id)
    return hoveredobjects[id] ~= nil
  end,
  getAllFocused = function(self)
    return coroutine.wrap(function()
      for _,obj in pairs(focusedObjects) do
        coroutine.yield(obj)
      end
    end)
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
    focusedObjects[id] = nil
    hoveredobjects[id] = nil
    return self
  end,
}

local collisionObjectMt = {
  x = 0,
  y = 0,
  offsetX = 0,
  offsetY = 0,
  selectable = false
}
collisionObjectMt.__index = collisionObjectMt

return setmetatable(M, {
  __call = function(self, props, collisionWorld)
    local o = setmetatable(props, collisionObjectMt)
    o.collisionWorld = collisionWorld
    collisionWorld:add(o, o.x, o.y, o.w, o.h)

    assert(props.id ~= nil, 'id must be provided for collision object')

    local duplicateObjectById = self:get(props.id)
    if duplicateObjectById then
      duplicateObjectById:remove()
    end

    objectsList[props.id] = o
    return o
  end
})