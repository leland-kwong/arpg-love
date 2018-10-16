local socket = require 'socket'
local msgBus = require 'components.msg-bus'
local config = require 'config.config'
require 'main.inputs.keyboard-manager'

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
  local message = { x, y, button, isTouch, presses }
  msgBus.send(
    msgBus.MOUSE_RELEASED,
    message
  )

  local timeBetweenRelease = socket.gettime() - state.mouse.lastPressed.timeStamp
  if timeBetweenRelease <= config.userSettings.mouseClickDelay then
    msgBus.send(msgBus.MOUSE_CLICKED, message)
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
