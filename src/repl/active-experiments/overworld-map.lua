local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local UniverseMap = dynamicRequire 'components.hud.universe-map.universe-map-2'

Component.create({
  id = 'UniverseMapInit',
  group = 'hud',
  init = function(self)
    self.listeners = {
      msgBus.on('MAP_TOGGLE', function(enabled)
        local ref = Component.get('UniverseMap')
        if ref then
          ref:delete(true)
        else
          UniverseMap.create({
            id = 'UniverseMap',
          })
        end
      end)
    }
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})