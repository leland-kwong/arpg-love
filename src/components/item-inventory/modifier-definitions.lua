--[[
  loot modifier definitions
]]
local Vec2 = require 'modules.brinevector'

return {
  cooldownReduction = {
    range = Vec2(0.01, 0.1),
  },
  attackTimeReduction = {
    range = Vec2(0.01, 0.1)
  },
  percentDamage = {
    range = Vec2(0.1, 0.2)
  },
  armor = {
    range = Vec2(10,100)
  },
  maxHealth = {
    range = Vec2(50, 100)
  },
  healthRegeneration = {
    range = Vec2(3, 6)
  },
  maxEnergy = {
    range = Vec2(10, 20)
  },
  energyRegeneration = {
    range = Vec2(1, 2)
  },
  moveSpeed = {
    range = Vec2(10, 15)
  },
}