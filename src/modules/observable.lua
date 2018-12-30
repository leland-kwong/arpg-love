local msgBus = require 'components.msg-bus'
local Promise = require 'utils.promise'

local Observable = {}
local mt = {}
mt.__index = mt

function mt.__call(self, fn)
  local d = Promise.new()
  local listener = msgBus.on(msgBus.UPDATE, function()
    local done, successValue, errors = fn(d)
    if done then
      if errors then
        d:reject(errors)
      else
        d:resolve(successValue)
      end
      return msgBus.CLEANUP
    end
  end)
  return d
end

mt.all = Promise.all

setmetatable(Observable, mt)

return Observable