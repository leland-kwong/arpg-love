local config = require 'config.config'
local noop = require 'utils.noop'

PROF_CAPTURE = true
local jprof = require('jprof')
local stackReady = false

local customMethods = {
  zoneStart = function(a, b, c)
    stackReady = true
    jprof.push(a, b, c)
  end,
  zoneEnd = function(a, b, c)
    stackReady = false
    jprof.pop(a, b, c)
  end
}

return setmetatable({}, {
  __index = function(_, method)
    if (not config.performanceProfile) then
      return noop
    end

    local custom = customMethods[method]
    if custom then
      return custom
    end
    if (method == 'push') and (not stackReady) then
      return noop
    end
    return jprof[method]
  end
})