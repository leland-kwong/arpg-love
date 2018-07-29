local M = {}
local isDebug = require 'config'.isDebug
local tc = require 'utils.type-check'
local uid = require 'utils.uid'
local inspect = require 'utils.inspect'
local noop = require 'utils.noop'

local errorMsg = {
  getInitialProps = "getInitialProps must return a table"
}

function M.newGroup()
  local C = {}
  local componentsById = {}
  local count = 0

  --[[
    x[NUMBER]
    y[NUMBER]
    initialProps[table] - a key/value hash of properties
  ]]
  function C.createFactory(blueprint)
    tc.validate(blueprint.getInitialProps, tc.FUNCTION)

    function blueprint.create(props)
      local c = blueprint.getInitialProps(props)

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

    local defaults = {
      x = 0,
      y = 0,
      z = 0,
      angle = 0,

      -- gets called on the next `update` frame
      init = noop,

      -- these methods will not be called until the component has been initialized
      update = noop,
      draw = noop,
      final = noop
    }
    -- default methods
    for k,v in pairs(defaults) do
      if not blueprint[k] then
        blueprint[k] = v
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
        c:draw()
      end
    end
  end

  function C.getStats()
    return count
  end

  function C.delete(component)
    componentsById[component._id] = nil
    count = count - 1
    component:final()
  end

  return C
end

return M