local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local bump = require 'modules.bump'
local msgBus = require 'components.msg-bus'
local camera = require 'components.camera'

local MapPointer = {
  -- debug = true,
  fromTarget = nil,
  target = nil -- an object with `x` and `y` coordinates
}

local screenEdgeCollisionWorld = bump.newWorld(100)
local function BoundsObject()
  return { isBoundsObject = true }
end
local screenSize = {
  width = 0,
  height = 0
}

local function setScreenBoundsCollisions()
  local screenWidth, screenHeight = camera:getSize()
  local isDifferentScreenSize = screenWidth ~= screenSize.width or screenHeight ~= screenSize.height
  if (not isDifferentScreenSize) then
    return
  end
  -- remove current collision bounds items
  local items, len = screenEdgeCollisionWorld:getItems()
  for i=1, len do
    local it = items[i]
    if (it.isBoundsObject) then
      screenEdgeCollisionWorld:remove(it)
    end
  end

  screenSize.width = screenWidth
  screenSize.height = screenHeight
  local top, right, bottom, left = 0, screenWidth, screenHeight, 0
  -- top
  screenEdgeCollisionWorld:add(BoundsObject(), 0, 0, right, 1)
  -- right
  screenEdgeCollisionWorld:add(BoundsObject(), right, 0, 1, bottom)
  -- bottom
  local hudHeight = 32
  screenEdgeCollisionWorld:add(BoundsObject(), 0, bottom - hudHeight, right, 1)
  -- left
  screenEdgeCollisionWorld:add(BoundsObject(), 0, 0, 1, bottom)
end

msgBus.on(msgBus.UPDATE, setScreenBoundsCollisions)
setScreenBoundsCollisions()

function handleCollisions(self)
  local camera = require 'components.camera'
  local toX, toY = camera:toScreenCoords(self.target.x, self.target.y)
  local actualX, actualY, _, numCollisions = self.collisionObject:move(toX, toY)
  self.x, self.y = actualX, actualY
  self.pointIsInsideViewport = numCollisions == 0
end

function MapPointer.init(self)
  Component.addToGroup(self, 'hud')

  self.collisionObject = self:addCollisionObject(
    'map-pointer',
    self.x,
    self.y,
    16,
    16
  ):addToWorld(screenEdgeCollisionWorld)
end

function MapPointer.update(self)
  local screenWidth, screenHeight = camera:getSize()
  self.collisionObject:update(screenWidth/2, screenHeight/2)
  handleCollisions(self)
  self:setDrawDisabled(self.pointIsInsideViewport or (not self.target) or (not self.fromTarget))
end

function MapPointer.draw(self)
  local c = self.collisionObject

  if self.debug then
    love.graphics.setColor(1,1,0,0.5)
    love.graphics.rectangle('fill', c.x, c.y, c.w, c.h)
  end

  local animation = AnimationFactory:newStaticSprite('gui-map-pointer')
  local Position = require 'utils.position'
  local vx, vy = Position.getDirection(self.fromTarget.x, self.fromTarget.y, self.target.x, self.target.y)
  love.graphics.setColor(1,1,1)
  local ox, oy = animation:getSourceOffset()
  love.graphics.draw(
    AnimationFactory.atlas,
    animation.sprite,
    self.x + c.w/2,
    self.y + c.h/2,
    math.atan2(vx, vy) * -1 - math.pi,
    1,
    1,
    ox,
    oy
  )
end

return Component.createFactory(MapPointer)