local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local Tooltip = require 'components.gui.tooltip'
local Color = require 'modules.color'
local font = require 'components.font'

local TooltipTest = {}

function TooltipTest.init()
  local rows = {
    Tooltip.Row({
      {
        content = {
          Color.DARK_GRAY,
          'Column 1'
        },
        maxWidth = 125,
        -- background = Color.WHITE,
        font = font.secondary.font,
        fontSize = font.secondary.fontSize,
        padding = 5,
      },
      {
        content = {
          Color.WHITE,
          'Column 2 lorem ipsum dolor sit amet consectetur'
        },
        maxWidth = 125,
        font = font.primary.font,
        fontSize = font.primary.fontSize,
        padding = 5,
        background = Color.PURPLE,
        -- border = {1,1,0,0.5},
        -- borderWidth = 4
      }
    }),
    Tooltip.Row({
      {
        content = {
          Color.DARK_GRAY,
          'Column 3'
        },
        maxWidth = 125,
        background = Color.WHITE,
        font = font.primary.font,
        fontSize = font.primary.fontSize,
        padding = 5,
      },
      {
        content = {
          Color.DARK_GRAY,
          'Column 4'
        },
        maxWidth = 125,
        font = font.secondary.font,
        fontSize = font.secondary.fontSize,
        padding = 5,
        background = Color.LIME
      }
    }),
  }
  Tooltip.create({
    x = 250,
    y = 20,
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