local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local config = require 'config.config'

local activeEntities = {}

local autoVisibilityGroup = Component.newGroup({
  name = 'autoVisibility'
})

local function visibleItemFilter(item)
  local parent = item.parent
  return autoVisibilityGroup.hasComponent(parent and parent:getId())
end

local floor = math.floor
local function toggleEntityVisibility(self)
  local collisionWorlds = require 'components.collision-worlds'
  local camera = require 'components.camera'
  local threshold = config.gridSize * 2
  local west, _, north = camera:getBounds()
  local width, height = camera:getSize()
  local items, len = collisionWorlds.map:queryRect(
    west - threshold,
    north - threshold, width + (threshold * 2),
    height + (threshold * 2),
    visibleItemFilter
  )

  -- reset active entities
  for _,entity in pairs(activeEntities) do
    entity.isInViewOfPlayer = false
  end
  activeEntities = {}

  -- set new list of active entities
  for i=1, len do
    local entity = items[i].parent
    local entityId = entity:getId()
    entity.isInViewOfPlayer = true
    activeEntities[entityId] = entity
  end
end

msgBus.on(msgBus.UPDATE, function()
  toggleEntityVisibility(self)
end)