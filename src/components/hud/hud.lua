local Component = require 'modules.component'
local groups = require 'components.groups'
local HealthIndicator = require 'components.hud.health-indicator'
local ExperienceIndicator = require 'components.hud.experience-indicator'
local ScreenFx = require 'components.hud.screen-fx'
local ActiveItemInfo = require 'components.hud.active-skill-info'
local Position = require 'utils.position'
local scale = require 'config'.scaleFactor

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
    h = h
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
  setupHealthIndicator(self)
  setupExperienceIndicator(self)
  ScreenFx.create():setParent(self)
  ActiveItemInfo.create({
    player = self.player,
    rootStore = self.rootStore,
    x = 300,
    y = (love.graphics.getHeight() / scale) - 32 - 5,
    slotX = 1,
    slotY = 5
  })
end

return Component.createFactory(Hud)