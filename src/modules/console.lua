local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local config = require 'config'

local modifier = false
local keysPressed = {}
local L_SUPER = 'lgui'
local R_SUPER = 'rgui'
local fontSize = 16
local lineHeight = fontSize * 1
local font = love.graphics.newFont(
  -- 'built/fonts/PolygonPixel5x7Cyrillic.ttf',
  'built/fonts/StarPerv.ttf',
  fontSize
)
love.graphics.setFont(font)

local function toggleCollisionDebug()
  config.collisionDebug = not config.collisionDebug
end

msgBus.subscribe(function(msgType, v)
  if ((msgBus.KEY_PRESSED == msgType) or (msgBus.KEY_RELEASED == msgType)) and
    not v.isRepeated
  then
    keysPressed[v.key] = msgBus.KEY_PRESSED == msgType
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

local function printTable(t, lineHeight, x, y)
  local i = 0
  for k,v in pairs(t) do
    love.graphics.print(
      k..': '..v,
      x,
      y + (i * lineHeight)
    )
    i = i + 1
  end
end

local function getAllGameObjectStats()
  local stats = {
    count = 0
  }
  for _,group in pairs(groups) do
    stats.count = stats.count + group.getStats()
  end
  return stats
end

local canvas = love.graphics.newCanvas()

function Console.draw()
  local gfx = love.graphics

  gfx.push()
  gfx.setCanvas(canvas)
  gfx.clear(0,0,0,0)
  gfx.setColor(Color.MED_GRAY)
  gfx.print('COMPONENTS', edgeOffset, edgeOffset)
  gfx.setColor(Color.WHITE)
  gfx.print(
    'objects: '..getAllGameObjectStats().count,
    edgeOffset,
    edgeOffset + lineHeight
  )

  local startY = edgeOffset + (lineHeight * 3)
  gfx.setColor(Color.MED_GRAY)
  gfx.print('GRAPHICS', edgeOffset, startY)
  gfx.setColor(Color.WHITE)
  -- print out each stat on its own line
  printTable(
    gfx.getStats(),
    lineHeight,
    edgeOffset,
    startY + lineHeight
  )
  gfx.setBlendMode('alpha', 'premultiplied')
  gfx.setCanvas()
  gfx.draw(canvas)
  gfx.pop()
  gfx.setBlendMode('alpha')
end

return groups.gui.createFactory(Console)
