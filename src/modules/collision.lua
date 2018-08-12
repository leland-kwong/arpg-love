local bump = require 'modules.bump'
local typeCheck = require 'utils.type-check'
local uid = require 'utils.uid'

bump.TOUCH = 'touch'

local CollisionObject = {}

function CollisionObject:new(group, x, y, w, h, offsetX, offsetY)
  typeCheck.validate(group, typeCheck.STRING)

  local obj = {
    _id = uid(),

    group = group,
    x = x,
    y = y,
    w = w,
    h = h,
    ox = (offsetX or 0),
    oy = (offsetY or 0),
    world = nil
  }

  setmetatable(obj, self)
  self.__index = self

  return obj
end

function CollisionObject:setParent(object)
  self.parent = object
  return self
end

function CollisionObject:addToWorld(collisionWorld)
  collisionWorld:add(
    self,
    self.x - self.ox,
    self.y - self.oy,
    self.w,
    self.h
  )
  self.world = collisionWorld
  return self
end

function CollisionObject:move(goalX, goalY, filter)
  if not self.world then
    error('collision object must be added to a world')
    return
  end

  local actualX, actualY, cols, len = self.world:move(
    self,
    goalX - self.ox,
    goalY - self.oy,
    filter
  )
  local finalX, finalY = actualX + self.ox, actualY + self.oy
  self.x = finalX
  self.y = finalY
  return finalX,
    finalY,
    cols,
    len
end

function CollisionObject:delete()
  self.world:remove(self)
  return self
end

function CollisionObject:removeFromWorld(collisionWorld)
  collisionWorld:remove(self)
  self.world = nil
end

function CollisionObject:update(x, y, w, h, offsetX, offsetY)
  if not self.world then
    error('[collision.update]: collision object must be added to a world')
    return self
  end

  offsetX = offsetX or 0
  offsetY = offsetY or 0

  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.ox = offsetX
  self.oy = offsetY
  self.world:update(
    self,
    x - offsetX,
    y - offsetY,
    w,
    h
  )
  return self
end

function CollisionObject:check(goalX, goalY, filter)
  return self.world:check(self, goalX, goalY, filter)
end

return CollisionObject