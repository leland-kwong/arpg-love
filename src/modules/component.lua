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
        tc.validate(c.x, tc.NUMBER) -- x-axis position
        tc.validate(c.y, tc.NUMBER) -- y-axis position
        tc.validate(c.z, tc.NUMBER, false) -- z-order
        tc.validate(c.angle, tc.NUMBER, false)
      end

      local id = uid()
      c._id = id
      componentsById[id] = c
      setmetatable(c, blueprint)
      blueprint.__index = blueprint

      c:init()
      return c
    end

    local defaults = {
      z = 0,
      init = noop,
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

    function blueprint:delete()
      componentsById[self._id] = nil
      self:final()
    end

    return blueprint
  end

  function C.updateAll(dt)
    for id,component in pairs(componentsById) do
      component:update(dt)
    end
  end

  function C.drawAll()
    for id,component in pairs(componentsById) do
      component:draw()
    end
  end

  return C
end

return M