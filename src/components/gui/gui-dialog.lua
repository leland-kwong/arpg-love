local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local drawBox = require 'components.gui.utils.draw-box'
local MenuList2 = require 'components.gui.menu-list-2'
local camera = require 'components.camera'
local F = require 'utils.functional'
local msgBus = require 'components.msg-bus'

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
  padding = 5,
  wrapLimit = 200
}

local function createToggleOverlayArea(parent)
  return Gui.create({
    onUpdate = function(self)
      self.x = 0
      self.y = 0
      self.width = love.graphics.getWidth()/2
      self.height = love.graphics.getHeight()/2
    end,
    onClick = parent.onResume,
    drawOrder = function()
      return DrawOrders.Dialog + 2
    end
  })
end

local function renderScriptOptions(parent)
  local options = parent.getOptions() or {}
  local isNewOptions = options ~= parent.previousOptions
  if isNewOptions then
    if parent.renderedOptions then
      F.forEach(parent.renderedOptions, function(optionNode)
        optionNode:delete(true)
      end)
    end
    parent.previousOptions = options
    parent.renderedOptions = F.map(options, function(option, index)
      local padding = 4
      return Gui.create({
        group = 'all',
        id = 'script-option-'..index,
        height = select(2, GuiText.getTextSize(option, DialogText.font)) + 1 + padding,
        getMousePosition = function()
          local camera = require 'components.camera'
          return camera:getMousePosition()
        end,
        onClick = function()
          parent.onOptionSelect(index)
        end,
        onUpdate = function(self)
          local previousHeights = 0
          for i=1, (index - 1) do
            local o = options[i]
            previousHeights = previousHeights + select(2, GuiText.getTextSize(o, DialogText.font)) + padding
          end
          self.x, self.y = parent.x, parent.y + parent.height + previousHeights
          self.innerX, self.innerY = self.x + padding, self.y + padding
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
            c, option
          }
          DialogText:addf(formattedString, self.innerWidth, 'left', self.innerX + padding, self.y + padding-1)

          if self.hovered then
            local h = parent.optionHighlightRectangle
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

  self.optionHighlightRectangle = Gui.create({
    group = 'all',
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

  Component.addToGroup(self, 'all')

  createToggleOverlayArea(parent)
    :setParent(parent)
end

function GuiDialog.getCurrentScript(self)
  return self.script
end

function GuiDialog.update(self, dt)
  local parent = self
  local endOfDialog = self.isDone()
  if (endOfDialog) then
    self:delete(true)
    self.onDone()
    return
  end
  wrapLimit = self.wrapLimit

  local bodyWidth, bodyHeight = DialogText.getTextSize(self.getText(), DialogText.font, self.wrapLimit)

  renderScriptOptions(self)

  local letterHeight = GuiText.getTextSize('a', DialogText.font)
  local optionsMarginTop = (#self:getOptions() > 0) and (letterHeight) or 0
  self.optionsTotalHeight = F.reduce(self.renderedOptions, function(totalHeight, optionNode)
    return totalHeight + optionNode.height
  end, 0)
  self.width, self.height = bodyWidth + self.padding*2
    ,bodyHeight + self.padding*2 + optionsMarginTop

  self.x, self.y = self.renderPosition.x, self.renderPosition.y - self.height - self.optionsTotalHeight

  local markdownToLove2d = require 'modules.markdown-to-love2d-string'
  DialogText:addf(markdownToLove2d(self.getText()).formatted, wrapLimit, 'left', self.x + self.padding, self.y + self.padding)
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