local Component = require 'modules.component'
local groups = require 'components.groups'
local GroundFlame = require 'components.particle.ground-flame'

local GroundFlameTest = {
  group = groups.all,
}

function GroundFlameTest.init(self)
  GroundFlame.create({
    x = love.graphics.getWidth() / 2,
    y = love.graphics.getHeight() / 2,
    width = 16,
    duration = 99999
  })

  -- Basic.create({
  --   x = player.x,
  --   y = player.y + 6,
  --   duration = 9999,
  --   drawOrder = function(self)
  --     return self.group:drawOrder(self)
  --   end
  -- }):setParent(self)
end

return Component.createFactory(GroundFlameTest)