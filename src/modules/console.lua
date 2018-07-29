local groups = require 'components.groups'
local inputBus = require 'components.msg-bus'.input
local Color = require 'modules.color'
local config = require 'config'

local modifier = false
local keysPressed = {}
local L_SUPER = 'lgui'
local R_SUPER = 'rgui'

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
  if (keysPressed[L_SUPER] or keysPressed[R_SUPER])
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

local edgeOffset = 10
local fontSize = 14

local function printTable(t, fontSize, x, y)
  local i = 0
  for k,v in pairs(t) do
    love.graphics.print(
      k..': '..v,
      x,
      y + (i * fontSize)
    )
    i = i + 1
  end
end

Console.drawOrder = groups.DRAW_ORDER_CONSOLE

function Console.draw()
  local gfx = love.graphics
  gfx.setColor(Color.WHITE)
  gfx.print(
    'objects: '..groups.all.getStats(),
    edgeOffset,
    edgeOffset
  )

  local startY = (fontSize * 2) + edgeOffset
  gfx.setColor(Color.MED_GRAY)
  gfx.print('GRAPHICS', edgeOffset, startY)
  gfx.setColor(Color.WHITE)
  -- print out each stat on its own line
  printTable(
    gfx.getStats(),
    fontSize,
    edgeOffset,
    startY + fontSize
  )
end

return groups.all.createFactory(Console)
