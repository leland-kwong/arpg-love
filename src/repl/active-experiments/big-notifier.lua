local function resetCheckPointLogState()
  local msgBus = require 'components.msg-bus'
  msgBus.send('EVENT_LOG_UPDATE', {
    checkPointsUnlocked = {
      ['1-1'] = true
    }
  })

  local EventLog = require 'modules.log-db.events-log'
  local globalState = require 'main.global-state'
  print(
    Inspect(
      EventLog.read(globalState.gameState:getId())
    )
  )
end

local function testCheckpointNotification()
  local checkPointId = 'Aureus 2'
  local BigNotifier = LiveReload 'components.hud.big-notifier'
  local bnTheme = BigNotifier.themes.checkPointUnlocked
  BigNotifier.create({
    w = 360,
    h = 50,
    duration = 0.3,
    text = {
      title = {
        bnTheme.title, 'Checkpoint ',

        {1,1,1}, checkPointId,

        bnTheme.title, ' unlocked'
      },
      body = {bnTheme.body, 'Location now available in map'}
    }
  })
end

local function testLevelUpNotification()
  local Sound = require 'components.sound'
  Sound.playEffect('level-up.wav')

  local nextLevel = 58
  local BigNotifier = LiveReload 'components.hud.big-notifier'
  local bnTheme = BigNotifier.themes.levelUp
  BigNotifier.create({
    w = 300,
    h = 50,
    duration = 0.3,
    text = {
      title = {
        bnTheme.title, 'Level ',

        {1,1,1}, nextLevel,

        bnTheme.title, ' Reached!'
      },
      body = {bnTheme.body, 'You have gained a new level'}
    }
  })
end

-- local function readLog(gameId)
--   local handleError = function(err)
--     print('error', err)
--   end
--   local Log = LiveReload 'modules.log-db'
--   Log.readStream(gameId, function(_, entry)
--     print('entry', Inspect(entry))
--   end, handleError, function()
--     print('done')
--   end)
-- end

-- local globalState = require 'main.global-state'
-- local gameId = globalState.gameState:getId()
-- readLog(gameId)
-- print(gameId)

-- testCheckpointNotification()
-- testLevelUpNotification()
-- resetCheckPointLogState()

local Component = require 'modules.component'
local playerRef = Component.get('PLAYER')
if playerRef then

end