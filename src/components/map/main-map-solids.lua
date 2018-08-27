local Component = require 'modules.component'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local f = require 'utils.functional'

local MainMapSolidsBlueprint = {
  group = groups.all,
  animation = {},
  x = 0,
  y = 0,
  ox = 0,
  oy = 0,
  gridSize = 0,
}

function MainMapSolidsBlueprint.init(self)
  assert(type(self.gridSize) == 'number', 'invalid grid size')

  local w = self.animation:getSourceSize()
  local ox, oy = self.animation:getSourceOffset()
  self.colObj = self:addCollisionObject(
    'obstacle',
    self.x, self.y, w, self.gridSize, ox, self.gridSize
  ):addToWorld(collisionWorlds.map)
end

function MainMapSolidsBlueprint.draw(self)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(
    self.animation.atlas,
    self.animation.sprite,
    self.x,
    self.y,
    0,
    1,
    1,
    self.ox,
    self.oy
  )
end

function MainMapSolidsBlueprint.drawOrder(self)
  return self.group.drawOrder(self)
end

return Component.createFactory(MainMapSolidsBlueprint)