local GuiText = require 'components.gui.gui-text'
local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local font = require 'components.font'
local Color = require 'modules.color'
local CollisionObject = require 'modules.collision'
local config = require 'config'

local modifier = false
local keysPressed = {}
local L_SUPER = 'lgui'
local R_SUPER = 'rgui'
local L_CTRL = 'lctrl'
local R_CTRL = 'rctrl'

local state = {
  showConsole = true
}

local function hasModifier()
  return keysPressed[L_SUPER]
    or keysPressed[R_SUPER]
    or keysPressed[L_CTRL]
    or keysPressed[R_CTRL]
end

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
  if (msgBus.KEY_PRESSED == msgType) and hasModifier()
    and keysPressed.p
    and not v.isRepeated
  then
    toggleCollisionDebug()
  end

  -- toggle console
  if (msgBus.KEY_PRESSED == msgType) and hasModifier()
    and keysPressed.c
    and not v.isRepeated
  then
    state.showConsole = not state.showConsole
  end
end)

local Console = {
  name = 'Console',
  group = groups.system,
  stats = {
    accumulatedMemoryUsed = 0,
    currentMemoryUsed = 0,
    frameCount = 0
  }
}

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

function Console.update(self)
  local s = self.stats
  s.currentMemoryUsed = collectgarbage('count')
  s.frameCount = s.frameCount + 1
  s.accumulatedMemoryUsed = s.accumulatedMemoryUsed + s.currentMemoryUsed
end

function Console.draw(self)
  if not state.showConsole then
    return
  end
  local lineHeight = font.primaryLarge.lineHeight
  love.graphics.setFont(font.primaryLarge.font)
  local gfx = love.graphics
  local s = self.stats

  gfx.push()
  gfx.setCanvas(canvas)
  gfx.clear(0,0,0,0)

  gfx.setColor(Color.MED_GRAY)
  gfx.print('COMPONENTS', edgeOffset, edgeOffset)
  gfx.setColor(Color.WHITE)
  printTable({
    objects = getAllGameObjectStats().count,
    collisionObjects = CollisionObject.getStats()
  },
    lineHeight,
    edgeOffset,
    edgeOffset + lineHeight
  )

  local startY = edgeOffset + (lineHeight * 4)
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

  gfx.setColor(Color.MED_GRAY)
  gfx.print('SYSTEM', edgeOffset, startY + 11 * lineHeight)
  gfx.setColor(Color.WHITE)
  printTable({
      memory = string.format('%0.2f', s.currentMemoryUsed / 1024),
      memoryAvg = string.format('%0.2f', s.accumulatedMemoryUsed / s.frameCount / 1024),
      delta = love.timer.getAverageDelta(),
      fps = love.timer.getFPS(),
      eventHandlers = #select(2, msgBus.getStats())
    },
    lineHeight,
    edgeOffset,
    startY + 12 * lineHeight
  )

  gfx.setCanvas()
  gfx.setBlendMode('alpha', 'premultiplied')
  gfx.draw(canvas)
  gfx.pop()
  gfx.setBlendMode('alpha')
end

function Console.drawOrder(self)
  return 10
end

return Component.createFactory(Console)
