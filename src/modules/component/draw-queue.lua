local Q = require 'modules.queue'
local config = require 'config.config'

return function(M, groupDefinition)
  local logger = require 'utils.logger'
  local queueStats = {
    history = logger:new(30),
    maxLength = 0,
    totalLengths = 0,
    avgLength = 0
  }

  return Q:new({
    development = config.debugDrawQueue,
    context = groupDefinition.name,
    beforeFlush = function(self)
      local enabled = M.debug.drawQueueStats
      if (not enabled) then
        return
      end

      queueStats.totalLengths = queueStats.totalLengths + self.length
      queueStats.avgLength = queueStats.totalLengths/math.max(1, queueStats.history.entryCount)
      queueStats.maxLength = math.max(queueStats.maxLength, self.length)
      local hasChange = self.length ~= queueStats.avgLength
      if hasChange then
        queueStats.history:add(self.length)
      end
      M.addToGroup(self.context, 'drawQueueStats', queueStats)
    end
  })
end