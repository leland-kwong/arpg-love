local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local drawBox = require 'components.gui.utils.draw-box'
local MenuList2 = require 'components.gui.menu-list-2'
local camera = require 'components.camera'
local F = require 'utils.functional'

local DrawOrders = require 'modules.draw-orders'
local DialogText = GuiText.create({
  id = 'DialogText',
  font = require 'components.font'.primary.font,
  drawOrder = function()
    return DrawOrders.Dialog + 1
  end
})

local HoverRectangle = Gui.create({
  id = 'DialogHoverRectangle',
  render = function(self)
    if self.show then
      love.graphics.setColor(self.color)
      love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    end
    self.show = false
  end,
  drawOrder = function()
    return DrawOrders.Dialog + 10
  end
})

local GuiDialog = {
  padding = 5,
  wrapLimit = 200
}

local function createToggleOverlayArea(parent)
  return Gui.create({
    onUpdate = function(self)
      self.x = 0
      self.y = 0
      self.width = love.graphics.getWidth()
      self.height = love.graphics.getHeight()
    end,
    onClick = parent.advanceDialog,
    drawOrder = function()
      return DrawOrders.Dialog + 2
    end
  })
end

local function renderScriptOptions(parent)
  local options = parent:getCurrentScript().options or {}
  local isNewOptions = options ~= parent.previousOptions
  if isNewOptions then
    if parent.renderedOptions then
      F.forEach(parent.renderedOptions, function(optionNode)
        optionNode:delete(true)
      end)
    end
    parent.previousOptions = options
    parent.renderedOptions = F.map(options, function(option, index)
      return Gui.create({
        group = 'all',
        id = 'script-option-'..index,
        padding = 5,
        height = select(2, GuiText.getTextSize(option.label, DialogText.font)),
        onClick = option.action,
        onUpdate = function(self)
          local previousOption = options[index - 1]
          local previousItemHeight = previousOption and
            select(2, GuiText.getTextSize(previousOption.label, DialogText.font)) or
            0
          self.x, self.y = parent.x, parent.y + parent.height + previousItemHeight
          self.innerX, self.innerY = self.x + self.padding, self.y + self.padding
          self.width = parent.width
          self.innerWidth = parent.width - (parent.padding * 2)
        end,
        render = function(self)
          local c = self.hovered and Color.LIME or Color.DEEP_BLUE
          love.graphics.setColor(c)
          DialogText:addf({c, option.label}, self.innerWidth, 'left', self.innerX + self.padding, self.y)

          if self.hovered then
            HoverRectangle.show = self.hovered
            HoverRectangle.color = c
            HoverRectangle.x = self.innerX
            HoverRectangle.y = self.y
            HoverRectangle.width = self.innerWidth
            HoverRectangle.height = self.height
          end
        end,
        drawOrder = function()
          return DrawOrders.Dialog + 2
        end
      }):setParent(parent)
    end)
  end
end

function GuiDialog.init(self)
  local parent = self
  Component.addToGroup(self, 'gui')
  self.scriptPosition = 1

  self.advanceDialog = function()
    self.scriptPosition = self.scriptPosition + 1
  end

  createToggleOverlayArea(parent)
    :setParent(parent)
end

function GuiDialog.isNewScriptPosition(self)
  return self.scriptPosition ~= self.lastScriptPosition
end

function GuiDialog.getCurrentScript(self)
  return self.script[self.scriptPosition]
end

function GuiDialog.update(self, dt)
  local parent = self
  local endOfDialog = (self.scriptPosition > #self.script) or (not self.script)
  if (endOfDialog) then
    return self:delete(true)
  end
  wrapLimit = self.wrapLimit

  local isNewScript = self.script ~= self.lastScript
  self.lastScript = self.script

  if isNewScript then
    self.scriptPosition = 1
    self.lastScriptPosition = nil
  end

  self.lastScriptPosition = self.scriptPosition

  local script = self:getCurrentScript()
  script.options = script.options or {}

  local titleHeight = 0
  if script.title then
    titleHeight = select(2, DialogText.getTextSize(script.title, DialogText.font, self.wrapLimit))
  end

  local bodyWidth, bodyHeight = DialogText.getTextSize(script.text, DialogText.font, self.wrapLimit)

  renderScriptOptions(self)

  local letterHeight = GuiText.getTextSize('a', DialogText.font)
  local optionsMarginTop = (#script.options > 0) and (letterHeight) or 0
  self.optionsTotalHeight = F.reduce(self.renderedOptions, function(totalHeight, optionNode)
    return totalHeight + optionNode.height
  end, 0)
  self.width, self.height = bodyWidth + self.padding*2
    ,bodyHeight + self.padding*2 + titleHeight + optionsMarginTop

  self.x, self.y = camera:toScreenCoords(self.renderPosition.x, self.renderPosition.y - self.height - self.optionsTotalHeight)

  DialogText:addf(script.text, wrapLimit, 'left', self.x + self.padding, self.y + self.padding + titleHeight)
  if script.title then
    DialogText:add(script.title, Color.SKY_BLUE, self.x + self.padding, self.y + self.padding)
  end
end

function GuiDialog.draw(self)
  drawBox({
    x = self.x,
    y = self.y,
    width = self.width,
    height = self.height + self.optionsTotalHeight + (self.optionsTotalHeight > 0 and self.padding or 0)
  })
end

function GuiDialog.drawOrder()
  return DrawOrders.Dialog
end

return Component.createFactory(GuiDialog)