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
local AnimationFactory = require 'components.animation-factory'
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

local healthManaWidth = 63 * 2

local function setupExperienceIndicator(self)
  local w, h = healthManaWidth - 2, 2
  local winWidth, winHeight = camera:getSize(true)
  local offX, offY = Position.boxCenterOffset(w, h, winWidth, winHeight)
  ExperienceIndicator.create({
    rootStore = self.rootStore,
    x = offX,
    y = winHeight - h - 11,
    w = w,
    h = h,
    drawOrder = function()
      return 2
    end
  }):setParent(self)
end

local menuButtonsList = {
  {
    displayValue = 'Portal Home (t)',
    normalAni = AnimationFactory:newStaticSprite('gui-home-portal-button'),
    hoverAni = AnimationFactory:newStaticSprite('gui-home-portal-button--hover'),
    onClick = function()
      msgBus.send(msgBus.PLAYER_PORTAL_OPEN)
    end
  },
  {
    displayValue = 'Inventory (i)',
    normalAni = AnimationFactory:newStaticSprite('gui-inventory-button'),
    hoverAni = AnimationFactory:newStaticSprite('gui-inventory-button--hover'),
    onClick = function()
      msgBus.send(msgBus.INVENTORY_TOGGLE)
    end
  },
  {
    displayValue = 'Skill Tree (o)',
    normalAni = AnimationFactory:newStaticSprite('gui-skill-tree-button'),
    hoverAni = AnimationFactory:newStaticSprite('gui-skill-tree-button--hover'),
    badge = function()
      local PlayerPassiveTree = require 'components.player.passive-tree'
      local unusedSkillPoints = PlayerPassiveTree.getUnusedSkillPoints()
      return unusedSkillPoints
    end,
    onClick = function()
      msgBus.send(msgBus.PASSIVE_SKILLS_TREE_TOGGLE)
    end
  },
  {
    displayValue = 'Map (m)',
    normalAni = AnimationFactory:newStaticSprite('gui-main-map-button'),
    hoverAni = AnimationFactory:newStaticSprite('gui-main-map-button--hover'),
    badge = function()
      return 0
    end,
    onClick = function()
      msgBus.send('MAP_TOGGLE')
    end
  },
  -- {
  --   displayValue = 'Quests (u)',
  --   normalAni = AnimationFactory:newStaticSprite('gui-quest-log-button'),
  --   hoverAni = AnimationFactory:newStaticSprite('gui-quest-log-button--hover'),
  --   badge = function()
  --     return 0
  --   end,
  --   onClick = function()
  --     msgBus.send('QUEST_LOG_TOGGLE')
  --   end
  -- },
  {
    displayValue = 'Main Menu (esc)',
    normalAni = AnimationFactory:newStaticSprite('gui-home-button'),
    hoverAni = AnimationFactory:newStaticSprite('gui-home-button--hover'),
    onClick = function()
      msgBus.send(msgBus.TOGGLE_MAIN_MENU)
    end
  },
}

