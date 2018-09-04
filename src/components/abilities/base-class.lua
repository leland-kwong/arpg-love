local groups = require 'components.groups'
local setProp = require 'utils.set-prop'

return function()
  return setProp({
    group = groups.all,

    -- [DEFAULTS]

    -- start position
    x = 0,
    y = 0,

    -- target position
    x2 = 0,
    y2 = 0,
    minDamage = 1,
    maxDamage = 2,
    weaponDamageScaling = 1,
    lifeTime = 2,
    speed = 250,
    cooldown = 0.1,
    targetGroup = 'ai'
  })
end