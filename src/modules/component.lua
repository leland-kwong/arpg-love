local config = require 'config.config'
local isDevelopment = config.isDevelopment
local tc = require 'utils.type-check'
local uid = require 'utils.uid'
local noop = require 'utils.noop'
local objectUtils = require 'utils.object-utils'
local Q = require 'modules.queue'
local collisionObject = require 'modules.collision'
local setProp = require 'utils.set-prop'

local M = {}
local allComponentsById = {}
local EMPTY = objectUtils.setReadOnly({})

-- built-in defaults
local floor = math.floor
local baseProps = {
  x = 0,
  y = 0,
  z = 0, -- axis normal to the x-y plane
  angle = 0,
  outOfBoundsX = 0,
  outOfBoundsY = 0,
  isOutsideViewport = false,

  drawOrder = function(self)
    return 1
  end,

  -- gets called on the next `update` frame
  init = noop,

  -- these methods will not be called until the component has been initialized
  update = noop, -- optional
  draw = noop, -- optional
  final = noop, -- optional
  _update = function(self, dt)
    self._ready = true
    self:update(dt)
    local children = self._children
    if children then
      local hasChangedPosition = self.x ~= self._prevX
        or self.y ~= self._prevY
        or self.z ~= self._prevZ

      if hasChangedPosition then
        for _,child in pairs(children) do
          -- update position relative to its parent
          local dx, dy, dz =
            (self.x - child.prevParentX),
            (self.y - child.prevParentY),
            (self.z - child.prevParentZ)
          child:setPosition(child.x + dx, child.y + dy, child.z + dz)
          child.prevParentX = self.x
          child.prevParentY = self.y
          child.prevParentZ = self.z
        end

        self._prevX = self.x
        self._prevY = self.y
        self._prevZ = self.z
      end
    end
  end,
  _drawDebug = function(self)
    self.draw(self)
    local colObjects = self.collisionObjects
    love.graphics.setColor(1,1,0,0.4)
    if colObjects then
      for i=1, #colObjects do
        local c = colObjects[i]
        local x, y = c:getPositionWithOffset()
        love.graphics.rectangle(
          'fill',
          x, y,
          c.w, c.h
        )
        love.graphics.rectangle(
          'line',
          x, y,
          c.w, c.h
        )
      end
    end
    love.graphics.setColor(0,1,0,0.2)
    love.graphics.circle(
      'fill',
      self.x,
      self.y,
      2
    )
  end,
  isComponent = true,
}

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
  local isIdComponent = type(id) == 'table'
  id = isIdComponent and id:getId() or id
  local name = getGroupName(group)
  local group = M.groups[name]
  if group then
    -- check if an entity has been added or not before removing
    group.removeComponent(id)
  end
  return M
end

--[[
  x[NUMBER]
  y[NUMBER]
  initialProps[table] - a key/value hash of properties
]]
local invalidPropsErrorMsg = 'props cannot be a component object'

local uniqueIds = {}

local entityMt = {
  __index = function(t, k)
    local firstVal = t.initialProps[k]
    if firstVal ~= nil then
      return firstVal
    end
    return t.blueprint[k]
  end
}

