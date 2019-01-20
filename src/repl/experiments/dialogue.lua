-- local dynamicRequire = require 'utils.dynamic-require'
-- local scriptRoutines = dynamicRequire 'components.quest-log.script-routines'
-- local Component = require 'modules.component'
-- local msgBus = require 'components.msg-bus'
-- local EventLog = dynamicRequire 'modules.log-db.events-log'
-- local questHandlers = dynamicRequire 'components.quest-log.quest-handlers'
-- dynamicRequire 'components.quest-log.script-routines'
-- local gameId = 'game-562'

-- EventLog.start(gameId)
-- questHandlers.start(gameId)

-- local questId = 'the-beginning'

-- Component.create({
--   id = 'dialogeTest',
--   group = 'firstLayer',
--   previousScript = nil,
--   init = function(self)
--     local Log = require 'modules.log-db'
--     local Db = require 'modules.database'
--     self.logTailStop = Log.tail(gameId, function(entry)
--       -- print(
--       --   Inspect(entry)
--       -- )
--       -- print(
--       --   Inspect(
--       --     Db.load('saved-states'):get(gameId..'/event-log')
--       --   )
--       -- )
--     end)

--     self.listeners = {
--       msgBus.on('KEY_PRESSED', function(msg)
--         local hotKeys = {
--           RESET = 'r',
--           RUN = 'return'
--         }

--         if hotKeys.RESET == msg.key then
--           msgBus.send('QUEST_REMOVE', {
--             id = questId
--           })

--           Component.addToGroup(
--             Component.newId(),
--             'scriptActions',
--             {
--               action = 'NEXT_SCRIPT',
--               payload = {
--                 npcName = 'lisa',
--                 scriptId = questId
--               }
--             }
--           )
--         end

--         if hotKeys.RUN == msg.key then
--           msgBus.send('QUEST_REMOVE', {
--             id = questId
--           })

--           msgBus.send('QUEST_ADD', {
--             id = questId
--           })

--           msgBus.send('QUEST_TASK_COMPLETE', {
--             questId = questId,
--             taskId = 'the-beginning_1'
--           })
--         end
--       end)
--     }
--   end,
--   update = function(self)
--     local nextScript = scriptRoutines.nextScript('lisa')
--     local isNewScript = self.previousScript ~= nextScript
--     if isNewScript then
--       self.previousScript = nextScript
--       print(
--         Inspect(nextScript)
--       )
--     end
--   end,
--   final = function(self)
--     self.logTailStop()
--     msgBus.off(self.listeners)
--   end
-- })