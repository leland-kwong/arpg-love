local Stateful = require 'utils.stateful'
local O = require 'utils.object-utils'

return function()
  return Stateful:new({
    pickedUpItem = nil
  })
end