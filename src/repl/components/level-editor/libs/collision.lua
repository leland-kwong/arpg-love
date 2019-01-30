local objectsList = {}
local focusedObjects = {}
local hoveredobjects = {}

local M = {
  get = function(self, id)
    return objectsList[id]
  end,
  setHover = function(self, id)
    hoveredobjects[id] = self:get(id)
  end,
  setFocus = function(self, id)
    focusedObjects[id] = self:get(id)
  end,
  isFocused = function(self, id)
    return focusedObjects[id] ~= nil
  end,
  isHovered = function(self, id)
    return hoveredobjects[id] ~= nil
  end,
  getAllFocused = function()
    return coroutine.wrap(function()
      for _,obj in pairs(focusedObjects) do
        coroutine.yield(obj)
      end
    end)
  end,
  getPosition = function(self, id)
    local o = self:get(id)
    return o.x + o.offsetX, o.y + o.offsetY
  end,
  getSize = function(self, id)
    local o = self:get(id)
    return o.w, o.h
  end
}

local collisionObjectMt = {
  x = 0,
  y = 0,
  offsetX = 0,
  offsetY = 0,
  selectable = false,
  setTranslate = function(self, x, y)
    self.offsetX, self.offsetY = x or self.offsetX, y or self.offsetY
    local x, y = M:getPosition(self.id)
    self.collisionWorld:update(self, x, y)
    return self
  end,
  remove = function(self)
    self.collisionWorld:remove(self)
    objectsList[self.id] = nil
    focusedObjects[self.id] = nil
    hoveredobjects[self.id] = nil
    return self
  end
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