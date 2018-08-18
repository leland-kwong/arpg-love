local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local Position = require 'utils.position'

local ExperienceIndicator = {
  group = groups.gui,
  experience = 0,
  totalExperience = 0,
}

local hudTextLayer = GuiText.create()

local function getExperienceInfo(self)
  return self.rootStore:get().experience,
    self.rootStore:get().experienceToNextLevel,
    self.rootStore:get().totalExperience
end

function ExperienceIndicator.init(self)
  local exp, experienceToNextLevel = getExperienceInfo(self)
  self.experience = exp
  self.experienceToNextLevel = experienceToNextLevel
  msgBus.subscribe(function(msgType, msgValue)
    if msgBus.EXPERIENCE_GAIN == msgType then
      self.rootStore:set('experience', function(state)
        -- TODO
        -- if experience surpasses experience needed for next level, then we've leveled up
        -- so we should get the new experience requirements
        return state.experience + msgValue
      end)
      local exp, experienceToNextLevel = getExperienceInfo(self)
      self.experience = exp
      self.experienceToNextLevel = experienceToNextLevel
    end
  end)
end

local function drawSegments(self, i, segmentCount, startX, totalWidth)
  local width = totalWidth / segmentCount
  local x = startX + (i * width)
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle('line', x, self.y, width, self.h)
end

function ExperienceIndicator.draw(self)
  -- background
  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

  -- experience gained for this level
  local r, g, b = 0, 0.6, 0
  local indicatorWidth = self.experience / self.experienceToNextLevel * self.w
  love.graphics.setColor(r, g, b)
  love.graphics.rectangle('fill', self.x, self.y, indicatorWidth, self.h)

  -- segment outlines
  local segmentCount = 6
  for i=0, (segmentCount - 1) do
    drawSegments(self, i, segmentCount, self.x, self.w)
  end
end

function ExperienceIndicator.drawOrder()
  return 1
end

return Component.createFactory(ExperienceIndicator)