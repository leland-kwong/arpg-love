local Component = require 'modules.component'
local groups = require 'components.groups'
local guiTextLayers = require'components.item-inventory.gui-text-layers'
local GuiText = require'components.gui.gui-text'
local Color = require'modules.color'

local PlayerStatsPanel = {
  group = groups.gui,
  rootStore = nil
}

local padding = 5
local primaryFont = require'components.font'.primary

function PlayerStatsPanel.init(self)
  self.guiText = GuiText.create({
    font = primaryFont.font
  })
end

local function drawBackground(self)
  love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
end

local function drawTitle(self)
  local characterName = 'Character Name'
  self.guiText:add(characterName, Color.SKY_BLUE, self.x + padding, self.y + padding)
end

function PlayerStatsPanel.draw(self)
  drawBackground(self)
  drawTitle(self)

  local rootStore = self.rootStore
  local i = 0
  for stat,val in pairs(rootStore:get().statModifiers) do
    local w, h = self.guiText:getSize()
    local xPos, yPos = self.x + padding, self.y + 25 + (h * i * primaryFont.lineHeight)
    local statType = stat..': '
    self.guiText:add(statType, Color.WHITE, xPos, yPos)
    local statValue = val..'\n'
    local statValueColor = val > 0 and Color.LIME or Color.WHITE
    self.guiText:add(statValue, statValueColor, xPos + 100, yPos)
    i = i + 1
  end
end

return Component.createFactory(PlayerStatsPanel)

