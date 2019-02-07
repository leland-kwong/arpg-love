local Component = require 'modules.component'
local Portal = LiveReload 'components.portal'
local msgBus = require 'components.msg-bus'
local globalState = require 'main.global-state'
local EventLog = require 'modules.log-db.events-log'

return Component.createFactory({
  checkPointId = '',
  init = function(self)
    local checkPointId = self.checkPointId
    local log = EventLog.read(globalState.gameState:getId())
    local isPortalUnlocked = log.checkPointsUnlocked[checkPointId]
    local portalRef = Portal.create({
      scale = isPortalUnlocked and 1 or 0.5,
      style = 2,
      color = isPortalUnlocked and {1,1,1} or {1,1,1,0.7},
      x = self.x,
      y = self.y,
      location = self.location
    }):setParent(self)

    if (not isPortalUnlocked) then
      Component.create({
        group = 'all',
        update = function(self)
          if portalRef.collidingWithPlayer then
            msgBus.send('CHECKPOINT_UNLOCKED', checkPointId)
            self.tween = self.tween or Component.animate(portalRef, {
              color = {1,1,1,1},
              scale = 1
            }, 1, 'outCubic')
          end
        end,
      }):setParent(portalRef)
    end
  end
})