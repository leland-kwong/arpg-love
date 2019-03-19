local Component = require 'modules.component'
local Vec2 = require 'modules.brinevector'

--[[
  Component properties

  magnitude [VECTOR2] - x and y magnitudes of the force
  actsOn [STRING] - the id of the entity for the force to act on
]]

local previousForces = {}
local VECTOR_0 = Vec2()
local defaultDuration = math.pow(100, 100)

return function(dt)
  for id in pairs(previousForces) do
    local ref = Component.get(id)
    if ref then
      ref:set('force', VECTOR_0)
    end
  end

  local components = Component.groups.gravForce.getAll()
  local forcesByTarget = {}
  for id,v in pairs(components) do
    local currentForce = forcesByTarget[v.actsOn] or VECTOR_0
    local totalForce = currentForce + v.magnitude
    forcesByTarget[v.actsOn] = totalForce
    local ref = Component.get(v.actsOn)
    if ref then
      ref:set('force', totalForce)
    end
    v.lifeTime = (v.lifeTime or v.duration or defaultDuration) - dt
    local expired = v.lifeTime <= 0
    if expired then
      Component.removeFromGroup(id, 'gravForce')
    end
  end
  previousForces = forcesByTarget
end