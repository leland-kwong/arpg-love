local isDebug = require 'config'.isDebug
local tc = require 'utils.type-check'
local uid = require 'utils.uid'
local inspect = require 'utils.inspect'
local noop = require 'utils.noop'
local Q = require 'modules.queue'

local M = {}

local drawQ = Q:new({development = isDebug})
local errorMsg = {
  getInitialProps = "getInitialProps must return a table"
}

function M.setMaxOrder(v)
  drawQ:setMaxOrder(v)
end

-- built-in defaults
local floor = math.floor
local baseProps = {
  x = 0,
  y = 0,
  angle = 0,

  getInitialProps = function(props)
    return props
  end,

  drawOrder = function(self)
    local o = floor(self.y)
    return o < 1 and 1 or o
  end,

  -- gets called on the next `update` frame
  init = noop,

  -- these methods will not be called until the component has been initialized
  update = noop,
  draw = noop,
  final = noop
}

local pprint = require 'utils.pprint'
function M.newGroup(factoryDefaults)
  factoryDefaults = factoryDefaults or {}

  local C = {}
  local componentsById = {}
  local count = 0

  --[[
    x[NUMBER]
    y[NUMBER]
    initialProps[table] - a key/value hash of properties
  ]]
  function C.createFactory(blueprint)
    -- call the blueprint with the factory defaults
    if type(blueprint) == 'function' then
      return C.createFactory(
        blueprint(factoryDefaults)
      )
    end

    tc.validate(blueprint.getInitialProps, tc.FUNCTION, false)

    function blueprint.create(props)
      local c = blueprint.getInitialProps(props or {})

      -- type check
      if isDebug then
        assert(type(c) == tc.TABLE, errorMsg.getInitialProps)
        tc.validate(c.x, tc.NUMBER, false) -- x-axis position
        tc.validate(c.y, tc.NUMBER, false) -- y-axis position
        tc.validate(c.z, tc.NUMBER, false) -- z-order
        tc.validate(c.angle, tc.NUMBER, false)
      end

      local id = uid()
      c._id = id
      componentsById[id] = c
      count = count + 1
      setmetatable(c, blueprint)
      blueprint.__index = blueprint
      return c
    end

    function blueprint:delete()
      C.delete(self)
      return self
    end

    -- default methods
    for k,v in pairs(baseProps) do
      if not blueprint[k] then
        blueprint[k] = factoryDefaults[k] or v
      end
    end

    return blueprint
  end

  function C.updateAll(dt)
    for id,c in pairs(componentsById) do
      if not c._initialized then
        c._initialized = true
        c:init()
      end
      c:update(dt)
    end
  end

  function C.drawAll()
    for id,c in pairs(componentsById) do
      if c._initialized then
        drawQ:add(c:drawOrder(), c.draw, c)
      end
    end
    drawQ:flush()
  end

  function C.getStats()
    return count
  end

  function C.delete(component)
    if component._deleted then
      if isDebug then
        print('component already deleted:', component._id)
      end
      return
    end

    componentsById[component._id] = nil
    count = count - 1
    component:final()
    component._deleted = true
  end

  return C
end

return M