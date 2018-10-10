local msgBus = require 'components.msg-bus'
local Promise = require 'utils.promise'

return function(fn)
  local d = Promise.new()
  local listener = msgBus.on(msgBus.UPDATE, function()
    local done, success, errors = fn(d)
    if done then
      if errors then
        d:reject(errors)
      else
        d:resolve(success)
      end
      return msgBus.CLEANUP
    end
  end)
  return d
end