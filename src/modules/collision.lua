local bump = require 'modules.bump'
local typeCheck = require 'utils.type-check'
local uid = require 'utils.uid'

bump.TOUCH = 'touch'

local objectCount = 0

local CollisionObject = {}

function CollisionObject:new(group, x, y, w, h, offsetX, offsetY)
  assert(
    group ~= nil,
    'collision group must be provided'
  )

  local id = uid()
  local obj = {
    _id = id,

    group = group,
    x = x,
    y = y,
    w = w,
    h = h,
    ox = (offsetX or 0),
    oy = (offsetY or 0),
    world = nil
  }

  objectCount = objectCount + 1
  setmetatable(obj, self)
  self.__index = self

  return obj
end

function CollisionObject:getPositionWithOffset()
  return self.x - self.ox, self.y - self.oy
end

function CollisionObject:addToWorld(collisionWorld)
  local x, y = self:getPositionWithOffset()
  collisionWorld:add(
    self,
    x,
    y,
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

--[[
  used for referencing in the collision filter
  to know what object this collision object is related to
]]
function CollisionObject:setParent(parent)
  self.parent = parent
  return self
end

function CollisionObject:delete()
  self:removeFromWorld(self.world)
  objectCount = objectCount - 1
  return self
end

function CollisionObject:getId()
  return self._id
end

function CollisionObject:removeFromWorld(collisionWorld)
  if (not self.world) then
    return
  end
  collisionWorld:remove(self)
  self.world = nil
end

function CollisionObject:update(x, y, w, h, offsetX, offsetY)
  if not self.world then
    error('[collision.update]: collision object must be added to a world')
    return self
  end

  self.x = x or self.x
  self.y = y or self.y
  self.w = w or self.w
  self.h = h or self.h
  self.ox = offsetX or self.ox
  self.oy = offsetY or self.oy

  local x, y = self:getPositionWithOffset()
  self.world:update(
    self,
    x,
    y,
    self.w,
    self.h
  )
  return self
end

function CollisionObject:check(goalX, goalY, filter)
  return self.world:check(self, goalX, goalY, filter)
end

function CollisionObject.getStats()
  return objectCount
end

return CollisionObject