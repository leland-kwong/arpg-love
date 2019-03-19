local Log = require 'modules.log-db'
local msgBus = require 'components.msg-bus'
local Component = require 'modules.component'

Component.create({
  id = 'ErrorLog',
  init = function(self)
    self.logTailCleanup = Log.tail('error.log', function(event)
      print(
        '[ERROR]\n',
        Inspect(event)
      )
    end)

    self.listeners = {
      msgBus.on('LOG_ERROR', function(msg)
        Log.append('error.log', {
          timestamp = os.date(),
          message = msg
        })
      end)
    }
  end,
  final = function(self)
    self.logTailCleanup()
    msgBus.off(self.listeners)
  end
})