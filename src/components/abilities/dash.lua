local Component = require 'modules.component'
local config = require 'config.config'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'

local Dash = {
  group = groups.all,
  fromCaster = nil, -- object thats casted it
  speed = 1000, -- speed bost
  duration = 3/60,
  range = config.gridSize * 5
}

function Dash.init(self)
  local boost = self.speed
  msgBus.send(msgBus.CHARACTER_HIT, {
    parent = self.fromCaster,
    duration = self.duration,
    modifiers = {
      moveSpeed = boost,
      freelyMove = 1
    },
    source = 'DASH_ABILITY'
  })
  self:delete()
end

return Component.createFactory(Dash)