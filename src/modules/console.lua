local groups = require 'components.groups'
local inputBus = require 'components.msg-bus'.input
local config = require 'config'
local modifier = false

local keysPressed = {}
local L_SUPER = 'lgui'

local function toggleCollisionDebug()
  config.collisionDebug = not config.collisionDebug
end

inputBus.subscribe(function(msgType, v)
  if ((inputBus.KEY_PRESSED == msgType) or (inputBus.KEY_RELEASED == msgType)) and
    not v.isRepeated
  then
    keysPressed[v.key] = inputBus.KEY_PRESSED == msgType
  end

  -- toggle collision debugger
  if keysPressed[L_SUPER]
    and keysPressed.p
    and not v.isRepeated
  then
    toggleCollisionDebug()
  end
end)

local Console = {}

function Console.getInitialProps()
  return {}
end

local pprint = require 'utils.pprint'

function Console.draw()
  love.graphics.print(
    'count: '..groups.all.getStats(),
    0,
    15
  )

  -- pprint(love.graphics.getStats())
end

return groups.all.createFactory(Console)
