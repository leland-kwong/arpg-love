local Enum = require 'utils.enum'

local aiType = Enum({
  'SLIME',
  'MINI_BOT',
  'EYEBALL'
})

local aiTypeDef = {
  [aiType.SLIME] = require 'components.spawn.ai-slime',
  [aiType.MINI_BOT] = require 'components.spawn.ai-mini-bot',
  [aiType.EYEBALL] = require 'components.spawn.ai-eyeball'
}

return {
  types = aiType,
  typeDefs = aiTypeDef
}