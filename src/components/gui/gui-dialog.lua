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
        onClick = function()
          parent.script = option.action()
        end,
        onUpdate = function(self)
          local previousHeights = 0
          for i=1, (index - 1) do
            local o = options[i]
            previousHeights = previousHeights + select(2, GuiText.getTextSize(o.label, DialogText.font))
          end
          self.x, self.y = parent.x, parent.y + parent.height + previousHeights
          self.innerX, self.innerY = self.x + self.padding, self.y + self.padding
          self.width = parent.width
          self.innerWidth = parent.width - (parent.padding * 2)
        end,
        render = function(self)
          local c = self.hovered and Color.LIME or Color.DEEP_BLUE
          love.graphics.setColor(c)
          local Constants = require 'components.state.constants'
          local bullet = Constants.glyphs.diamondBullet
          local formattedString = {
            Color.MED_GRAY,
            bullet..' ',
            c, option.label
          }
          DialogText:addf(formattedString, self.innerWidth, 'left', self.innerX + self.padding, self.y)

          if self.hovered then
            local h = parent.HoverRectangle
            h.show = self.hovered
            h.color = c
            h.x = self.innerX
            h.y = self.y
            h.width = self.innerWidth
            h.height = self.height
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

  self.HoverRectangle = Gui.create({
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
  }):setParent(self)

  Component.addToGroup(self, 'gui')

  self.advanceDialog = function()
    self.script.defaultOption()
  end

  createToggleOverlayArea(parent)
    :setParent(parent)
end

function GuiDialog.getCurrentScript(self)
  return self.script
end

function GuiDialog.update(self, dt)
  local parent = self
  self.script = self.nextScript()
  local endOfDialog = not self.script
  if (endOfDialog) then
    return self:delete(true)
  end
  wrapLimit = self.wrapLimit

  local isNewScript = self.script ~= self.lastScript
  self.lastScript = self.script

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

  local markdownToLove2d = require 'modules.markdown-to-love2d-string'
  DialogText:addf(markdownToLove2d(script.text).formatted, wrapLimit, 'left', self.x + self.padding, self.y + self.padding + titleHeight)
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
  }, 'tooltip')
end

function GuiDialog.drawOrder()
  return DrawOrders.Dialog
end

return Component.createFactory(GuiDialog)