local Component = require 'modules.component'
local groups = require 'components.groups'
local HealthIndicator = require 'components.hud.health-indicator'
local ExperienceIndicator = require 'components.hud.experience-indicator'
local ScreenFx = require 'components.hud.screen-fx'
local ActiveSkillInfo = require 'components.hud.active-skill-info'
local GuiText = require 'components.gui.gui-text'
local Position = require 'utils.position'
local scale = require 'config.config'.scaleFactor

local Hud = {
  group = groups.gui,
  rootStore = {}
}

local function setupHealthIndicator(self)
  local w, h = 180, 18
  local winWidth, winHeight = love.graphics.getWidth() / scale, love.graphics.getHeight() / scale
  local offX, offY = Position.boxCenterOffset(w, h, winWidth, winHeight)
  HealthIndicator.create({
    rootStore = self.rootStore,
    x = offX,
    y = winHeight - h - 13,
    w = w,
    h = h,
    hudTextLayer = self.hudTextLayer
  }):setParent(self)
end

local function setupExperienceIndicator(self)
  local w, h = 180, 6
  local winWidth, winHeight = love.graphics.getWidth() / scale, love.graphics.getHeight() / scale
  local offX, offY = Position.boxCenterOffset(w, h, winWidth, winHeight)
  ExperienceIndicator.create({
    rootStore = self.rootStore,
    x = offX,
    y = winHeight - h - 5,
    w = w,
    h = h
  }):setParent(self)
end

function Hud.init(self)
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

  setupHealthIndicator(self)
  setupExperienceIndicator(self)
  ScreenFx.create():setParent(self)

  local spacing = 32
  local endXPos = 340

  local skillSetup = {
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
    {
      skillId = 'SKILL_1',
      slotX = 1,
      slotY = 3
    },
    {
      skillId = 'SKILL_2',
      slotX = 2,
      slotY = 3
    },
    {
      skillId = 'SKILL_3',
      slotX = 1,
      slotY = 2
    },
    {
      skillId = 'SKILL_4',
      slotX = 2,
      slotY = 2
    }
  }

  for i=1, #skillSetup do
    local skill = skillSetup[i]
    ActiveSkillInfo.create({
      skillId = skill.skillId,
      player = self.player,
      rootStore = self.rootStore,
      x = endXPos - (spacing * (i - 1)),
      y = (love.graphics.getHeight() / scale) - 32 - 1,
      slotX = skill.slotX,
      slotY = skill.slotY,
      hudTextLayer = self.hudTextSmallLayer
    }):setParent(self)
  end
end

return Component.createFactory(Hud)