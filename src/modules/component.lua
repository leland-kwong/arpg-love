local isDebug = require 'config.config'.isDebug
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
  scale = 1,
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
      local hasChangedPosition = self.x ~= self.prevX
        or self.y ~= self.prevY
        or self.z ~= self.prevZ

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

        self.prevX = self.x
        self.prevY = self.y
        self.prevZ = self.z
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

M.groups = {}
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

  local name = getGroupName(group)
  if (not M.entitiesById[id]) then
    M.entitiesById[id] = {}
  end
  M.entitiesById[id][name] = data or EMPTY
  M.groups[name].addComponent(id, data)
  return M
end

function M.removeFromGroup(id, group)
  local isIdComponent = type(id) == 'table'
  local id = isIdComponent and id:getId() or id
  local name = getGroupName(group)
  M.groups[name].removeComponent(id)
  return M
end

--[[
  x[NUMBER]
  y[NUMBER]
  initialProps[table] - a key/value hash of properties
]]
local invalidPropsErrorMsg = 'props cannot be a component object'

local uniqueIds = {}

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
    assert(type(props) == 'table' or props == nil, 'props must be of type `table` or `nil`')
    local c = setProp(props or {}, isDebug)
    assert(
      not c.isComponent,
      invalidPropsErrorMsg
    )

    local id = blueprint.id or (props and props.id) or uid()
    c._id = id

    setmetatable(c, blueprint)
    blueprint.__index = blueprint

    -- type check
    if isDebug then
      tc.validate(c.x, tc.NUMBER, false) -- x-axis position
      tc.validate(c.y, tc.NUMBER, false) -- y-axis position
      tc.validate(c.angle, tc.NUMBER, false)
    end

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

    --[[
      The child's position will now be relative to its parent,
      so we need to store the parent's initial position
    ]]
    self.prevParentX = parent.x
    self.prevParentY = parent.y
    self.prevParentZ = parent.z

    local id = self:getId()
    -- dissasociate itself from previous parent
    local previousParent = self.parent
    if (previousParent and previousParent._children) then
      previousParent._children[id] = nil
    end

    -- set new parent
    self.parent = parent
    parent._children = parent._children or {}
    -- add self as child to its parent
    parent._children[id] = self
    return self
  end

  function blueprint:getProp(prop)
    return self[prop]
  end

  function blueprint:delete(recursive)
    if self._deleted then
      return
    end

    local children = self._children
    if (recursive and children) then
      for _,child in pairs(children) do
        child:delete(true)
      end
      self._children = nil
    end

    cleanupCollisionObjects(self)
    self._deleted = true
    self:final()

    -- remove from associated group
    local ownGroups = M.entitiesById[self:getId()] or EMPTY
    for group in pairs(ownGroups) do
      M.removeFromGroup(self, group)
    end
    return self
  end

  function blueprint:getId()
    return self._id
  end

  function blueprint:isDeleted()
    return self._deleted
  end

  function blueprint:isReady()
    return self._ready
  end

  function blueprint:checkOutOfBounds(threshold)
    threshold = threshold or 0
    local camera = require 'components.camera'
    local west, east, north, south = camera:getBounds()
    -- add bounds data
    local x, y = self.x, self.y
    local outOfBoundsX, outOfBoundsY = 0, 0
    if x < west then
      outOfBoundsX = west - x
    elseif x > east then
      outOfBoundsX = x - east
    end
    if y < north then
      outOfBoundsY = north - y
    elseif y > south then
      outOfBoundsY = y - south
    end

    return (outOfBoundsX > threshold) or
      (outOfBoundsY > threshold)
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
  local drawQueue = Q:new({development = isDebug})
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

  local max = math.max
  function Group.drawAll()
    for id,c in pairs(componentsById) do
      if c:isReady() and (not c._drawDisabled) then
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
    count = count + 1
    allComponentsById[id] = data
    componentsById[id] = data
    if Group.onComponentEnter then
      Group:onComponentEnter(data)
    end
  end

  function Group.removeComponent(id)
    count = count - 1
    componentsById[id] = nil
    local component = M.entitiesById[id][Group.name]
    -- remove global reference
    if component._deleted then
      allComponentsById[id] = nil
    end
    if Group.onComponentLeave then
      Group:onComponentLeave(component)
    end
  end

  function Group.getAll()
    return componentsById
  end

  M.groups[Group.name] = Group
  return Group
end

M.newSystem = M.newGroup
M.systems = M.groups

function M.get(id)
  return allComponentsById[id]
end

local NodeFactory = M.createFactory({})
M.create = NodeFactory.create

return M