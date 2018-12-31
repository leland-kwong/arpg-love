local Component = require 'modules.component'
local groups = require 'components.groups'
local guiTextLayers = require'components.item-inventory.gui-text-layers'
local Gui = require 'components.gui.gui'
local GuiText = require'components.gui.gui-text'
local Color = require'modules.color'

local PlayerStatsPanel = {
  group = groups.gui,
  rootStore = nil
}

local padding = 5
local primaryFont = require'components.font'.primary

function PlayerStatsPanel.init(self)
  local parent = self
  Gui.create({
    id = 'StatsPanelRegion',
    x = parent.x,
    y = parent.y,
    inputContext = 'StatsPanel',
    onUpdate = function(self)
      self.w = parent.w
      self.h = parent.h
    end,
  }):setParent(self)

  self.guiText = GuiText.create({
    font = primaryFont.font
  }):setParent(self)
end

local function drawBackground(self)
  love.graphics.setColor(0.2, 0.2, 0.2, 1)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
  love.graphics.setColor(Color.multiplyAlpha(Color.SKY_BLUE, 0.5))
  love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
end

local function drawCharacterName(self, characterName)
  self.guiText:add(characterName, Color.SKY_BLUE, self.x + padding, self.y + padding)
end

function PlayerStatsPanel.draw(self)
  local rootStore = self.rootStore

  drawBackground(self)
  drawCharacterName(self, rootStore:get().characterName)

  local i = 0
  local originY = 25

  -- player level
  local playerLevelOriginY = self.y + padding + (primaryFont.fontSize * primaryFont.lineHeight)
  self.guiText:add('Level: '..rootStore:get().level, Color.YELLOW, self.x + padding, playerLevelOriginY)

  local statNames = {}
  local statValues = {}
  local camelCaseHumanized = require 'utils.camel-case-humanized'
  local modifierPropTypeDisplayMapper = require 'components.state.base-stat-modifiers'.propTypesDisplayValue
  local playerRef = Component.get('PLAYER')
  local propsByAlphabetical = {}
  for stat in playerRef.stats:forEach() do
    table.insert(propsByAlphabetical, stat)
  end
  table.sort(propsByAlphabetical)
  for _,stat in pairs(propsByAlphabetical) do
    local val = playerRef.stats:get(stat)
    local statType = camelCaseHumanized(stat)..':\n'
    local displayValueMapper = modifierPropTypeDisplayMapper[stat]
    local statValue = displayValueMapper(val or 0)..'\n'
    local statValueColor = val > 0 and Color.LIME or Color.WHITE
    table.insert(statNames, Color.WHITE)
    table.insert(statNames, statType)

    table.insert(statValues, statValueColor)
    table.insert(statValues, statValue)
  end
  local wrapLimit = 155
  self.guiText:addf(statNames, wrapLimit, 'left', self.x + padding, self.y + originY + 16)
  self.guiText:addf(statValues, wrapLimit, 'right', self.x + padding, self.y + originY + 16)
end

return Component.createFactory(PlayerStatsPanel)

