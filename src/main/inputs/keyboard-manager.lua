local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local socket = require 'socket'
local config = require 'config.config'

local state = {
  keyboard = {
    lastPressed = {
      timeStamp = 0
    },
    isDown = false,
  }
}

local keysPressed = {}
local L_SUPER = 'lgui'
local R_SUPER = 'rgui'
local L_CTRL = 'lctrl'
local R_CTRL = 'rctrl'

local function hasModifier()
  return keysPressed[L_SUPER]
    or keysPressed[R_SUPER]
    or keysPressed[L_CTRL]
    or keysPressed[R_CTRL]
end

local keyboardMessage = require 'utils.pooled-table'(function(t, key, scanCode, isRepeated)
  t.key = key
  t.code = scanCode
  t.isRepeated = isRepeated
  t.hasModifier = hasModifier()
  return t
end)

function love.keypressed(key, scanCode, isRepeated)
  keysPressed[key] = true

  msgBus.send(
    msgBus.KEY_DOWN,
    keyboardMessage(key, scanCode, isRepeated)
  )

  if (not state.keyboard.isDown) then
    local lastPressed = state.keyboard.lastPressed
    lastPressed.timeStamp = socket.gettime()
  end

  if config.userSettings.keyboard.MAIN_MENU == key then
    msgBusMainMenu.send(
      msgBusMainMenu.TOGGLE_MAIN_MENU
    )
  end
end

function love.keyreleased(key, scanCode)
  keysPressed[key] = false

  local msg = keyboardMessage(key, scanCode, false)
  msgBus.send(
    msgBus.KEY_RELEASED,
    msg
  )

  local timeBetweenRelease = socket.gettime() - state.keyboard.lastPressed.timeStamp
  if timeBetweenRelease >= config.userSettings.keyPressedDelay then
    msgBus.send(msgBus.KEY_PRESSED, msg)
  end
end