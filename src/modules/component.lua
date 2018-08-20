local isDebug = require 'config'.isDebug
local tc = require 'utils.type-check'
local uid = require 'utils.uid'
local inspect = require 'utils.inspect'
local noop = require 'utils.noop'
local objectUtils = require 'utils.object-utils'
local Q = require 'modules.queue'
local typeCheck = require 'utils.type-check'
local pprint = require 'utils.pprint'
local collisionObject = require 'modules.collision'

local M = {}

-- built-in defaults
local floor = math.floor
local baseProps = {
  x = 0,
  y = 0,
  angle = 0,
  scale = 1,

  drawOrder = function(self)
    return 1
  end,

  -- gets called on the next `update` frame
  init = noop,

  -- these methods will not be called until the component has been initialized
  update = noop,
  draw = noop,
  final = noop,
  _update = function(self, dt)
    local parent = self.parent
    if parent then
      if parent._deleted then
        -- remove parent reference
        self:setParent(nil)

        if parent._deleteRecursive then
          self:delete(true)
          return
        end
      end

      -- update position relative to its parent
      local dx, dy =
        self.prevParentX and (parent.x - self.prevParentX) or 0,
        self.prevParentY and (parent.y - self.prevParentY) or 0
      self:setPosition(self.x + dx, self.y + dy)
      self.prevParentX = parent.x
      self.prevParentY = parent.y
    end
    self:update(dt)
  end,
}

local function cleanupCollisionObjects(self)
  if self.collisionObjects then
    for i=1, #self.collisionObjects do
      self.collisionObjects[i]:delete()
    end
  end
end

--[[
  x[NUMBER]
  y[NUMBER]
  initialProps[table] - a key/value hash of properties
]]
function M.createFactory(blueprint)
  tc.validate(blueprint.getInitialProps, tc.FUNCTION, false)

  function blueprint.create(props)
    local c = (props or {})

    local id = uid()
    c._id = id
    setmetatable(c, blueprint)
    blueprint.__index = blueprint

    -- type check
    if isDebug then
      assert(c.group ~= nil, 'a default `group` must be provided')
      tc.validate(c.x, tc.NUMBER, false) -- x-axis position
      tc.validate(c.y, tc.NUMBER, false) -- y-axis position
      tc.validate(c.angle, tc.NUMBER, false)
    end

    c:setGroup(c.group)
    c:init()
    return c
  end

  function blueprint:getPosition()
    return self.x, self.y
  end

  function blueprint:setPosition(x, y)
    self.x = x
    self.y = y
    return self
  end

  -- sets the parent if a parent is provided, otherwise unsets it (when parent is `nil`)
  function blueprint:setParent(parent)
    self.parent = parent
    return self
  end

  function blueprint:setGroup(group)
    if not group and self.group then
      self.group.removeComponent(self)
    else
      group.addComponent(self)
    end
    return self
  end

  function blueprint:delete(recursive)
    self.group.delete(self)
    self._deleteRecursive = recursive
    cleanupCollisionObjects(self)
    return self
  end

  function blueprint:getId()
    return self._id
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

  local drawQ = Q:new({development = isDebug})
  local Group = groupDefinition
  local componentsById = {}
  local count = 0

  function Group.updateAll(dt)
    for id,c in pairs(componentsById) do
      c:_update(dt)
    end
    return Group
  end

  function Group.drawAll()
    for id,c in pairs(componentsById) do
      drawQ:add(c:drawOrder(), c.draw, c)
    end

    drawQ:flush()
    return Group
  end

  function Group.getStats()
    return count
  end

  function Group.addComponent(component)
    count = count + 1
    componentsById[component:getId()] = component
  end

  function Group.delete(component)
    if component._deleted then
      if isDebug then
        print('[WARNING] component already deleted:', component._id)
      end
      return
    end

    componentsById[component._id] = nil
    count = count - 1
    component:final()
    -- set deleted state. (this is for debugging purposes only)
    component._deleted = true
    return Group
  end

  function Group.deleteAll()
    for id,c in pairs(componentsById) do
      c:delete()
    end
    return Group
  end

  return Group
end

return M