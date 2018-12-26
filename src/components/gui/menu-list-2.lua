local Component = require 'modules.component'
local Grid = require 'utils.grid'
local getRect = require 'utils.rect'
local GuiList = require 'components.gui.gui-list'
local Gui = require 'components.gui.gui'

return Component.createFactory({
  width = 1,
  height = 1,
  layoutItems = {}, -- 2-d array
  otherItems = {}, -- other components that should be added to the list for clipping
  init = function(self)
    local parent = self
    Component.addToGroup(self, 'gui')
    self.inputContext = self.inputContext or self:getId()

    -- we want to update list components before the `guiList` component does its rendering since there is scrolling involved
    Component.create({
      init = function(self)
        Component.addToGroup(self, 'gui')
      end,
      update = function(_, dt)
        local childNodes = {}
        local newRect = getRect(self.layoutItems)
        local guiList = self.guiList
        Grid.forEach(newRect.childRects, function(rect, x, y)
          local guiNode = Grid.get(self.layoutItems, x, y)
          guiNode.x = guiList.x + rect.x
          guiNode.y = guiList.y + rect.y + guiList.scrollTop

          local guiListTop = guiList.y
          local guiListBottom = guiList.y + guiList.height
          local isInView = (guiNode.y + guiNode.height) >= guiListTop and
            guiNode.y <= guiListBottom
          guiNode._isInView = isInView
          table.insert(childNodes, guiNode)
        end)

        guiList.contentHeight = newRect.height
        guiList.contentWidth = newRect.width
        guiList.width = newRect.width
        for i=1, #self.otherItems do
          local item = self.otherItems[i]
          table.insert(childNodes, item)
        end
        guiList.childNodes = childNodes

        self.width = guiList.width
      end
    }):setParent(self)

    self.guiList = GuiList.create({
      x = self.x,
      y = self.y,
      width = self.width,
      height = self.height,
      childNodes = {},
      inputContext = parent.inputContext,
      drawOrder = function()
        return parent:drawOrder()
      end
    }):setParent(parent)
    self.interactZone = Gui.create({
      x = self.x,
      y = self.y,
      inputContext = parent.inputContext,
      onUpdate = function(self)
        self.width = parent.guiList.width
        self.height = parent.guiList.height
      end,
      onPointerEnter = function()
        Grid.forEach(parent.layoutItems, function(guiNode)
          guiNode:setEventsDisabled(false)
        end)
      end,
      onPointerLeave = function()
        Grid.forEach(parent.layoutItems, function(guiNode)
          guiNode:setEventsDisabled(true)
        end)
      end
    }):setParent(parent)
  end,
})