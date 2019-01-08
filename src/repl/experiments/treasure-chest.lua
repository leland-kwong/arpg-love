local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local TreasureChest = dynamicRequire 'components.treasure-chest'
local msgBus = require 'components.msg-bus'
local itemConfig = require(require('alias').path.items..'.config')

Component.create({
  id = 'TreasureChestTest',
  init = function(self)
    Component.addToGroup(self, 'all')

    if Component.get('MAIN_SCENE') then
      local ok, res = pcall(function()
        local itemSystem = require 'components.item-inventory.items.item-system'
        Component.addToGroup(os.clock(), 'loot', {
          itemData = {
            level = 1,
            dropRate = 200,
            minRarity = itemConfig.rarity.NORMAL,
            maxRarity = itemConfig.rarity.LEGENDARY,
          },
          guaranteedItems = {
            itemSystem.create('base.action-module-initiate')
          }
        })
      end)

      if (not ok) then
        print('[error]', res)
      else
        print(
          'response',
          Inspect(
            res
          )
        )
      end
      -- local x, y = Component.get('PLAYER'):getPosition()
      -- TreasureChest.create({
      --   x = x,
      --   y = y,
      --   guaranteedItems = {
      --     itemSystem.create('base.action-module-initiate')
      --   }
      -- })
    end
  end,
  final = function(self)
  end
})