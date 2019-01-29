local collisionObjectMt = {
  offsetX = 0,
  offsetY = 0,
  selectable = false,
  setTranslate = function(self, x, y)
    self.offsetX, self.offsetY = x or self.offsetX, y or self.offsetY
    local x, y = self:getPosition()
    self.collisionWorld:update(self, x, y)
    return self
  end,
  getPosition = function(self)
    return self.x + self.offsetX, self.y + self.offsetY
  end,
  remove = function(self)
    self.collisionWorld:remove(self)
    return self
  end
}
collisionObjectMt.__index = collisionObjectMt

return setmetatable({
  _objectsList = {},
  get = function(self, id)
    return self._objectsList[id]
  end,
}, {
  __call = function(self, props, collisionWorld)
    local o = setmetatable(props, collisionObjectMt)
    o.collisionWorld = collisionWorld
    collisionWorld:add(o, o.x, o.y, o.w, o.h)

    assert(props.id ~= nil, 'id must be provided for collision object')
    self._objectsList[props.id] = o
    return o
  end
})