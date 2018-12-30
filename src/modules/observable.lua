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

function mt.all(observableList)
  local numObservables = #observableList
  local doneCount = 0
  local done = false
  local _error
  local successValues = {}
  for i=1, #observableList do
    local o = observableList[i]
    o:next(function(v)
      doneCount = doneCount + 1
      if (doneCount == numObservables) then
        done = true
      end
      if (not _error) then
        table.insert(successValues, v)
      end
    end, function(err)
      doneCount = doneCount + 1
      done = true
      _error = err
    end)
  end

  return Observable(function()
    return done, successValues, _error
  end)
end

setmetatable(Observable, mt)

return Observable