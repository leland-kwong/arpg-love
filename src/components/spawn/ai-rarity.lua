local function setupRarityTypes(types)
  local list = {}
  for i=1, #types do
    local t = types[i]
    for j=1, t.chance do
      table.insert(list, t)
    end
  end
  return list
end

local function CallableObject(props)
  return setmetatable(props, {
    __call = props.__call
  })
end

local rarityTypes = setupRarityTypes({
  CallableObject({
    type = 'NORMAL',
    chance = 3,
    __call = function(self, ai)
      return ai
    end
  }),
  CallableObject({
    type = 'MAGICAL',
    chance = 3,
    outlineColor = {0.5, 0.5, 1, 1},
    __call = function(self, ai)
      return ai:set('outlineColor', self.outlineColor)
        :set('maxHealth', ai.maxHealth * 2)
    end
  }),
  CallableObject({
    type = 'RARE',
    chance = 3,
    outlineColor = {0.8, 0.8, 0, 1},
    __call = function(self, ai)
      return ai:set('outlineColor', self.outlineColor)
        :set('maxHealth', ai.maxHealth * 5)
    end
  }),
})

return function(ai)
  local rarityTypeIndex = math.random(1, #rarityTypes)
  return rarityTypes[rarityTypeIndex](ai)
end