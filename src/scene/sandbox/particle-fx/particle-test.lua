local Component = require 'modules.component'
local scale = require 'config'.scaleFactor
local groups = require 'components.groups'
local Player = require 'components.player'
local ParticleFx = require 'components.particle.particle'
local tick = require'utils.tick'

local ParticleTest = {
  group = groups.all,
}

function ParticleTest.init(self)
  local player = Player.create({
    x = 100,
    y = 100
  }):setParent(self)

  ParticleFx.Basic.create({
    x = player.x,
    y = player.y + 6,
    duration = 9999
  }):setParent(self)

  ParticleFx.Basic.create({
    x = player.x,
    y = player.y + 6,
    duration = 9999,
    drawOrder = function(self)
      return self.group.drawOrder(self)
    end
  }):setParent(self)
end

return Component.createFactory(ParticleTest)