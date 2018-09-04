local Component = require 'modules.component'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local f = require 'utils.functional'

local MainMapSolidsBlueprint = {
  group = groups.all,
  animation = nil,
  x = 0,
  y = 0,
  ox = 0,
  oy = 0,
  opacity = 1,
  gridSize = 0,
}

function MainMapSolidsBlueprint.changeTile(self, animation, x, y, opacity)
  local tileX, tileY = x * self.gridSize, y * self.gridSize
  local ox, oy = animation:getSourceOffset()

  self.ox, self.oy = ox, oy
  self.animation = animation
  self.x = tileX
  self.y = tileY
  self.opacity = opacity

  return self
end

function MainMapSolidsBlueprint.draw(self)
  if not self.animation then
    return
  end

  love.graphics.setColor(1,1,1,self.opacity)
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