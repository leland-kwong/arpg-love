local dynamicRequire = require 'utils.dynamic-require'
local questDefinitions = dynamicRequire('components.quest-log.quest-definitions')

return {
  quests = questDefinitions,
  completedTasks = {
    ['quest_1_1'] = true,
    ['quest_2_1'] = true
  }
}