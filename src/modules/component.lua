local isDebug = require 'config'.isDebug
local tc = require 'utils.type-check'
local uid = require 'utils.uid'
local inspect = require 'utils.inspect'
local noop = require 'utils.noop'
local objectUtils = require 'utils.object-utils'
local Q = require 'modules.queue'
local typeCheck = require 'utils.type-check'
local pprint = require 'utils.pprint'

local M = {}

-- built-in defaults
local floor = math.floor
local baseProps = {
  x = 0,
  y = 0,
  angle = 0,
  scale = 1,

  drawOrder = function(self)
    local o = floor(self.y)
    return o < 1 and 1 or o
  end,

  -- gets called on the next `update` frame
  init = noop,

  -- these methods will not be called until the component has been initialized
  update = noop,
  draw = noop,
  final = noop,
  _update = function(self, dt)
    if self.parent then
      -- update position relative to its parent
      local dx, dy =
        self.prevParentX and (self.parent.x - self.prevParentX) or 0,
        self.prevParentY and (self.parent.y - self.prevParentY) or 0
      self:setPosition(self.x + dx, self.y + dy)
      self.prevParentX = self.parent.x
      self.prevParentY = self.parent.y
    end
    self:update(dt)
  end
}

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

  function blueprint:delete()
    self.group.delete(self)
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
      if not c._initialized then
        c._initialized = true
        c:init()
      end
      c:_update(dt)
    end
    return Group
  end

  function Group.drawAll()
    for id,c in pairs(componentsById) do
      if c._initialized then
        drawQ:add(c:drawOrder(), c.draw, c)
      end
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
    if component._initialized then
      component:final()
    end
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