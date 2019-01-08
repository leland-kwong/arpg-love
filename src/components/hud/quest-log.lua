local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local MenuList2 = require 'components.gui.menu-list-2'
local GuiText = require 'components.gui.gui-text'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local MenuManager = require 'modules.menu-manager'

local QuestLog = {
  width = 0,
  height = 0
}

function QuestLog.init(self)
  Component.addToGroup(self, 'gui')
  Component.addToGroup(self, 'gameWorld')

  msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  MenuManager.clearAll()
  MenuManager.push(self)

  local parent = self
  local bodyText = GuiText.create({
    font = require 'components.font'.primary.font
  }):setParent(self)
  self.bodyText = bodyText

  self.log = MenuList2.create({
    x = self.x,
    y = self.y,
    height = self.height,
    inputContext = 'any',
    layoutItems = {},
    otherItems = {
      bodyText
    },
    autoWidth = false,
    drawOrder = function()
      return 2
    end
  }):setParent(self)

  self.guiNodes = {
    {
      Gui.create({
        onPointerLeave = function(self)
          parent.hovered = false
        end,
        onPointerEnter = function(self)
          parent.hovered = true
        end,
        onUpdate = function(self)
          local EventLog = require 'modules.log-db.events-log'
          local log = EventLog.read(
            msgBus.send('GAME_STATE_GET'):getId()
          )

          local padding = 5
          local wrapLimit = parent.width - padding
          local titleText = {Color.SKY_BLUE, 'QUESTS'}
          bodyText:addf(titleText, wrapLimit, 'center', self.x + padding, self.y + padding)
          local titleWidth, titleHeight = bodyText:getSize()

          local questList = {}

          for _,info in pairs(log.quests) do
            if (not info.completed) then
              table.insert(questList, {1,1,0})
              table.insert(questList, '\n'..info.title..'\n')

              table.insert(questList, {0.9,0.9,0.9})
              table.insert(questList, info.description..'\n')
            end
          end

          if (#questList > 0) then
            local offsetY = 16
            bodyText:addf(questList, wrapLimit, nil, self.x + padding, self.y + offsetY)
            local textWidth, textHeight = bodyText:getSize()
            self.width, self.height = math.max(titleWidth, textWidth), titleHeight + textHeight + offsetY
          end
        end
      })
    }
  }

  self.log.layoutItems = self.guiNodes
end

function QuestLog.update(self)
  -- self.log.height = self.height
  self.log.width = self.width
end

function QuestLog.draw(self)
  local opacity = 1
  local log = self.log
  local bw = 1
  local x, y, width, height = log.x - bw, log.y - bw, log.width + bw * 2, log.height + bw * 2
  love.graphics.setColor(0.1,0.1,0.1,0.95 * opacity)
  love.graphics.rectangle('fill', x, y, width, height)
  love.graphics.setColor(Color.multiplyAlpha(Color.MED_GRAY, opacity))
  love.graphics.rectangle('line', x, y, width, height)
end

function QuestLog.drawOrder(self)
  return self.log:drawOrder() - 1
end

function QuestLog.final(self)
  MenuManager.pop()
end

return Component.createFactory(QuestLog)