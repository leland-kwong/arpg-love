local socket = require 'socket'

function Time()
  return socket.gettime() * 1000
end

return Time