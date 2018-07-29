local messageBus = require 'utils.message-bus'

local M = {}
M.input = messageBus.new()
M.input.KEY_PRESSED = 'KEY_PRESSED'
M.input.KEY_RELEASED = 'KEY_RELEASED'

return M