local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'

local emptyTable = {}
for groupName,group in pairs(groups) do
  local function drawQueueWarningCheck(self)
    local maxOrdersCount = 200
    local ordersCount = #(self.orders or emptyTable)
    local isTooManyPriorities = ordersCount > maxOrdersCount
    if isTooManyPriorities then
      local Color = require 'modules.color'
      msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
        title = '['..groupName..'] WARNING: excessive draw orders',
        description = {
          Color.WHITE, 'number of draw orders ',
          Color.CYAN, ordersCount,
          Color.WHITE, ' exceeded threshold of ',
          Color.RED, maxOrdersCount,
          Color.WHITE, '.\nA high number of draw orders can cause performance issues because the draw queue will have to iterate over a large list.'
        }
      })
    end
  end
  group.drawQueue:onBeforeFlush(drawQueueWarningCheck)
end