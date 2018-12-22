local Component = require 'modules.component'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local f = require 'utils.functional'

local MainMapSolidsBlueprint = {
  animation = nil,
  x = 0,
  y = 0,
  ox = 0,
  oy = 0,
  opacity = 1,
  gridSize = 0,
  layer = 0,
  disabled = true
}

Component.newGroup({
  name = 'activeWalls'
})

function MainMapSolidsBlueprint.changeTile(self, animation, x, y, opacity, layer)
  local tileX, tileY = x * self.gridSize, y * self.gridSize
  local ox, oy = animation:getOffset()

  self.ox, self.oy = ox, oy
  self.animation = animation
  self.x = tileX
  self.y = tileY
  self.opacity = opacity
  self.layer = layer

  return self
end

function MainMapSolidsBlueprint.disable(self)
  self.disabled = true
  Component.removeFromGroup(self, 'all')
  Component.removeFromGroup(self, 'activeWalls')
  return self
end

function MainMapSolidsBlueprint.enable(self)
  self.disabled = false
  Component.addToGroup(self, 'all')
  Component.addToGroup(self, 'activeWalls')
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
  return Component.groups.all:drawOrder(self) + self.layer
end

return Component.createFactory(MainMapSolidsBlueprint)