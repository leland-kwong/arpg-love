local callableObject = require 'utils.callable-object'

local Chance = {}

local random = math.random

function Chance.roll(percentChance)
  return random(1, 1 / percentChance) == 1
end

local defaultSeed = os.time()
local getDefaultSeed = function()
  defaultSeed = defaultSeed + 1
  return defaultSeed
end

local function setupChanceFunctions(_, types, seed)
  math.randomseed(seed or getDefaultSeed())
  local list = {}
  for i=1, #types do
    local props = types[i]
    assert(type(props.chance) == 'number', 'chance must be a number')
    local t = callableObject(props)
    for j=1, t.chance do
      table.insert(list, t)
    end
  end
  return function(a)
    local index = math.random(1, #list)
    return list[index](a)
  end
end

return setmetatable(Chance, {
  __call = setupChanceFunctions
})