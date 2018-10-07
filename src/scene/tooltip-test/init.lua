local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local Block = require 'components.gui.block'
local Color = require 'modules.color'
local font = require 'components.font'

local TooltipTest = {}

function TooltipTest.init()
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, Color.LIGHT_GRAY)
  local blockPadding = 8

  local titleBlock = {
    content = {
      Color.YELLOW,
      'Fast Pod Initate of the Bear'
    },
    width = 125,
    -- background = Color.WHITE,
    font = font.secondary.font,
    fontSize = font.secondary.fontSize,
  }
  local levelBlock = {
    content = {
      Color.WHITE,
      'Level 1'
    },
    width = 125,
    align = 'right',
    font = font.primary.font,
    fontSize = font.primary.fontSize,
  }
  local itemTypeBlock = {
    content = {
      Color.YELLOW,
      'Rare Pod Module'
    },
    width = 125,
    font = font.primary.font,
    fontSize = font.primary.fontSize
  }
  local upgradeModifierBlock = {
    content = {
      Color.YELLOW,
      'Critical Strikes\n',

      Color.LIME,
      '20 experience to unlock\n',

      Color.OFF_WHITE,
      '\nAttacks have a ',

      Color.WHITE,
      '25% ',

      Color.OFF_WHITE,
      'chance to deal ',

      Color.WHITE,
      '1.2x - 1.4x ',

      Color.OFF_WHITE,
      'damage'
    },
    width = 250,
    font = font.primary.font,
    fontSize = font.primary.fontSize,
    background = {0.3, 0.3, 0.3},
    padding = blockPadding
  }
  local baseStatsBlock = {
    content = {
      Color.OFF_WHITE,
      '+',
      Color.WHITE,
      5,
      Color.OFF_WHITE,
      ' Lightning Damage',

      Color.OFF_WHITE,
      '\n+',
      Color.WHITE,
      tostring(12)..'%',
      Color.OFF_WHITE,
      ' Cooldown Reduction\n',
    },
    width = 250,
    font = font.primary.font,
    fontSize = font.primary.fontSize,
    background = {0.3, 0.3, 0.3},
    padding = blockPadding,
  }
  local rows = {
    Block.Row({
      titleBlock,
      levelBlock
    }),
    Block.Row({
      itemTypeBlock
    }, {
      marginTop = 8
    }),
    Block.Row({
      baseStatsBlock
    }, {
      marginTop = 8
    }),
    Block.Row({
      upgradeModifierBlock
    }, {
      marginTop = 1
    })
  }
  Block.create({
    x = 250,
    y = 20,
    background = {0.2,0.2,0.2},
    padding = blockPadding,
    rows = rows
  })
end

local Scene = Component.createFactory(TooltipTest)

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'tooltip test',
  value = function()
    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Scene
    })
  end
})