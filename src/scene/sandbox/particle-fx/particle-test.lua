local Component = require 'modules.component'
local scale = require 'config'.scaleFactor
local groups = require 'components.groups'
local Player = require 'components.player'
local ParticleFx = require 'components.particle.particle'
local Timer = require 'components.timer'
local tick = require'utils.tick'

local ParticleTest = {
  group = groups.all,
}

function ParticleTest.init(self)
  local player = Player.create({
    x = 100,
    y = 100
  })

  ParticleFx.Basic.create({
    x = player.x,
    y = player.y + 6
  })

  ParticleFx.Basic.create({
    x = player.x,
    y = player.y + 6,
    drawOrder = function(self)
      return self.group.drawOrder(self)
    end
  })

  tick.delay(function()
    print('done')
  end, 1)
end

return Component.createFactory(ParticleTest)