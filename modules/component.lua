local M = {}
local isDebug = require 'config'.isDebug
local tc = require 'utils.type-check'
local uid = require 'utils.uid'
local inspect = require 'utils.inspect'
local noop = require 'utils.noop'

function M.newGroup()
  local C = {}
  local componentsById = {}

  --[[
    x[NUMBER]
    y[NUMBER]
    initialProps[table] - a key/value hash of properties
  ]]
  function C.createFactory(blueprint)
    function blueprint:create(props)
      local c = blueprint.getInitialProps(props)
      local id = uid()
      c._id = id
      componentsById[id] = c
      setmetatable(c, blueprint)
      blueprint.__index = blueprint

      -- type check
      if isDebug then
        -- x and y properties are for positioning
        tc.validate(c.x, tc.NUMBER)
        tc.validate(c.y, tc.NUMBER)
        tc.validate(c.angle, tc.NUMBER, false)
      end

      c:init()
      return c
    end

    local defaultMethods = {
      init = noop,
      update = noop,
      draw = noop,
      final = noop
    }
    -- default methods
    for k,cb in pairs(defaultMethods) do
      if not blueprint[k] then
        blueprint[k] = cb
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