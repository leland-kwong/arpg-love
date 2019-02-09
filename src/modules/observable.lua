local msgBus = require 'components.msg-bus'
local Promise = require 'utils.promise'

--[[
  storing this as a global so when we use `dynamicRequire` for liveReloading,
  the list is shared across contexts
]]
globalPendingPromises = globalPendingPromises or {}
globalPromiseCallbacks = globalPromiseCallbacks or {}
local pendingPromises = globalPendingPromises
local promiseCallbacks = globalPromiseCallbacks

local function flushPromises()
  local i = 1
  while i <= #pendingPromises do
    local promise = pendingPromises[i]
    local cb = promiseCallbacks[i]
    local done, successValue, errors = cb(promise)
    if done then
      if errors then
        promise:reject(errors)
      else
        promise:resolve(successValue)
      end
      table.remove(pendingPromises, i)
      table.remove(promiseCallbacks, i)
    else
      i = i + 1
    end
  end
end

msgBus.on('UPDATE', flushPromises)

local Observable = {}
local mt = {}
mt.__index = mt

function mt.__call(self, fn)
  local d = Promise.new()
  table.insert(promiseCallbacks, fn)
  table.insert(pendingPromises, d)
  return d
end

mt.all = Promise.all

setmetatable(Observable, mt)

return Observable