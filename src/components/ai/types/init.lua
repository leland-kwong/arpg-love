local aiTypesPath = 'components.ai.types.'
local Enum = require 'utils.enum'

local aiType = Enum({
  'SLIME',
  'MINI_BOT',
  'EYEBALL',
  'MELEE_BOT'
})

local aiTypeDef = {
  [aiType.SLIME] =      require(aiTypesPath..'ai-slime'),
  [aiType.MINI_BOT] =   require(aiTypesPath..'ai-mini-bot'),
  [aiType.EYEBALL] =    require(aiTypesPath..'ai-eyeball'),
  [aiType.MELEE_BOT] =    require(aiTypesPath..'ai-melee-bot')
}

return {
  types = aiType,
  typeDefs = aiTypeDef
}