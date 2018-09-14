local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'

groups.all.drawQueue:onBeforeFlush(function(self)
  local minOrder, maxOrder = self:getStats()
  local maxDivergence = 300
  local divergence = maxOrder - minOrder
  local isDivergingTooMuch = divergence > maxDivergence
  if isDivergingTooMuch then
    local Color = require 'modules.color'
    msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
      title = 'draw queue divergence',
      description = {
        Color.WHITE, 'draw order gap of ',
        Color.CYAN, divergence,
        Color.WHITE, ' exceeded threshold of ',
        Color.RED, maxDivergence
      }
    })
  end
end)