local Component = require 'modules.component'
local groups = require 'components.groups'
local GuiText = require 'components.gui.gui-text'
local StatusBar = require 'components.hud.status-bar'
local collisionWorlds = require 'components.collision-worlds'
local camera = require 'components.camera'
local config = require 'config.config'
local Position = require 'utils.position'
local Color = require 'modules.color'

local itemHovered = nil
local aiHoverFilter = function(item)
  return (not itemHovered) and item.group == 'ai'
end

local NpcInfo = {
  group = groups.hud,
  target = nil -- hovered npc component
}

local function windowSize()
  return love.graphics.getWidth() / config.scale, love.graphics.getHeight() / config.scale
end

function NpcInfo.init(self)
  local w, h = 200, 20
  local y = 14
  local windowW, windowH = windowSize()
  local x = Position.boxCenterOffset(w, h, windowW, windowH)
  self.statusBar = StatusBar.create({
    x = x,
    y = y,
    w = w,
    h = h,
    color = Color.DEEP_RED,
    fillPercentage = function()
      local percentage = self.target:getBaseStat('health') /
        self.target:getCalculatedStat('maxHealth')
      return percentage
    end
  }):setDisabled(true)
end

function NpcInfo.update(self, dt)
  local textLayer = Component.get('HUD').hudTextLayer
  local textLayerSmall = Component.get('HUD').hudTextSmallLayer
  local mx, my = camera:getMousePosition()
  local area = 4
  itemHovered = nil
  local items, len = collisionWorlds.map:queryRect(
    -- readjust coordinates to center to mouse
    mx - area,
    my - area,
    area,
    area,
    aiHoverFilter
  )

  self.collisionShape = {
    x = mx,
    y = my,
    size = area
  }

  if len > 0 then
    itemHovered = items[1].parent
    local dataSheet = itemHovered.dataSheet
    local name = itemHovered.name or ''
    local windowW, windowH = windowSize()
    local textWidth, textHeight = GuiText.getTextSize(dataSheet.name, textLayer.font)
    local x, y = Position.boxCenterOffset(
      textWidth,
      textHeight,
      windowW,
      windowH
    )
    textLayer:add(
      dataSheet.name,
      itemHovered.outlineColor or Color.WHITE,
      x,
      20
    )
    local props = dataSheet.properties
    for i=1, #props do
      local p = props[i]
      local textWidth, textHeight = GuiText.getTextSize(p, textLayerSmall.font)
      local x, y = Position.boxCenterOffset(
        textWidth,
        textHeight,
        windowW,
        windowH
      )
      textLayerSmall:add(p, Color.WHITE, x, 28 + (i * 8) + 2)
    end
    self.target = itemHovered
  end
  self.statusBar:setDisabled(not itemHovered)
end

return Component.createFactory(NpcInfo)