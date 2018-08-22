local GuiText = require 'components.gui.gui-text'
local animationFactory = require'components.animation-factory'
local itemDefinition = require'components.item-inventory.items.item-definitions'
local font = require 'components.font'
local Position = require 'utils.position'

local itemAnimationsCache = {}

local guiStackSizeTextLayer = GuiText.create({
  font = font.primary.font,
  drawOrder = function()
    return 5
  end
})

local function drawItem(item, x, y, slotSize)
  local d = itemDefinition.getDefinition(item)
  if d then
    local animation = itemAnimationsCache[def]
    if not animation then
      animation = animationFactory:new({
        d.sprite
      })
      itemAnimationsCache[d] = animation
    end

    local sx, sy, sw, sh = animation.sprite:getViewport()
    local ox, oy = Position.boxCenterOffset(
      sw, sh,
      slotSize or sw, slotSize or sh
    )
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      animationFactory.atlas,
      animation.sprite,
      x + ox, y + oy
    )

    local showStackSize = item.stackSize > 1
    if showStackSize then
      guiStackSizeTextLayer:add(item.stackSize, Color.WHITE, x + ox, y + oy)
    end
  end
end

return drawItem