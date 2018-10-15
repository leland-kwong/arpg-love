local config = require 'config.config'
local noop = require 'utils.noop'

PROF_CAPTURE = true
local jprof = require('jprof')

return setmetatable({}, {
  __index = function(_, method)
    if config.performanceProfile then
      return jprof[method]
    end
    return noop
  end
})