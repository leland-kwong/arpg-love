local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local drawBox = require 'components.gui.utils.draw-box'

local DrawOrders = require 'modules.draw-orders'
local DialogText = GuiText.create({
  id = 'DialogText',
  group = 'all',
  font = require 'components.font'.primary.font,
  drawOrder = function()
    return DrawOrders.Dialog + 1
  end
})

local GuiDialog = {
  padding = 5
}

function GuiDialog.init(self)
  local parent = self
  Component.addToGroup(self, 'all')
  self.scriptPosition = 1

  self.advanceDialog = function()
    self.scriptPosition = self.scriptPosition + 1
  end

  Gui.create({
    onUpdate = function(self)
      self.width = love.graphics.getWidth()
      self.height = love.graphics.getHeight()
    end,
    onClick = parent.advanceDialog,
    drawOrder = function()
      return DrawOrders.Dialog + 2
    end
  }):setParent(parent)
end

function GuiDialog.update(self, dt)
  local endOfDialog = self.scriptPosition > #self.script
  if (endOfDialog) then
    return self:delete(true)
  end

  local isNewScript = self.script ~= self.lastScript
  self.lastScript = self.script

  if isNewScript then
    self.scriptPosition = 1
    self.lastScriptPosition = nil
  end

  local isNewScriptPosition = self.scriptPosition ~= self.lastScriptPosition
  self.lastScriptPosition = self.scriptPosition

  local script = self.script[self.scriptPosition]

  local width, height = DialogText.getTextSize(script.text, DialogText.font)
  self.width, self.height = width + self.padding*2, height + self.padding*2
  DialogText:add(script.text, Color.WHITE, self.x + self.padding, self.y + self.padding)
end

function GuiDialog.draw(self)
  drawBox(self)
end

function GuiDialog.drawOrder()
  return DrawOrders.Dialog
end

return Component.createFactory(GuiDialog)