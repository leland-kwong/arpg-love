local itemDefs = require("components.item-inventory.items.item-definitions")
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'

return itemDefs.registerModule({
  name = 'equip-on-click',
  type = itemDefs.moduleTypes.INVENTORY_ACTIVE,
  active = function(item)
    msgBus.send(msgBus.EQUIPMENT_SWAP, item)
  end,
  tooltip = function(item)
    return {Color.LIGHT_GRAY, 'right-click to equip'}
  end
})