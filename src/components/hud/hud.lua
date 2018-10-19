local Component = require 'modules.component'
local groups = require 'components.groups'
local StatusBar = require 'components.hud.status-bar'
local ExperienceIndicator = require 'components.hud.experience-indicator'
local ScreenFx = require 'components.hud.screen-fx'
local ActiveSkillInfo = require 'components.hud.active-skill-info'
local ActionError = require 'components.hud.action-error'
local GuiText = require 'components.gui.gui-text'
local NpcInfo = require 'components.hud.npc-info'
local Notifier = require 'components.hud.notifier'
local Minimap = require 'components.map.minimap'
local camera = require 'components.camera'
local msgBus = require 'components.msg-bus'
local Position = require 'utils.position'
local scale = require 'config.config'.scaleFactor
local Color = require 'modules.color'
local config = require 'config.config'
local max = math.max

local Hud = {
  id = 'HUD',
  group = groups.hud,
  minimapEnabled = true,
  rootStore = {}
}

local healthManaWidth = 180

local function setupExperienceIndicator(self)
  local w, h = 180, 6
  local winWidth, winHeight = love.graphics.getWidth() / scale, love.graphics.getHeight() / scale
  local offX, offY = Position.boxCenterOffset(w, h, winWidth, winHeight)
  ExperienceIndicator.create({
    rootStore = self.rootStore,
    x = offX,
    y = winHeight - h - 5,
    w = w,
    h = h,
    drawOrder = function()
      return 2
    end
  }):setParent(self)
end

function Hud.init(self)
  local mainSceneRef = Component.get('MAIN_SCENE')
  if mainSceneRef and self.minimapEnabled then
    local minimapW, minimapH = 100, 100
    local minimapMargin = 5
    Minimap.create({
      camera = camera,
      grid = mainSceneRef.mapGrid,
      x = love.graphics.getWidth()/config.scale - minimapW - minimapMargin,
      y = minimapH + minimapMargin,
      w = minimapW,
      h = minimapH,
      scale = config.scale
    }):setParent(self)
  end

  self.hudTextLayer = GuiText.create({
    group = groups.hud,
    drawOrder = function()
      return 4
    end
  }):setParent(self)

  self.hudTextSmallLayer = GuiText.create({
    group = groups.hud,
    font = require 'components.font'.primary.font,
    drawOrder = function()
      return 10
    end
  }):setParent(self)

  local notifierWidth, notifierHeight = 250, 200
  Notifier.create({
    x = love.graphics.getWidth()/config.scale - notifierWidth,
    y = love.graphics.getHeight()/config.scale - notifierHeight,
    h = notifierHeight,
    w = notifierWidth
  }):setParent(self)

  local winWidth, winHeight = love.graphics.getWidth() / scale, love.graphics.getHeight() / scale
  local barHeight = 18
  local offX, offY = Position.boxCenterOffset(healthManaWidth, barHeight, winWidth, winHeight)

  local function getHealthRemaining()
    local state = self.rootStore:get()
    local maxHealth = state.maxHealth + state.statModifiers.maxHealth
    local health = state.health
    return health / maxHealth
  end

  local function getEnergyRemaining()
    local state = self.rootStore:get()
    local maxEnergy = state.maxEnergy + state.statModifiers.maxEnergy
    local energy = state.energy
    return energy / maxEnergy
  end

  -- health bar
  StatusBar.create({
    x = offX,
    y = winHeight - barHeight - 13,
    w = healthManaWidth / 2,
    h = barHeight,
    color = {Color.rgba255(209, 27, 27)},
    fillPercentage = getHealthRemaining,
    drawOrder = function()
      return 2
    end
  }):setParent(self)

  -- -- mana bar
  local energyStatusBar = StatusBar.create({
    x = offX + healthManaWidth / 2,
    y = winHeight - barHeight - 13,
    w = healthManaWidth / 2,
    h = barHeight,
    fillDirection = -1,
    color = {Color.rgba255(33, 89, 186)},
    fillPercentage = getEnergyRemaining,
    drawOrder = function()
      return 2
    end
  }):setParent(self)

  self.listeners = {
    msgBus.on(msgBus.PLAYER_HIT_RECEIVED, function(msgValue)
      self.rootStore:set('health', function(state)
        return max(0, state.health - msgValue)
      end)

      return msgValue
    end),
    msgBus.on(msgBus.SCENE_CHANGE, function(sceneRef)
      local ZoneInfo = require 'components.hud.zone-info'
      ZoneInfo.create()
    end)
  }

  setupExperienceIndicator(self)
  ScreenFx.create({
    drawOrder = function()
      return 1
    end
  }):setParent(self)
  NpcInfo.create():setParent(self)
  ActionError.create({
    textLayer = self.hudTextSmallLayer
  }):setParent(self)

  local spacing = 32
  local endXPos = 355

  local skillSetup = {
    {
      skillId = 'ACTIVE_ITEM_2',
      slotX = 2,
      slotY = 5
    },
    {
      skillId = 'ACTIVE_ITEM_1',
      slotX = 1,
      slotY = 5
    },
    {
      skillId = 'SKILL_4',
      slotX = 2,
      slotY = 2
    },
    {
      skillId = 'SKILL_3',
      slotX = 2,
      slotY = 1
    },
    {
      skillId = 'SKILL_2',
      slotX = 1,
      slotY = 2
    },
    {
      skillId = 'SKILL_1',
      slotX = 1,
      slotY = 1
    },
    {
      skillId = 'MOVE_BOOST',
      slotX = 1,
      slotY = 4
    }
  }

  for i=1, #skillSetup do
    local skill = skillSetup[i]
    ActiveSkillInfo.create({
      skillId = skill.skillId,
      player = self.player,
      rootStore = self.rootStore,
      x = endXPos - (spacing * (i - 1)),
      y = winHeight - 32 - 1,
      slotX = skill.slotX,
      slotY = skill.slotY,
      hudTextLayer = self.hudTextSmallLayer,
      drawOrder = function()
        return 2
      end
    }):setParent(self)
  end

  local MenuButtons = require 'components.hud.menu-buttons'
  MenuButtons.create({
    x = energyStatusBar.x + energyStatusBar.w + 5,
    y = winHeight - 30
  }):setParent(self)
end

function Hud.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(Hud)