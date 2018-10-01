local itemSystem =require("components.item-inventory.items.item-system")
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'

return itemSystem.registerModule({
  name = 'equip-on-click',
  type = itemSystem.moduleTypes.INVENTORY_ACTIVE,
  active = function(item)
    msgBus.send(msgBus.EQUIPMENT_SWAP, item)
  end,
  tooltip = function(item)
    return {Color.LIGHT_GRAY, 'right-click to equip'}
  end
})