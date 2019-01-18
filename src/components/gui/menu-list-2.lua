local Component = require 'modules.component'
local Grid = require 'utils.grid'
local getRect = require 'utils.rect'
local GuiList = require 'components.gui.gui-list'
local Gui = require 'components.gui.gui'

local function setupChildNodes(self)
  local childNodes = {}
  local newRect = getRect(self.layoutItems)
  local guiList = self.guiList
  Grid.forEach(newRect.childRects, function(rect, x, y)
    local guiNode = Grid.get(self.layoutItems, x, y)
    guiNode.x = guiList.x + rect.x
    guiNode.y = guiList.y + rect.y + guiList.scrollTop

    local guiListTop = guiList.y
    local guiListBottom = guiList.y + guiList.height
    local isInView = (guiNode.y + (guiNode.height or 0)) >= guiListTop and
      guiNode.y <= guiListBottom
    guiNode._isInView = isInView
    table.insert(childNodes, guiNode)
  end)

  guiList.contentHeight = newRect.height
  guiList.contentWidth = newRect.width
  if self.maxWidth then
    local newWidth = math.min(self.maxWidth, newRect.width)
    guiList.width = newWidth
    self.width = newWidth
  else
    guiList.width = newRect.width
    self.width = guiList.width
  end
  if self.maxHeight then
    local newHeight = math.min(self.maxHeight, newRect.height)
    guiList.height = newHeight
    self.height = newHeight
  else
    guiList.height = newRect.height
    self.heiht = guiList.heiht
  end
  for i=1, #self.otherItems do
    local item = self.otherItems[i]
    table.insert(childNodes, item)
  end

  return childNodes
end

return Component.createFactory({
  width = 1,
  height = 1,
  layoutItems = {}, -- 2-d array
  otherItems = {}, -- other components that should be added to the list for clipping
  maxWidth = nil,
  maxHeight = nil,
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
        parent.guiList.childNodes = setupChildNodes(parent)
      end
    }):setParent(self)

    self.guiList = GuiList.create({
      childNodes = {},
      inputContext = parent.inputContext,
      drawOrder = function()
        return parent:drawOrder()
      end
    }):setParent(parent)

    self.interactZone = Gui.create({
      inputContext = parent.inputContext,
      onUpdate = function(self)
        local guiList = parent.guiList
        self.x = guiList.x
        self.y = guiList.y
        self.width = guiList.width
        self.height = guiList.height
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
      end,
    }):setParent(parent)

    self.guiList.childNodes = setupChildNodes(self)
  end,

  update = function(self)
    local isNewLayoutItems = self.layoutItems ~= self.prevLayoutItems
    self.prevLayoutItems = self.layoutItems
    if isNewLayoutItems then
      self.guiList.childNodes = setupChildNodes(self)
    end
    self.guiList.x, self.guiList.y = self.x, self.y
    if (not self.autoWidth) then
      self.guiList.width = self.width
    end
    self.guiList.height = self.height
  end
})