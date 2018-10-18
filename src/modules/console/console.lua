local GuiText = require 'components.gui.gui-text'
local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local CollisionObject = require 'modules.collision'
local config = require 'config.config'
local InputContext = require 'modules.input-context'

local state = {
  showConsole = true
}

local font = love.graphics.newFont(
  'built/fonts/StarPerv.ttf',
  16
)
font:setLineHeight(1)

local guiText = GuiText.create({
  font = font,
  group = groups.system,
  outline = false
})

local function toggleCollisionDebug()
  msgBus.send(msgBus.SET_CONFIG, {
    collisionDebug = (not config.collisionDebug)
  })
end

local function toggleConsole()
  msgBus.send(msgBus.SET_CONFIG, {
    enableConsole = (not config.enableConsole)
  })
end

local function togglePerformanceProfiler()
  local enabled = not config.performanceProfile

  if (not enabled) then
    local profile = require 'modules.profile'
    profile.write('prof.mpack')
  end

  msgBus.send(msgBus.SET_CONFIG, {
    performanceProfile = enabled
  })
end

local keyActions = setmetatable({
  o = toggleCollisionDebug,
  p = togglePerformanceProfiler,
  c = toggleConsole,
}, {
  __index = function()
    local noop = require 'utils.noop'
    return noop
  end
})

msgBus.on(msgBus.KEY_DOWN, function(v)
  if v.hasModifier and (not v.isRepeated) then
    keyActions[v.key]()
  end
  return v
end)

msgBus.IS_CONSOLE_ENABLED = 'IS_CONSOLE_ENABLED'
msgBus.on(msgBus.IS_CONSOLE_ENABLED, function()
  return config.enableConsole
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
  Component.addToGroup(self, groups.system)
  local perf = require 'utils.perf'
  msgBus.send = perf({
    done = function(_, totalTime, callCount)
      self.msgBusAverageTime = totalTime/callCount
    end
  })(msgBus.send)
end

function Console.update(self)
  local noop = require 'utils.noop'
  -- set logger function to noop if console is disabled
  consoleLog = config.enableConsole and Console.debug or noop
  self:setDrawDisabled(not config.enableConsole)
  if (not config.enableConsole) then
    return
  end

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
  love.graphics.setFont(font)
  local charHeight = font:getLineHeight() * font:getHeight()
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
    charHeight,
    edgeOffset,
    edgeOffset + charHeight
  )

  local startY = edgeOffset + (charHeight * 4)
  gfx.setColor(Color.MED_GRAY)
  gfx.print('GRAPHICS', edgeOffset, startY)
  gfx.setColor(Color.WHITE)
  -- print out each stat on its own line
  printTable(
    gfx.getStats(),
    charHeight,
    edgeOffset,
    startY + charHeight
  )

  gfx.setColor(Color.MED_GRAY)
  gfx.print('SYSTEM', edgeOffset, startY + 11 * charHeight)
  gfx.setColor(Color.WHITE)
  printTable({
      memory = string.format('%0.2f', s.currentMemoryUsed / 1024),
      memoryAvg = string.format('%0.2f', s.accumulatedMemoryUsed / s.frameCount / 1024),
      delta = love.timer.getAverageDelta(),
      fps = love.timer.getFPS(),
      eventHandlers = calcMessageBusHandlers()
    },
    charHeight,
    edgeOffset,
    startY + 12 * charHeight
  )

  gfx.printf(
    {
      Color.WHITE,
      'msgBus '..string.format('%0.3f', self.msgBusAverageTime),
      Color.WHITE,
      '\ninput context: ',
      Color.YELLOW,
      InputContext.get()
    },
    edgeOffset,
    700,
    400,
    'left'
  )

  local logEntries = logger:get()
  gfx.setColor(Color.MED_GRAY)
  local loggerYPosition = 750
  local logSectionTitle = 'LOG'
  gfx.print(logSectionTitle, edgeOffset, loggerYPosition)
  gfx.setColor(Color.WHITE)
  local output = {}
  for i=1, #logEntries do
    local entry = logEntries[i]
    table.insert(output, Color.WHITE)
    table.insert(output, entry..'\n')
  end
  guiText:addf(output, 400, 'left', edgeOffset, loggerYPosition + guiText.getTextSize(logSectionTitle, guiText.font))

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
