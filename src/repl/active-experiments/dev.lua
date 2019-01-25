local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local msgBus = require 'components.msg-bus'
local MenuManager = require 'modules.menu-manager'

-- require 'repl.components.break-screen'

-- require 'repl.components.components-system-queue-debug'


-- msgBus.send(msgBus.EXPERIENCE_GAIN, 10000)

local M = {
  id = 'dev-components'
}

local function closeMenu()
  Component.remove('DEV_MENU', true)
end

function M.init(self)
  local MenuList2 = require 'components.gui.menu-list-2'
  local Text = require 'components.gui.gui-text'
  local text = Text.create({
    font = require 'components.font'.primary.font
  }):setParent(self)

  local function MenuItem(props)
    return Gui.create({
      width = 100,
      label = props.label,
      onClick = props.onClick,
      onUpdate = function(self)
        self.height = select(2, Text.getTextSize(self.label, text.font))
      end,
      draw = function(self)
        text:add(self.label, {1,1,1}, self.x, self.y)

        if self.hovered then
          love.graphics.setColor(1,1,0,0.3)
          love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
        end
      end
    })
  end

  self.listeners = {
    msgBus.on('*', function(_, msgType)
      -- print(msgType)
    end),
    msgBus.on('KEY_PRESSED', function(ev)
      if ev.key == 'f1' then
        msgBus.send(msgBus.DEV_MENU_TOGGLE)
      end
    end),
    msgBus.on(msgBus.DEV_MENU_TOGGLE, function()
      if Component.get('DEV_MENU') then
        closeMenu()
        return
      end

      local layoutItems = {
        {
          MenuItem({
            label = 'spawn ai',
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
                      'ai-minibot'
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
          }),
        },
        {
         MenuItem({
            label = 'generate item',
            onClick = function()
              local itemSystem = require 'components.item-inventory.items.item-system'
              local playerRef = Component.get('PLAYER')
              Component.addToGroup(os.clock(), 'loot', {
                x = playerRef.x,
                y = playerRef.y,
                guaranteedItems = {
                  itemSystem.create('legendary.augmentation-module-frenzy')
                }
              })
            end,
          })
        },
        {
          MenuItem({
            label = 'Dummy object',
            onClick = function()
              closeMenu()
              local camera = require 'components.camera'
              local width, height = camera:getSize()

              local EnvironmentInteractable = require 'components.map.environment-interactable'
              local mx, my = camera:getMousePosition()
              local displayObject = EnvironmentInteractable.create({
                x = mx,
                y = my
              })

              -- cover full-screen to prevent click-through
              local clickOverlay = Gui.create({
                width = width,
                height = height,
                onUpdate = function(self)
                  local west, _, north = camera:getBounds()
                  self:setPosition(west, north)
                end,
                getMousePosition = function()
                  return camera:getMousePosition()
                end,
                onPointerMove = function(_, ev)
                  displayObject:setPosition(ev.x, ev.y)
                end,
                onClick = function(self, ev)
                  EnvironmentInteractable.create({
                    x = ev.x,
                    y = ev.y,
                    maxHealth = math.pow(100, 100)
                  })
                end,
                render = function()
                  love.graphics.setColor(1,1,1)
                  love.graphics.print('click to place dummy object', 100, 100)
                end,
                onFinal = function()
                  displayObject:delete(true)
                  MenuManager.pop()
                end
              })
              MenuManager.push(clickOverlay)
            end,
          })
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
      msgBus.send(msgBus.TOGGLE_MAIN_MENU, false)
      MenuManager.clearAll()
      MenuManager.push(devMenu)

      Component.addToGroup('DEV_MENU_BOX_DRAW', 'guiDrawBox', devMenu)
    end),
  }
end

function M.final(self)
  msgBus.off(self.listeners)
end

Component.create(M)