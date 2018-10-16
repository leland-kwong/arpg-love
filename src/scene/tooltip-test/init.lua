local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local Block = require 'components.gui.block'
local Color = require 'modules.color'
local font = require 'components.font'
local modParser = require 'modules.loot.item-modifier-template-parser'

local TooltipTest = {}

function TooltipTest.init(self)
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, Color.LIGHT_GRAY)
  local blockPadding = 8
  local tooltipWidth = 250

  local titleBlock = {
    content = {
      Color.RARITY_MAGICAL,
      'Fast Pod Initate of the Bear'
    },
    width = tooltipWidth * 5/8,
    -- background = Color.WHITE,
    font = font.secondary.font,
    fontSize = font.secondary.fontSize,
  }
  local levelRequiredBlock = {
    content = {
      Color.WHITE,
      'Level 1'
    },
    width = tooltipWidth * 3/8,
    align = 'right',
    font = font.primary.font,
    fontSize = font.primary.fontSize,
  }
  local itemTypeBlock = {
    content = {
      Color.RARITY_MAGICAL,
      'Pod Module'
    },
    width = tooltipWidth / 2,
    font = font.primary.font,
    fontSize = font.primary.fontSize
  }
  local upgradeModifierBlock = {
    content = modParser({
      type = 'upgrade',
      data = {
        title = 'Critical Strikes',
        experienceRequired = 20,
        description = {
          template = 'Gain {speedBoost} extra move speed for {speedBoostDuration} seconds.',
          data = {
            speedBoost = 300,
            speedBoostDuration = 1
          }
        }
      }
    }),
    width = tooltipWidth,
    font = font.primary.font,
    fontSize = font.primary.fontSize,
    background = {0.3, 0.3, 0.3},
    padding = blockPadding
  }
  local baseStatsBlock = {
    content = modParser({
      type = 'statsList',
      data = {
        lightningDamage = 2,
        cooldownReduction = 5,
      }
    }),
    width = tooltipWidth,
    font = font.primary.font,
    fontSize = font.primary.fontSize,
    background = {0.3, 0.3, 0.3},
    padding = blockPadding,
  }
  local baseStatsBlock2 = {
    content = modParser({
      type = 'statsList',
      data = {
        lightningDamage = 2,
        cooldownReduction = 5,
      }
    }),
    width = tooltipWidth,
    font = font.primary.font,
    fontSize = font.primary.fontSize,
    background = {0.3, 0.3, 0.3},
    padding = blockPadding,
  }
  local rows = {
    Block.Row({
      titleBlock,
      levelRequiredBlock
    }, {
      marginBottom = 8
    }),
    Block.Row({
      itemTypeBlock
    }, {
      marginBottom = 8
    }),
    Block.Row({
      baseStatsBlock
    }, {
      marginTop = 1
    }),
    Block.Row({
      upgradeModifierBlock
    }, {
      marginTop = 1
    }),
    Block.Row({
      baseStatsBlock2
    }, {
      marginTop = 1
    }),
  }
  Block.create({
    x = tooltipWidth,
    y = 20,
    background = {0.2,0.2,0.2},
    padding = blockPadding,
    rows = rows
  }):setParent(self)
end

local Scene = Component.createFactory(TooltipTest)

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'tooltip test',
  value = function()
    msgBus.send(msgBus.SCENE_STACK_REPLACE, {
      scene = Scene
    })
  end
})