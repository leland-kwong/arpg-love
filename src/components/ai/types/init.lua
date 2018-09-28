local aiTypesPath = 'components.ai.types.'
local Enum = require 'utils.enum'

local aiType = Enum({
  'SLIME',
  'MINI_BOT',
  'EYEBALL'
})

local aiTypeDef = {
  [aiType.SLIME] =      require(aiTypesPath..'ai-slime'),
  [aiType.MINI_BOT] =   require(aiTypesPath..'ai-mini-bot'),
  [aiType.EYEBALL] =    require(aiTypesPath..'ai-eyeball')
}

return {
  types = aiType,
  typeDefs = aiTypeDef
}