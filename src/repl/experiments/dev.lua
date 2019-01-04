local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local MenuManager = require 'modules.menu-manager'

-- msgBus.send(msgBus.EXPERIENCE_GAIN, 10000)

local M = {
  id = 'dev-components'
}

function M.init(self)
  self.listeners = {
    msgBus.on(msgBus.DEV_MENU_SHOW, function()
      local MenuList2 = require 'components.gui.menu-list-2'
      local Text = require 'components.gui.gui-text'
      local text = Text.create({
        font = require 'components.font'.primary.font
      })
      local function closeMenu()
        Component.remove('DEV_MENU', true)
      end
      local layoutItems = {
        {
          Gui.create({
            width = 100,
            height = 100,
            onClick = function()
              closeMenu()

              local config = require 'config.config'
              local camera = require 'components.camera'
              local width, height = camera:getSize()
              -- cover full-screen to prevent click-through
              local spawnOverlay = Gui.create({
                width = width,
                height = height,
                onClick = function(self)
                  local Spawn = require 'components.spawn.spawn-ai'
                  local aiTypes = require 'components.ai.types'
                  local mx, my = camera:getMousePosition()
                  Spawn({
                    x = mx/config.gridSize,
                    y = my/config.gridSize,
                    grid = Component.get('MAIN_SCENE').mapGrid,
                    target = function()
                      return Component.get('PLAYER')
                    end,
                    types = {
                      aiTypes.types.SLIME
                    }
                  })
                end,
                render = function()
                  love.graphics.setColor(1,1,1)
                  love.graphics.print('click to spawn ai', 100, 100)
                end,
                onFinal = function()
                  print('exit spawn mode')
                  MenuManager.pop()
                end
              })
              MenuManager.push(spawnOverlay)
            end,
            draw = function(self)
              text:add('spawn ai', {1,1,1}, self.x, self.y)
            end
          }),
          -- Gui.create({
          --   width = 100,
          --   height = 200,
          --   draw = function(self)
          --   end
          -- })
        }
      }
      local devMenu = MenuList2.create({
        id = 'DEV_MENU',
        x = 100,
        y = 100,
        height = 100,
        layoutItems = layoutItems,
        otherItems = {
          text
        },
        final = function()
          Component.remove('DEV_MENU_BOX_DRAW')
          MenuManager.pop()
        end,
        drawOrder = function()
          return 100000
        end
      })
      msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
      MenuManager.clearAll()
      MenuManager.push(devMenu)

      Component.addToGroup('DEV_MENU_BOX_DRAW', 'guiDrawBox', devMenu)
    end)
  }
end

function M.final(self)
  msgBus.off(self.listeners)
end

Component.create(M)