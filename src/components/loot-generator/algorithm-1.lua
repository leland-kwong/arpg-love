local itemsPath = 'components.item-inventory.items.definitions.'
local lootPool = {
  require(itemsPath..'pod-module-fireball'),
  require(itemsPath..'mock-shoes'),
  require(itemsPath..'gpow-armor'),
  require(itemsPath..'potion-health'),
  require(itemsPath..'potion-energy'),
  require(itemsPath..'lightning-rod'),
  require(itemsPath..'pod-module-slow-time')
}

return function()
  local item = lootPool[math.random(1, #lootPool)]
  return item.create()
end