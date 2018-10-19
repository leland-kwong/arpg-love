local Color = require 'modules.color'
local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local f = require 'utils.functional'

local function scrollbars(self)
  local verticalRatio = self.h / (self.h + self.scrollHeight)
  local horizontalRatio = self.w / (self.w + self.scrollWidth)

  if self.scrollHeight > 0 then
    local scrollbarWidth = 5
    local scrollbarHeight = verticalRatio * self.h
    love.graphics.setColor(Color.PRIMARY)
    love.graphics.rectangle(
      'fill',
      self.x + self.w - scrollbarWidth,
      self.y - (self.scrollTop * verticalRatio),
      scrollbarWidth,
      scrollbarHeight
    )
  end

  if self.scrollWidth > 0 then
    local scrollbarWidth = horizontalRatio * self.w
    local scrollbarHeight = 5
    love.graphics.setColor(Color.PRIMARY)
    love.graphics.rectangle(
      'fill',
      self.x - (self.scrollLeft * horizontalRatio),
      self.y + self.h - scrollbarHeight,
      scrollbarWidth,
      scrollbarHeight
    )
  end
end

local GuiList = {
  childNodes = {},
  width = 0,
  height = 0,
  contentWidth = nil,
  contentHeight = nil
}

function GuiList.init(self)
  local parent = self
  Component.addToGroup(self, 'gui')

  self.contentWidth = self.contentWidth or self.width
  self.contentHeight = self.contentHeight or self.height
  local children, width, height, contentWidth, contentHeight =
    self.childNodes, self.width, self.height, self.contentWidth, self.contentHeight

  local function guiStencil()
    love.graphics.rectangle(
      'fill',
      self.x,
      self.y,
      width,
      height
    )
  end

  local baseDrawOrder = self.drawOrder

  local noop = require 'utils.noop'
  f.forEach(children, function(child, index)
    child.drawOrder = function()
      return baseDrawOrder() + index
    end
  end)

  local stencilComponent = Component.create({
    group = Component.groups.gui,
    draw = function()
      -- remove stencil
      love.graphics.setStencilTest()
      love.graphics.pop()
    end,
    drawOrder = function()
      return baseDrawOrder() + #children + 1
    end
  }):setParent(self)

  local listNode = Gui.create({
    x = self.x,
    y = self.y,
    inputContext = self.inputContext,
    w = width,
    h = height,
    type = Gui.types.LIST,
    children = children,
    scrollHeight = (contentHeight >= height) and (contentHeight - height) or height,
    scrollWidth = (contentWidth >= width) and (contentWidth - width) or width,
    scrollSpeed = 8,
    onScroll = function(self)
    end,
    render = function(self)

      -- setup stencil
      love.graphics.push()
      love.graphics.stencil(guiStencil, 'replace', 1)
      love.graphics.setStencilTest('greater', 0)

      scrollbars(self)
    end,
    drawOrder = baseDrawOrder
  }):setParent(self)
end

local function removeChildren(self)
  for i=1, #self.childNodes do
    self.childNodes[i]:delete(true)
  end
end

function GuiList.final(self)
  removeChildren(self)
end

return Component.createFactory(GuiList)