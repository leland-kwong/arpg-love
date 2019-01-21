local dynamicRequire = require 'utils.dynamic-require'
local questDefinitions = dynamicRequire('components.quest-log.quest-definitions')

return {
  quests = questDefinitions,
  completedTasks = {
    ['the-beginning_1'] = true,
    ['boss-1_1'] = true
  }
}