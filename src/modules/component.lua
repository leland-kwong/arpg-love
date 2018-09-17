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

-- built-in defaults
local floor = math.floor
local baseProps = {
  x = 0,
  y = 0,
  z = 0, -- axis normal to the x-y plane
  angle = 0,
  scale = 1,

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
  _isComponent = true,
}

local function cleanupCollisionObjects(self)
  if self.collisionObjects then
    for i=1, #self.collisionObjects do
      self.collisionObjects[i]:delete()
    end
    self.collisionObjects = nil
  end
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
      not c._isComponent,
      invalidPropsErrorMsg
    )

    local id = blueprint.id or uid()
    c._id = id

    setmetatable(c, blueprint)
    blueprint.__index = blueprint

    -- type check
    if isDebug then
      if (props and props.id) then
        assert(uniqueIds[props.id], 'unique ids must be registered in the factory')
      end
      assert(c.group ~= nil, 'a default `group` must be provided')
      tc.validate(c.x, tc.NUMBER, false) -- x-axis position
      tc.validate(c.y, tc.NUMBER, false) -- y-axis position
      tc.validate(c.angle, tc.NUMBER, false)
    end

    -- add component to default group first
    c.group.addComponent(c)
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

  function blueprint:setGroup(group)
    if self.group then
      self.group.removeComponent(self)
    end
    group.addComponent(self)
    self.group = group
    return self
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

    self.group.delete(self)
    cleanupCollisionObjects(self)
    self._deleted = true
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

  function Group.drawAll()
    for id,c in pairs(componentsById) do
      if c:isReady() and (not c._drawDisabled) then
        local drawFunc = (c.debug == true) and c._drawDebug or c.draw
        drawQueue:add(c:drawOrder(), drawFunc, c)
      end
    end

    drawQueue:flush()
    return Group
  end

  function Group.getStats()
    return count
  end

  function Group.addComponent(component)
    count = count + 1
    local id = component:getId()

    allComponentsById[id] = component
    componentsById[id] = component
  end

  function Group.removeComponent(component)
    count = count - 1
    local id = component:getId()
    componentsById[id] = nil
  end

  function Group.delete(component)
    if not Group.hasComponent(component) then
      print('[WARNING] component already deleted:', component._id)
      return
    end

    local id = component:getId()
    componentsById[id] = nil
    allComponentsById[id] = nil
    count = count - 1
    component:final()
    return Group
  end

  function Group.hasComponent(component)
    return componentsById[component._id]
  end

  return Group
end

function M.get(id)
  return allComponentsById[id]
end

return M