local groups = require 'components.groups'
local extend = require 'utils.object-utils'.extend

local baseClass = {
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
  lifeTime = 2,
  speed = 250,
  cooldown = 0.1,
  targetGroup = 'ai',
}

return function(props)
  return extend(baseClass, props)
end