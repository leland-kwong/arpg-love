local messageBus = require 'utils.message-bus'

local M = messageBus.new()
M.GAME_LOADED = 'GAME_LOADED'
M.KEY_PRESSED = 'KEY_PRESSED'
M.KEY_RELEASED = 'KEY_RELEASED'
M.WINDOW_FOCUS = 'WINDOW_FOCUS'
M.NEW_FLOWFIELD = 'NEW_FLOWFIELD'

return M