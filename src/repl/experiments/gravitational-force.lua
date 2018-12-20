local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local gravForce = dynamicRequire 'components.groups.gravitational-force'
local Vec2 = require 'modules.brinevector'

local ZERO_VECTOR = Vec2()

local testBody = Component.create({
  id = 'test-body',
  init = function(self)
    Component.addToGroup(self, 'all')

    local msgBus = require 'components.msg-bus'
    msgBus.on(msgBus.KEY_PRESSED, function(ev)
      if ev.key == 'space' then
        -- local playerRef = Component.get('PLAYER')
        -- if playerRef then
        --   local distance = 10
        --   local magnitude = Vec2(
        --     playerRef.moveDirectionX * distance,
        --     playerRef.moveDirectionY * distance
        --   )
        --   Component.addToGroup('dash-force', 'gravForce', {
        --     magnitude = magnitude,
        --     actsOn = 'PLAYER',
        --     duration = 3/60
        --   })
        -- end
      end
    end)
  end,
  update = function(self, dt)
  end
})

Component.create({
  id = 'gravitational-force-test',
  init = function(self)
    Component.addToGroup(self, 'firstLayer')

    -- Component.addToGroup('force-1', 'gravForce', {
    --   magnitude = Vec2(1, 0),
    --   actsOn = 'PLAYER'
    -- })
    -- Component.addToGroup('force-2', 'gravForce', {
    --   magnitude = Vec2(0, 1),
    --   actsOn = 'PLAYER'
    -- })
  end,
  update = function(self, dt)
    gravForce(dt)
  end
})