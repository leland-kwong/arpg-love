local itemDefs = require 'components.item-inventory.items.item-definitions'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'

local UpgradeManager = {}

local function triggerUpgradeMessage(item, level)
  msgBus.send(
    msgBus.ITEM_UPGRADE_UNLOCKED, {
      item = item,
      level = level
    }
  )
end

local function handleUpgrades(item)
  local self = item
  local upgrades = itemDefs.getDefinition(item).upgrades

  if (not upgrades) then
    return
  end

  local function getHighestUpgradeUnlocked()
    local highestUpgradeUnlocked = 0
    for level=1, #upgrades do
      local up = upgrades[level]
      if self.experience >= up.experienceRequired then
        highestUpgradeUnlocked = level
        triggerUpgradeMessage(item, level)
      end
    end

    return highestUpgradeUnlocked
  end

  local lastUpgradeUnlocked = getHighestUpgradeUnlocked()

  local listeners = {
    msgBus.on(msgBus.ENEMY_DESTROYED, function(v)
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
        triggerUpgradeMessage(item, nextUpgradeLevel)
      end
    end)
  }

  msgBus.on(msgBus.EQUIPMENT_UNEQUIP, function(v)
    if v == self then
      msgBus.off(listeners)
      return msgBus.CLEANUP
    end
  end)
end

msgBus.on(msgBus.ITEM_EQUIPPED, handleUpgrades)

msgBus.on(msgBus.ITEM_CHECK_UPGRADE_AVAILABILITY, function(v)
  local item, level = v.item, v.level
  local upgrades = itemDefs.getDefinition(item).upgrades
  return item.experience >= upgrades[level].experienceRequired
end)