local randomItem = require 'components.loot-generator.algorithm-1'
local itemDefinition = require 'components.item-inventory.items.item-definitions'

local items = randomItem(1, 10 * 100, 0, 2)
for i=1, #items do
  print(
    require 'utils.inspect'(
      items[i]
    )
  )
end