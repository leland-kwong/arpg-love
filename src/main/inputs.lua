local socket = require 'socket'
local msgBus = require 'components.msg-bus'
local config = require 'config.config'
local msgBusMainMenu = require 'components.msg-bus-main-menu'

msgBus.MOUSE_CLICKED = 'MOUSE_CLICKED'

local state = {
  mouse = {
    lastPressed = {
      timeStamp = 0,
      x = 0,
      y = 0
    },
    isDown = false,
  }
}

msgBus.on(msgBus.UPDATE, function()
  state.mouse.isDown = love.mouse.isDown()
end)

local inputMsg = require 'utils.pooled-table'(function(t, key, scanCode, isRepeated)
  t.key = key
  t.code = scanCode
  t.isRepeated = isRepeated
  return t
end)

function love.keypressed(key, scanCode, isRepeated)
  msgBus.send(
    msgBus.KEY_PRESSED,
    inputMsg(key, scanCode, isRepeated)
  )

  if config.userSettings.keyboard.MAIN_MENU == key then
    msgBusMainMenu.send(
      msgBusMainMenu.TOGGLE_MAIN_MENU
    )
  end
end

function love.keyreleased(key, scanCode)
  msgBus.send(
    msgBus.KEY_RELEASED,
    inputMsg(key, scanCode, false)
  )
end

function love.mousepressed( x, y, button, istouch, presses )
  msgBus.send(
    msgBus.MOUSE_PRESSED,
    { x, y, button, istouch, presses }
  )
  if (not state.mouse.isDown) then
    local lastPressed = state.mouse.lastPressed
    lastPressed.timeStamp = socket.gettime()
    lastPressed.x, lastPressed.y = x, y
  end
end

function love.mousereleased( x, y, button, istouch, presses )
  msgBus.send(
    msgBus.MOUSE_RELEASED,
    { x, y, button, isTouch, presses }
  )

  local timeBetweenRelease = socket.gettime() - state.mouse.lastPressed.timeStamp
  if timeBetweenRelease <= config.userSettings.mouseClickDelay then
    msgBus.send(msgBus.MOUSE_CLICKED, state.mouse.lastPressed)
  end
end

function love.wheelmoved(x, y)
  msgBus.send(msgBus.MOUSE_WHEEL_MOVED, {x, y})
end

function love.textinput(t)
  msgBus.send(
    msgBus.GUI_TEXT_INPUT,
    t
  )
end
