local ItemGenerator = require 'components.loot-generator.algorithm-1'
local itemSystem = require 'components.item-inventory.items.item-system'
local f = require 'utils.functional'

local numItems = 1

local randomItem = ItemGenerator({
  'mock-shoes'
})

-- check magical modifiers
local item = randomItem(1, numItems * 100, 1, 1)[1]
local numModifiersMagical = 2
assert(
  #f.keys(item.extraModifiers[1].props) == numModifiersMagical,
  'magical items should have '..numModifiersMagical..' modifiers'
)

-- check rare modifiers
local item = randomItem(1, numItems * 100, 2, 2)[1]
local numModifiersRare = 4
assert(
  #f.keys(item.extraModifiers[1].props) == numModifiersRare,
  'rare items should have '..numModifiersRare..' modifiers'
)