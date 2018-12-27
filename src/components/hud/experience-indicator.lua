local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local Sound = require 'components.sound'
local Position = require 'utils.position'
local config = require 'config.config'

local ExperienceIndicator = {
  group = groups.hud,
  experience = 0,
  totalExperience = 0,
}

local hudTextLayer = GuiText.create()

local memoize = require 'utils.memoize'
local getCurrentLevel = memoize(function (totalExp)
  for level=1, #config.levelExperienceRequirements do
    local expRequired = config.levelExperienceRequirements[level]
    if expRequired > totalExp then
      return level - 1
    end
  end
end)

local function getExpInfo(currentLevel, totalExp)
  local currentLevelRequirement = config.levelExperienceRequirements[currentLevel]
  local nextLevelRequirement = config.levelExperienceRequirements[currentLevel + 1]
  local currentLevelExp = totalExp - currentLevelRequirement
  local expRequiredForLevelUp = nextLevelRequirement - currentLevelRequirement
  local progress = currentLevelExp / expRequiredForLevelUp

  return progress
end

function ExperienceIndicator.init(self)
  msgBus.on(msgBus.EXPERIENCE_GAIN, function(msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    local currentLevel = self.rootStore:get().level
    self.rootStore:set('totalExperience', function(state)
      return math.max(0, state.totalExperience + msgValue)
    end)
    local nextLevel = getCurrentLevel(self.rootStore:get().totalExperience)
    local isLevelUp = currentLevel < nextLevel
    if isLevelUp then
      love.audio.stop(Sound.levelUp)
      love.audio.play(Sound.levelUp)
      msgBus.send(msgBus.PLAYER_LEVEL_UP)
      msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
        title = 'level up!',
        description = {
          Color.WHITE, 'you are now level ',
          Color.CYAN, nextLevel
        }
      })
    end
  end)
end

function ExperienceIndicator.update(self)
  local totalExp = self.rootStore:get().totalExperience
  local progress = getExpInfo(self.rootStore:get().level, totalExp)
  self.experience = totalExp
  self.progress = progress

  local currentLevel = getCurrentLevel(totalExp)
  self.rootStore:set('level', currentLevel)
end

local function drawSegments(self, i, segmentCount, startX, totalWidth)
  local width = totalWidth / segmentCount
  local x = startX + (i * width)
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle('line', x, self.y, width, self.h)
end

function ExperienceIndicator.draw(self)
  love.graphics.setLineWidth(1)

  -- background
  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

  -- experience gained for this level
  local indicatorWidth = self.progress * self.w
  love.graphics.setColor(Color.GOLDEN_PALE)
  love.graphics.rectangle('fill', self.x, self.y, indicatorWidth, self.h)

  -- segment outlines
  local segmentCount = 6
  for i=0, (segmentCount - 1) do
    -- drawSegments(self, i, segmentCount, self.x, self.w)
  end
end

function ExperienceIndicator.drawOrder()
  return 1
end

return Component.createFactory(ExperienceIndicator)