local itemSystem = require 'components.item-inventory.items.item-system'

return {
  guaranteedItems = {
    itemSystem.create('base.augmentation-module-one'),
    itemSystem.create('base.mock-shoes')
  }
}