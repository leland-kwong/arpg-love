local config = require 'config.config'
local isDevelopment = config.isDevelopment
local tc = require 'utils.type-check'
local uid = require 'utils.uid'
local objectUtils = require 'utils.object-utils'

local allComponentsById = {}
local M = {
  debug = {
    drawQueueStats = true
  },
  allComponentsById = allComponentsById
}
local EMPTY = objectUtils.EMPTY

local function cleanupCollisionObjects(self)
  if self.collisionObjects then
    for i=1, #self.collisionObjects do
      self.collisionObjects[i]:delete()
    end
    self.collisionObjects = nil
  end
end

M.groups = setmetatable({}, {
  -- default to emptyGroup
  __index = function(groups)
    return groups.emptyGroup
  end
})
M.entitiesById = {}

local function getGroupName(group)
  return type(group) == 'string' and group or group.name
end

function M.addToGroup(id, group, data)
  if (not id) then
    error('invalid id', id)
  end

  -- backwards compatiblity with older component system
  local isIdComponent = type(id) == 'table'
  if (isIdComponent) then
    data = id
    id = id:getId()
  end

  local groupName = getGroupName(group)
  local entity = M.entitiesById[id]
  if (not entity) then
    entity = {}
    M.entitiesById[id] = entity
  end
  entity[groupName] = data or EMPTY
  local group = M.groups[groupName]
  local isNewGroup = group == M.groups.emptyGroup
  if (isNewGroup) then
    group = M.newGroup({
      name = groupName
    })
  end
  group.addComponent(id, data)
  return M
end

function M.removeFromGroup(id, group)
  local isIdComponent = (type(id) == 'table') and id.isComponent
  id = isIdComponent and id:getId() or id
  local name = getGroupName(group)
  local group = M.groups[name]
  if group then
    -- check if an entity has been added or not before removing
    group.removeComponent(id)
  end
  return M
end

function M.clearGroup(group)
  local groupName = getGroupName(group)
  for id in pairs(M.groups[groupName].getAll()) do
    M.removeFromGroup(id, groupName)
  end
end

M.createFactory = require 'modules.component.create-factory'(M)

function M.newGroup(groupDefinition)
  assert(type(groupDefinition.name) == 'string', 'group name must be a string')

  -- apply any missing default options to group definition
  groupDefinition = objectUtils.assign(
    {},
    defaultGroupOptions,
    groupDefinition or {}
  )

  local Group = groupDefinition

  local drawQueue = require 'modules.component.draw-queue'(M, groupDefinition)
  Group.drawQueue = drawQueue
  local componentsById = {}
  local newComponentsById = {}
  local isUpdating = false
  local count = 0

  function Group.updateAll(dt)
    isUpdating = true

    -- merge in new components to master list
    for entityId,c in pairs(newComponentsById) do
      if M.get(entityId) then
        componentsById[entityId] = c
      end
    end
    newComponentsById = {}

    for id,c in pairs(componentsById) do
      if (not c._updatedDisabled) then
        c:_update(dt)
      end
    end

    isUpdating = false

    return Group
  end

  --[[
    if the component's update lifecycle has not been triggered (ready property is not true),
    this will wait until the next update frame to draw.
  ]]
  local max = math.max
  function Group.drawAll()
    for id,c in pairs(componentsById) do
      if c._ready and (not c._drawDisabled) then
        local drawFunc = (c.debug == true) and c._drawDebug or c.draw
        drawQueue:add(
          max(c:drawOrder(), 1),
          drawFunc,
          c
        )
      end
    end

    drawQueue:flush()
    return Group
  end

  function Group.getStats()
    return count
  end

  function Group.addComponent(id, data)
    local isNewComponent = not Group.hasComponent(id)
    if isNewComponent then
      count = count + 1
    end

    --[[
      when we're in the middle of an update loop, we should add new components to a different list
      to prevent mutating the list which causes the loop to do unintended behavior (duplicate updates, etc...).
    ]]
    if isUpdating then
      newComponentsById[id] = data
    else
      componentsById[id] = data
    end
    if Group.onComponentEnter then
      Group:onComponentEnter(data)
    end
  end

  function Group.removeComponent(id)
    if (not Group.hasComponent(id)) then
      return
    end

    count = count - 1
    componentsById[id] = nil
    newComponentsById[id] = nil
    local entity = M.entitiesById[id]
    local component = entity[Group.name]
    if Group.onComponentLeave then
      Group:onComponentLeave(component)
    end

    entity[Group.name] = nil

    -- remove global reference if no more groups
    if objectUtils.isEmpty(entity) then
      M.entitiesById[id] = nil
    end
  end

  function Group.hasComponent(id)
    return (not not componentsById[id])
      or (not not newComponentsById[id])
  end

  function Group.getAll()
    return componentsById
  end

  M.groups[Group.name] = Group
  return Group
end

M.newSystem = M.newGroup

function M.get(id)
  return allComponentsById[id]
end

function M.getBlueprint(component)
  return component.blueprint
end

function M.getChildren(component)
  return component and component._children or EMPTY
end

function M.remove(entityId, recursive)
  local idType = type(entityId)
  assert(
    idType == 'string' or idType == 'number',
    'entity id must be a number or string'
  )

  local entity = allComponentsById[entityId]
  if entity and entity.isComponent and (not entity._deleted) then
    local children = entity._children
    if (recursive and children) then
      for _,child in pairs(children) do
        child:delete(true)
      end
      entity._children = nil
    end

    cleanupCollisionObjects(entity)

    entity._deleted = true
    entity:final()
  end

  local ownGroups = M.entitiesById[entityId] or EMPTY
  for group in pairs(ownGroups) do
    M.removeFromGroup(entityId, group)
  end
  M.entitiesById[entityId] = nil
  allComponentsById[entityId] = nil
end

-- Method for creating components without a factory
local NodeFactory = M.createFactory({})
M.create = NodeFactory.create
M.newId = uid

M.newGroup({
  name = 'emptyGroup'
})

return M