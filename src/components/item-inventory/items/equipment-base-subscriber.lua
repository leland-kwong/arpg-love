local itemDefs = require 'components.item-inventory.items.item-definitions'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'

return function(item)
  local self = item
  local upgrades = itemDefs.getDefinition(item).upgrades

  local function getHighestUpgradeUnlocked()
    local highestUpgradeUnlocked = 0
    for i=1, #upgrades do
      local up = upgrades[i]
      if self.experience >= up.experienceRequired then
        highestUpgradeUnlocked = i
      end
    end
    return highestUpgradeUnlocked
  end

  local lastUpgradeUnlocked = getHighestUpgradeUnlocked()

  local msgTypes = {
    [msgBus.EQUIPMENT_UNEQUIP] = function(v)
      if v == self then
        return msgBus.CLEANUP
      end
    end,
    [msgBus.ENEMY_DESTROYED] = function(v)
      self.experience = self.experience + v.experience
      local nextUpgradeLevel = getHighestUpgradeUnlocked()
      local newUpgradeUnlocked = nextUpgradeLevel > lastUpgradeUnlocked
      lastUpgradeUnlocked = nextUpgradeLevel
      if newUpgradeUnlocked then
        local itemTitle = itemDefs.getDefinition(self).title
        msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
          title = itemTitle..' upgraded',
          icon = itemDefs.getDefinition(self).sprite,
          description = {
            Color.CYAN, upgrades[nextUpgradeLevel].title,
            Color.WHITE, ' is unlocked'
          }
        })
      end
    end
  }

  msgBus.subscribe(function(msgType, msgValue)
    local handler = msgTypes[msgType]
    if handler then
      handler(msgValue)
    end
  end)
end