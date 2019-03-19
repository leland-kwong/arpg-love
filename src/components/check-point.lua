local Component = require 'modules.component'
local Portal = LiveReload 'components.portal'
local msgBus = require 'components.msg-bus'
local globalState = require 'main.global-state'
local EventLog = require 'modules.log-db.events-log'
local BigNotifier = require 'components.hud.big-notifier'
local collisionWorlds = require 'components.collision-worlds'
local collisionGroups = require 'modules.collision-groups'

local function checkIfPortalUnlocked(checkPointId)
  local log = EventLog.read(globalState.gameState:getId())
  return log.checkPointsUnlocked[checkPointId]
end

return Component.createFactory({
  checkPointId = '',
  init = function(self)
    local checkPointId = self.checkPointId
    local isPortalUnlocked = checkIfPortalUnlocked(checkPointId)
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
        x = self.x,
        y = self.y,
        w = 100,
        h = 100,
        group = 'all',
        init = function(self)
          self.collision = self:addCollisionObject('hotSpot', self.x, self.y, self.w, self.h, self.w/2, self.h/2)
            :addToWorld(collisionWorlds.map)
        end,
        update = function(self)
          local _,_,cols,len = self.collision:check(self.x, self.y, function(item, other)
            if collisionGroups.matches(other.group, 'player') then
              return 'touch'
            end
            return false
          end)
          local collidingWithPlayer = len > 0
          if collidingWithPlayer and (not checkIfPortalUnlocked(checkPointId)) then
            local Sound = require 'components.sound'
            Sound.playEffect('gui/big-notification-appear.wav')

            msgBus.send('CHECKPOINT_UNLOCKED', checkPointId)
            local bnTheme = BigNotifier.themes.checkPointUnlocked
            BigNotifier.create({
              w = 360,
              h = 50,
              duration = 0.5,
              text = {
                title = {
                  bnTheme.title, 'Checkpoint ',

                  {1,1,1}, checkPointId,

                  bnTheme.title, ' unlocked'
                },
                body = {bnTheme.body, 'Location now available in map'}
              }
            })
            Component.animate(portalRef, {
              color = {1,1,1,1},
              scale = 1
            }, 1, 'outCubic')
          end
        end,
      }):setParent(portalRef)
    end
  end
})