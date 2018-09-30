local GuiText = require 'components.gui.gui-text'
local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local font = require 'components.font'
local Color = require 'modules.color'
local CollisionObject = require 'modules.collision'
local config = require 'config.config'

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

local guiText = GuiText.create({
  font = font.primaryLarge.font,
  group = groups.system,
  outline = false
})

local function toggleCollisionDebug()
  config.collisionDebug = not config.collisionDebug
end

msgBus.on(msgBus.KEY_PRESSED, function(v)
  keysPressed[v.key] = true

  if hasModifier() and not v.isRepeated then
    -- toggle collision debugger
    if keysPressed.p then
      toggleCollisionDebug()
    end

    if keysPressed.c then
      state.showConsole = not state.showConsole
    end
  end
  return v
end)

msgBus.IS_CONSOLE_ENABLED = 'IS_CONSOLE_ENABLED'
msgBus.on(msgBus.IS_CONSOLE_ENABLED, function()
  return state.showConsole
end)

msgBus.on(msgBus.KEY_RELEASED, function(v)
  keysPressed[v.key] = false
  return v
end)

local Console = {
  name = 'Console',
  stats = {
    accumulatedMemoryUsed = 0,
    currentMemoryUsed = 0,
    frameCount = 0,
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

local canvas = love.graphics.newCanvas(1000, 1000)

local Logger = require'utils.logger'
local logger = Logger:new(10)

function Console.debug(...)
  local args = {...}
  local output = ''
  for i=1, #args do
    output = output..' '..tostring(args[i])
  end
  logger:add(output)
end

-- GLOBAL console logger
consoleLog = Console.debug

function Console.init(self)
  self:addToGroup(groups.system)
  local perf = require 'utils.perf'
  msgBus.send = perf({
    done = function(_, totalTime, callCount)
      self.msgBusAverageTime = totalTime/callCount
    end
  })(msgBus.send)
end

function Console.update(self)
  local s = self.stats
  s.currentMemoryUsed = collectgarbage('count')
  s.frameCount = s.frameCount + 1
  s.accumulatedMemoryUsed = s.accumulatedMemoryUsed + s.currentMemoryUsed
end

local function calcMessageBusHandlers()
  local handlersByType = msgBus.getStats()
  local handlersByTypeCount = 0
  for _,handlers in pairs(handlersByType) do
    handlersByTypeCount = handlersByTypeCount + #handlers
  end
  return handlersByTypeCount
end

function Console.draw(self)
  if not state.showConsole then
    return
  end
  local primaryFont = font.primaryLarge
  local lineHeight = primaryFont.lineHeight * primaryFont.fontSize
  love.graphics.setFont(primaryFont.font)
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
      eventHandlers = calcMessageBusHandlers()
    },
    lineHeight,
    edgeOffset,
    startY + 12 * lineHeight
  )

  gfx.print('msgBus '..self.msgBusAverageTime, edgeOffset, 720)

  local logEntries = logger:get()
  gfx.setColor(Color.MED_GRAY)
  local loggerYPosition = 750
  gfx.print('LOG', edgeOffset, loggerYPosition)
  gfx.setColor(Color.WHITE)
  for i=1, #logEntries do
    local output = logEntries[i]
    guiText:add(output, Color.WHITE, edgeOffset, loggerYPosition + (lineHeight * i))
  end

  gfx.setCanvas()
  gfx.setBlendMode('alpha', 'premultiplied')
  gfx.scale(config.scale / 2)
  gfx.draw(canvas)
  gfx.pop()
  gfx.setBlendMode('alpha')
end

function Console.drawOrder(self)
  return 10
end

return Component.createFactory(Console)
