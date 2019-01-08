local Component = require 'modules.component'
local Promise = require 'utils.promise'

--[[
  storing this as a global so when we use `dynamicRequire` for liveReloading,
  the list is shared across contexts
]]
globalPendingPromises = globalPendingPromises or {}
local pendingPromises = globalPendingPromises

local function flushPromises()
  local i = 1
  while i <= #pendingPromises do
    local cb = pendingPromises[i]
    local done = cb()
    if done then
      table.remove(pendingPromises, i)
    else
      i = i + 1
    end
  end
end

Component.create({
  id = 'observable-init',
  init = function(self)
    Component.addToGroup(self, 'firstLayer')
  end,
  update = flushPromises
})

local Observable = {}
local mt = {}
mt.__index = mt

function mt.__call(self, fn)
  local d = Promise.new()
  table.insert(pendingPromises, function()
    local done, successValue, errors = fn(d)
    if done then
      if errors then
        d:reject(errors)
      else
        d:resolve(successValue)
      end
    end
    return done
  end)
  return d
end

mt.all = Promise.all

setmetatable(Observable, mt)

return Observable