local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local bump = require 'modules.bump'
local msgBus = require 'components.msg-bus'
local camera = require 'components.camera'
local Color = require 'modules.color'

local MapPointerWorld = {
  debug = true,
  fromTarget = nil,
  target = nil, -- an object with `x` and `y` coordinates
  pointers = {}
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

function handleCollisions(self, target)
  local camera = require 'components.camera'
  local toX, toY = camera:toScreenCoords(target.x, target.y)
  local actualX, actualY, _, numCollisions = self.collisionObject:move(toX, toY)
  local pointIsInsideViewport = numCollisions == 0
  return actualX, actualY, pointIsInsideViewport
end

function MapPointerWorld.init(self)
  Component.addToGroup(self, 'hud')

  self.collisionObject = self:addCollisionObject(
    'map-pointer',
    1,
    1,
    16,
    16
  ):addToWorld(screenEdgeCollisionWorld)
end

function MapPointerWorld.add(self, fromTarget, target, color)
  local defaultColor = Color.YELLOW
  table.insert(self.pointers, {
    fromTarget = fromTarget,
    target = target,
    color = color or defaultColor
  })
end

function MapPointerWorld.draw(self)
  local c = self.collisionObject

  for i=1, #self.pointers do
    local pointer = self.pointers[i]
    local animation = AnimationFactory:newStaticSprite('gui-map-pointer')
    local Position = require 'utils.position'
    local vx, vy = Position.getDirection(pointer.fromTarget.x, pointer.fromTarget.y, pointer.target.x, pointer.target.y)
    love.graphics.setColor(pointer.color)
    local ox, oy = animation:getSourceOffset()
    local x, y = handleCollisions(self, pointer.target)
    love.graphics.draw(
      AnimationFactory.atlas,
      animation.sprite,
      x + c.w/2,
      y + c.h/2,
      math.atan2(vx, vy) * -1 - math.pi,
      1,
      1,
      ox,
      oy
    )

    if self.debug then
      love.graphics.setColor(1,1,0,0.5)
      love.graphics.rectangle('fill', c.x, c.y, c.w, c.h)
    end
  end

  -- reset pointers list after drawing them
  self.pointers = {}
end

return Component.createFactory(MapPointerWorld)