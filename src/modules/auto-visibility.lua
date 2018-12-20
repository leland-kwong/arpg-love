local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local config = require 'config.config'

local previousItems = {}

local autoVisibilityGroup = Component.newGroup({
  name = 'autoVisibility'
})

local function visibleItemFilter(item)
  local parent = item.parent
  return autoVisibilityGroup.hasComponent(parent and parent:getId())
end

local function toggleEntityVisibility(self)
  local collisionWorlds = require 'components.collision-worlds'
  local camera = require 'components.camera'
  local threshold = config.gridSize * 3
  local west, _, north = camera:getBounds()
  local width, height = camera:getSize()
  local items, len = collisionWorlds.map:queryRect(
    west - threshold,
    north - threshold,
    width + (threshold * 2),
    height + (threshold * 2),
    visibleItemFilter
  )

  -- reset previously active entities
  for i=1, #previousItems do
    local entity = previousItems[i].parent
    entity.isInViewOfPlayer = false
  end
  previousItems = items

  -- set visibility for new active entities
  for i=1, len do
    local entity = items[i].parent
    entity.isInViewOfPlayer = true
  end
end

msgBus.on(msgBus.UPDATE, toggleEntityVisibility)