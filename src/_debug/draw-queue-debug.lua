local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'

for groupName,group in pairs(groups) do
  group.drawQueue:onBeforeFlush(function(self)
    local minOrder, maxOrder = self:getStats()
    local maxDivergence = 500
    local divergence = maxOrder - minOrder
    local isDivergingTooMuch = divergence > maxDivergence
    if isDivergingTooMuch then
      local Color = require 'modules.color'
      msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
        title = '['..groupName..'] WARNING: draw queue divergence',
        description = {
          Color.WHITE, 'draw order gap of ',
          Color.CYAN, divergence,
          Color.WHITE, ' exceeded threshold of ',
          Color.RED, maxDivergence,
          Color.WHITE, '.\nA high draw order gap can cause performance issues because the draw queue will have to iterate over a large list. Additionally, a big gap will require the draw queue to skip positions, causing unecessary cpu strain.'
        }
      })
    end
  end)
end