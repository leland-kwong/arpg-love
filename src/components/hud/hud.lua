local Component = require 'modules.component'
local groups = require 'components.groups'
local StatusBar = require 'components.hud.status-bar'
local ExperienceIndicator = require 'components.hud.experience-indicator'
local ScreenFx = require 'components.hud.screen-fx'
local ActiveSkillInfo = require 'components.hud.active-skill-info'
local GuiText = require 'components.gui.gui-text'
local NpcInfo = require 'components.hud.npc-info'
local Notifier = require 'components.hud.notifier'
local Minimap = require 'components.map.minimap'
local HudStatusIcons = require 'components.hud.status-icons'
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

local healthManaWidth = 62 * 2

local function setupExperienceIndicator(self)
  local w, h = healthManaWidth, 4
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
  local root = self
  local mainSceneRef = Component.get('MAIN_SCENE')
  if mainSceneRef and self.minimapEnabled then
    local stateSnapshot = msgBus.send(msgBus.GLOBAL_STATE_GET)
      .stateSnapshot
        :consumeSnapshot(mainSceneRef.mapId)
    local minimapW, minimapH = 100, 100
    local minimapMargin = 5
    Minimap.create({
      camera = camera,
      grid = mainSceneRef.mapGrid,
      x = love.graphics.getWidth()/config.scale - minimapW - minimapMargin,
      y = minimapH + minimapMargin,
      w = minimapW,
      h = minimapH,
      scale = config.scale,
      visitedIndices = stateSnapshot and (stateSnapshot.miniMap[1].state.visitedIndices)
    }):setParent(self)
  end

  self.hudTextLayer = GuiText.create({
    id = 'hudTextLayer',
    group = groups.hud,
    drawOrder = function()
      return 4
    end
  }):setParent(self)

  self.hudTextSmallLayer = GuiText.create({
    id = 'hudTextSmallLayer',
    group = groups.hud,
    font = require 'components.font'.primary.font,
    drawOrder = function()
      return 10
    end
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
  local StatusBarFancy = require 'components.hud.status-bar-fancy'
  local healthStatusBar = StatusBarFancy.create({
    id = 'healthStatusBar',
    x = offX - 1,
    y = winHeight - barHeight - 17,
    w = healthManaWidth / 2,
    h = barHeight,
    color = {Color.rgba255(228, 59, 119)},
    fillPercentage = getHealthRemaining
  }):setParent(self)

  -- mana bar
  local energyStatusBar = StatusBarFancy.create({
    x = offX + healthManaWidth / 2 + 1,
    y = healthStatusBar.y,
    w = healthManaWidth / 2,
    h = barHeight,
    fillDirection = -1,
    color = {Color.rgba255(44, 192, 245)},
    fillPercentage = getEnergyRemaining
  }):setParent(self)

  local AnimationFactory = require 'components.animation-factory'
  local aniStatusBar = AnimationFactory:newStaticSprite('gui-dashboard-status-bars-underlay')
  local function drawStatusBarUnderlay()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      AnimationFactory.atlas,
      aniStatusBar.sprite,
      offX - 6,
      healthStatusBar.y - 4
    )
  end

  local function drawAbilityUnderlay()
    local AnimationFactory = require 'components.animation-factory'
    local ani = AnimationFactory:newStaticSprite('gui-dashboard-abilities-underlay')
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      AnimationFactory.atlas,
      ani.sprite,
      offX - 6 - ani:getWidth(),
      healthStatusBar.y - 7
    )
  end

  local AnimationFactory = require 'components.animation-factory'
  local aniVialUnderlay = AnimationFactory:newStaticSprite('gui-dashboard-vials-underlay')
  local function drawVialUnderlay()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      AnimationFactory.atlas,
      aniVialUnderlay.sprite,
      offX - 6 + aniStatusBar:getWidth(),
      healthStatusBar.y - 7
    )
  end

  local function drawMenuButtonsUnderlay()
    local AnimationFactory = require 'components.animation-factory'
    local aniLeft = AnimationFactory:newStaticSprite('gui-dashboard-menu-left')
    local aniMiddle = AnimationFactory:newStaticSprite('gui-dashboard-menu-middle')
    local aniRight = AnimationFactory:newStaticSprite('gui-dashboard-menu-right')
    local y = healthStatusBar.y
    local x = offX - 4 + aniStatusBar:getWidth() + aniVialUnderlay:getWidth()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      AnimationFactory.atlas,
      aniLeft.sprite,
      x,
      y + 2
    )
    local middleWidth = 1
    love.graphics.draw(
      AnimationFactory.atlas,
      aniMiddle.sprite,
      x + aniLeft:getWidth(),
      y + 2
    )
    love.graphics.draw(
      AnimationFactory.atlas,
      aniRight.sprite,
      x + aniLeft:getWidth() + middleWidth,
      y
    )
  end

  Component.create({
    init = function(self)
      Component.addToGroup(self, 'hud')
    end,
    draw = function()
      drawStatusBarUnderlay()
      drawVialUnderlay()
      drawAbilityUnderlay()
      drawMenuButtonsUnderlay()
    end,
    drawOrder = function(self)
      return 1
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

  -- setupExperienceIndicator(self)
  ScreenFx.create({
    drawOrder = function()
      return 1
    end
  }):setParent(self)
  NpcInfo.create():setParent(self)

  HudStatusIcons.create({
    id = 'hudStatusIcons',
    x = healthStatusBar.x,
    y = healthStatusBar.y - 25
  }):setParent(self)

  local spacing = 32
  local endXPos = healthStatusBar.x - spacing

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
      slotX = 1,
      slotY = 2
    },
    {
      skillId = 'SKILL_2',
      slotX = 2,
      slotY = 1
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
    x = energyStatusBar.x + 134,
    y = healthStatusBar.y + 5
  }):setParent(self)
end

function Hud.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(Hud)