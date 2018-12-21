local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local GuiList = require 'components.gui.gui-list'
local GuiButton = require 'components.gui.gui-button'
local Color = require 'modules.color'

local GuiDialog = {
  title = nil,
  text = '',
  width = 1,
  height = 1,
  padding = 0,
  wrapLimit = 20,
  onClose = nil -- optional callback. If enabled, the close button will be enabled
}

function GuiDialog.init(self)
  local root = self
  self.font = self.font or require('components.font').primary.font
  local guiTextLayer = GuiText.create({
    font = root.font,
    outline = true,
    drawOrder = self.drawOrder
  })
  Component.addToGroup(self, 'gui')

  if root.title then
    Component.create({
      init = function(self)
        Component.addToGroup(self, 'gui')
      end,
      draw = function()
        guiTextLayer:add(root.title, Color.YELLOW, root.x, root.y - 25 + root.padding)
      end,
      drawOrder = self.drawOrder
    }):setParent(root)
  end

  local textNode = Component.create({
    x = self.x,
    y = self.y,
    init = function(self)
      Component.addToGroup(self, 'gui')
    end,
    draw = function(self)
      love.graphics.setFont(root.font)
      love.graphics.setColor(1,1,1)
      love.graphics.printf(root.text, self.x + root.padding, self.y + root.padding, root.wrapLimit)
    end,
    drawOrder = function()
      return root:drawOrder() + 1
    end
  })
  self.scrollablePanel = GuiList.create({
    x = self.x,
    y = self.y,
    width = self.width,
    height = self.height,
    contentWidth = self.width,
    contentHeight = 0,
    childNodes = {
      textNode
    },
    drawOrder = function()
      return root:drawOrder() + 1
    end
  }):setParent(root)

  if self.onClose then
    local sp = self.scrollablePanel
    -- close button
    GuiButton.create({
      padding = 4,
      x = sp.x + sp.contentWidth - 13,
      y = sp.y - 20,
      textLayer = guiTextLayer,
      text = 'x',
      onClick = function()
        root:delete(true)
        self:onClose()
      end
    }):setParent(root)
  end
end

function GuiDialog.update(self)
  self.wrapLimit = (self.width - self.padding * 2)
  local width, height = GuiText.getTextSize(self.text, self.font, self.wrapLimit)
  self.scrollablePanel.contentHeight = height + self.padding * 2
end

function GuiDialog.draw(self)
  local guiDrawBox = require 'components.gui.utils.draw-box'
  guiDrawBox(self.scrollablePanel, {
    borderColor = Color.YELLOW
  })
end

return Component.createFactory(GuiDialog)