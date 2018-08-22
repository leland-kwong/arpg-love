local itemsPath = 'components.item-inventory.items.definitions.'
local lootPool = {
  require(itemsPath..'poison-blade'),
  require(itemsPath..'mock-shoes'),
  require(itemsPath..'gpow-armor'),
  require(itemsPath..'potion-health'),
  require(itemsPath..'potion-health')
}

return function()
  local item = lootPool[math.random(1, #lootPool)]
  return item.create()
end