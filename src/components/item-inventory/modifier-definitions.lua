local Vec2 = require 'modules.brinevector'

return {
  cooldownReduction = {
    range = Vec2(0.01, 0.1),
  },
  attackTimeReduction = {
    range = Vec2(0.01, 0.3)
  },
  percentDamage = {
    range = Vec2(0.2, 0.5)
  },
  armor = {
    range = Vec2(10,100)
  },
  maxHealth = {
    range = Vec2(50, 100)
  },
  maxEnergy = {
    range = Vec2(10, 20)
  }
}