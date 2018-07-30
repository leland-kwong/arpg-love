local messageBus = require 'utils.message-bus'

local M = messageBus.new()
M.GAME_LOADED = 'GAME_LOADED'
M.KEY_PRESSED = 'KEY_PRESSED'
M.KEY_RELEASED = 'KEY_RELEASED'

return M