function M.createFactory(blueprint)
  if blueprint.id then
    local isUniqueId = not uniqueIds[blueprint.id]
    assert(
      isUniqueId,
      'Duplicate id '..blueprint.id..'. Fixed ids must be unique amongst all factories'
    )
    -- add id to list of unique ids
    uniqueIds[blueprint.id] = true
  end

  function blueprint.create(props)
    props = props or {}
    assert(type(props) == 'table', 'props must be of type `table` or `nil`')
    local c = setProp({
      -- by keeping initial props as its own property, we can keep the input values immutable.
      initialProps = props,
      blueprint = blueprint
    }, isDevelopment)
    assert(
      not c.isComponent,
      invalidPropsErrorMsg
    )

    local componentWithDuplicateId = M.get(props.id)
    if componentWithDuplicateId then
      componentWithDuplicateId:delete(true)
    end

    local id = blueprint.id or (props and props.id) or uid()
    c._id = id

    setmetatable(c, entityMt)

    -- type check
    if isDevelopment then
      tc.validate(c.x, tc.NUMBER, false) -- x-axis position
      tc.validate(c.y, tc.NUMBER, false) -- y-axis position
      tc.validate(c.angle, tc.NUMBER, false)
    end

    -- add to all components list
    allComponentsById[id] = c

    -- add component to default group
    if c.group then
      M.addToGroup(id, c.group, c)
    end
    c:init()
    return c
  end

  function blueprint:getPosition()
    return self.x, self.y, self.z
  end

  function blueprint:setPosition(x, y, z)
    self.x = x
    self.y = y
    self.z = z
    return self
  end

  function blueprint:setDisabled(isDisabled)
    self:setUpdateDisabled(isDisabled)
    self:setDrawDisabled(isDisabled)
    return self
  end

  function blueprint:setDrawDisabled(isDisabled)
    self._drawDisabled = isDisabled
    return self
  end

  function blueprint:setUpdateDisabled(isDisabled)
    self._updatedDisabled = isDisabled
    return self
  end

  --[[
    Sets the parent if a parent is provided, otherwise unsets it (when parent is `nil`).
    We don't want an `addChild` method so we can avoid coupling between child and parent.
  ]]
  function blueprint:setParent(parent)
    local isSameParent = parent == self.parent
    if isSameParent then
      return self
    end

    local id = self:getId()
    -- dissasociate itself from previous parent
    local previousParent = self.parent
    if (previousParent and previousParent._children) then
      previousParent._children[id] = nil
    end

    if (not parent) then
      self.parent = nil
      return self
    end

    --[[
      The child's position will now be relative to its parent,
      so we need to store the parent's initial position
    ]]
    self.prevParentX = parent.x
    self.prevParentY = parent.y
    self.prevParentZ = parent.z

    -- set new parent
    self.parent = parent
    parent._children = parent._children or {}
    -- add self as child to its parent
    parent._children[id] = self
    return self
  end

  function blueprint:delete(recursive)
    if self._deleted then
      return
    end
    M.remove(self:getId(), recursive)
    return self
  end

  function blueprint:getId()
    return self._id
  end

  function blueprint:isDeleted()
    return self._deleted
  end

  -- default methods
  for k,v in pairs(baseProps) do
    if not blueprint[k] then
      blueprint[k] = baseProps[k] or v
    end
  end

  function blueprint:addCollisionObject(group, x, y, w, h, ox, oy)
    self.collisionObjects = self.collisionObjects or {}
    local colObj = collisionObject:new(group, x, y, w, h, ox, oy)
      :setParent(self)
    table.insert(self.collisionObjects, colObj)
    return colObj
  end

  return blueprint
end

function M.newGroup(groupDefinition)
  assert(type(groupDefinition.name) == 'string', 'group name must be a string')

  -- apply any missing default options to group definition
  groupDefinition = objectUtils.assign(
    {},
    defaultGroupOptions,
    groupDefinition or {}
  )

  local Group = groupDefinition
  local drawQueue = Q:new({development = config.debugDrawQueue})
  Group.drawQueue = drawQueue
  local componentsById = {}
  local count = 0

  function Group.updateAll(dt)
    for id,c in pairs(componentsById) do
      if (not c._updatedDisabled) then
        c:_update(dt)
      end
    end

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

    allComponentsById[id] = data
    componentsById[id] = data
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
    local entity = M.entitiesById[id]
    local component = entity[Group.name]
    if Group.onComponentLeave then
      Group:onComponentLeave(component)
    end
    -- remove global reference
    entity[Group.name] = nil
    if (type(component) ~= 'table') or component._deleted then
      allComponentsById[id] = nil
    end
  end

  function Group.hasComponent(id)
    return not not componentsById[id]
  end

  function Group.getAll()
    return componentsById
  end

  function Group.get(_, id)
    return componentsById[id]
  end

  M.groups[Group.name] = Group
  return Group
end

M.newSystem = M.newGroup
M.systems = M.groups

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

  -- this is for legacy reasons when our entites weren't just plain tables
  local entityAsComponent = allComponentsById[entityId]
  if entityAsComponent.isComponent then
    local eAsC = entityAsComponent
    local children = eAsC._children
    if (recursive and children) then
      for _,child in pairs(children) do
        child:delete(true)
      end
      eAsC._children = nil
    end

    cleanupCollisionObjects(eAsC)
    eAsC._deleted = true
    eAsC:final()
  end

  local ownGroups = M.entitiesById[entityId] or EMPTY
  for group in pairs(ownGroups) do
    M.removeFromGroup(entityId, group)
  end
  M.entitiesById[entityId] = nil
end

-- Method for creating components without a factory
local NodeFactory = M.createFactory({})
M.create = NodeFactory.create
M.newId = uid

M.newGroup({
  name = 'emptyGroup'
})

return M