function Hud.init(self)
  local root = self
  local mainSceneRef = Component.get('MAIN_SCENE')
  if mainSceneRef and self.minimapEnabled then
    local globalState = require 'main.global-state'
    local stateSnapshot = globalState.stateSnapshot
      :consumeSnapshot(mainSceneRef.mapId)
    local minimapW, minimapH = 100, 100
    local minimapMargin = 5
    local cameraWidth = camera:getSize(true)
    Minimap.create({
      camera = camera,
      grid = mainSceneRef.mapGrid,
      x = cameraWidth - minimapW - minimapMargin,
      y = minimapMargin,
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
      return 4
    end
  }):setParent(self)

  local winWidth, winHeight = camera:getSize(true)
  local barHeight = 18
  local offX, offY = Position.boxCenterOffset(healthManaWidth, barHeight, winWidth, winHeight)

  local function getHealthRemaining()
    local playerRef = Component.get('PLAYER')
    return playerRef.stats:get('health') / playerRef.stats:get('maxHealth')
  end

  local function getEnergyRemaining()
    local playerRef = Component.get('PLAYER')
    return playerRef.stats:get('energy') / playerRef.stats:get('maxEnergy')
  end

  -- health bar
  local StatusBarFancy = require 'components.hud.status-bar-fancy'
  local healthStatusBar = StatusBarFancy.create({
    id = 'healthStatusBar',
    x = offX - 2,
    y = winHeight - barHeight - 17,
    w = healthManaWidth / 2,
    h = barHeight,
    color = {Color.rgba255(207, 23, 59)},
    fillPercentage = getHealthRemaining
  }):setParent(self)

  -- mana bar
  local energyStatusBar = StatusBarFancy.create({
    x = offX + healthManaWidth / 2 + 1,
    y = healthStatusBar.y,
    w = healthManaWidth / 2,
    h = barHeight,
    fillDirection = -1,
    color = {Color.rgba255(24, 144, 224)},
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

  local function drawMenuButtonsUnderlay(buttonDefinitions)
    local AnimationFactory = require 'components.animation-factory'
    local aniLeft = AnimationFactory:newStaticSprite('gui-dashboard-menu-left')
    local aniMiddle = AnimationFactory:newStaticSprite('gui-dashboard-menu-middle')
    local aniRight = AnimationFactory:newStaticSprite('gui-dashboard-menu-right')
    local y = healthStatusBar.y - 1
    local x = offX - 2 + aniStatusBar:getWidth() + aniVialUnderlay:getWidth()

    local ox = aniLeft:getOffset()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      AnimationFactory.atlas,
      aniLeft.sprite,
      x,
      y + 2,
      0,
      1, 1,
      ox
    )

    local numButtons = #buttonDefinitions
    local buttonMargin = 2
    local middleWidth = (numButtons * 14) + (numButtons * buttonMargin) + 7 - (aniLeft:getWidth() + aniRight:getWidth())
    local ox = aniMiddle:getOffset()
    love.graphics.draw(
      AnimationFactory.atlas,
      aniMiddle.sprite,
      x + aniLeft:getWidth(),
      y + 2,
      0,
      middleWidth,
      1,
      ox
    )

    local ox = aniRight:getOffset()
    love.graphics.draw(
      AnimationFactory.atlas,
      aniRight.sprite,
      x + aniLeft:getWidth() + middleWidth,
      y,
      0,
      1, 1,
      ox
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
      drawMenuButtonsUnderlay(menuButtonsList)
    end,
    drawOrder = function(self)
      return 1
    end
  }):setParent(self)

  self.listeners = {
    msgBus.on(msgBus.PLAYER_HIT_RECEIVED, function(msgValue)
      local playerRef = Component.get('PLAYER')
      playerRef.health = max(0, playerRef.health - msgValue)
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

  HudStatusIcons.create({
    id = 'hudStatusIcons',
    x = healthStatusBar.x,
    y = healthStatusBar.y - 25
  }):setParent(self)

  local spacing = 27
  local endXPos = healthStatusBar.x - spacing - 7

  local skillSetup = {
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
    }):setParent(self)
  end

  local itemSetup = {
    {
      skillId = 'ACTIVE_ITEM_1',
      slotX = 1,
      slotY = 5
    },
    {
      skillId = 'ACTIVE_ITEM_2',
      slotX = 2,
      slotY = 5
    },
  }

  for i=1, #itemSetup do
    local skill = itemSetup[i]
    ActiveSkillInfo.create({
      skillId = skill.skillId,
      player = self.player,
      rootStore = self.rootStore,
      x = energyStatusBar.x + energyStatusBar.w + 9 + (spacing * (i - 1)),
      y = winHeight - 32 - 1,
      slotX = skill.slotX,
      slotY = skill.slotY,
      hudTextLayer = self.hudTextSmallLayer,
    }):setParent(self)
  end

  local MenuButtons = require 'components.hud.menu-buttons'
  MenuButtons.create({
    x = energyStatusBar.x + 135,
    y = healthStatusBar.y + 7,
    buttonDefinitions = menuButtonsList
  }):setParent(self)
end

function Hud.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(Hud)