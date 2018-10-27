local socket = require 'socket'

local function Time()
  return socket.gettime() * 1000
end

return Time