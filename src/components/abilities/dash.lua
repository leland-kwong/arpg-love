local Component = require 'modules.component'
local config = require 'config.config'
local groups = require 'components.groups'
local tick = require 'utils.tick'

local MOVE_SPEED = 'moveSpeed'

local Dash = {
  group = groups.all,
  fromCaster = nil, -- object thats casted it
  speed = 1000,
  duration = 3/60,
  range = config.gridSize * 5
}

local function modifyCasterSpeed(caster, boost)
  caster:set(
    MOVE_SPEED,
    caster:getProp(MOVE_SPEED) + boost
  )
end

function Dash.init(self)
  local boost = self.speed
  modifyCasterSpeed(self.fromCaster, boost)
  -- restore move speed bonus to its former state by subtracting the boost
  tick.delay(function()
    modifyCasterSpeed(self.fromCaster, -boost)
    self:delete()
  end, self.duration)
end

return Component.createFactory(Dash)