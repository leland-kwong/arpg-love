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

local function getExpInfo(self)
  local curState = self.rootStore:get()
  local currentLevel = curState.level
  local currentLevelRequirement = config.levelExperienceRequirements[currentLevel]
  local nextLevelRequirement = config.levelExperienceRequirements[currentLevel + 1]
  local totalExp = curState.totalExperience
  local currentLevelExp = totalExp - currentLevelRequirement
  local expRequiredForLevelUp = nextLevelRequirement - currentLevelRequirement
  local progress = currentLevelExp / expRequiredForLevelUp

  return totalExp, progress
end

function ExperienceIndicator.init(self)
  msgBus.on(msgBus.EXPERIENCE_GAIN, function(msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    msgValue = math.floor(msgValue) -- round fractional values

    self.rootStore:set('totalExperience', function(state)
      return state.totalExperience + msgValue
    end)
    local totalExp, progress = getExpInfo(self)
    local isLevelUp = progress >= 1
    if isLevelUp then
      self.rootStore:set('level', function(state)
        return state.level + 1
      end)
      love.audio.stop(Sound.levelUp)
      love.audio.play(Sound.levelUp)
      msgBus.send(msgBus.PLAYER_LEVEL_UP)
      msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
        title = 'level up!',
        description = {
          Color.WHITE, 'you are now level ',
          Color.CYAN, self.rootStore:get().level
        }
      })
    end

    return msgValue
  end, 1)
end

function ExperienceIndicator.update(self)
  local totalExp, progress = getExpInfo(self)
  self.experience = totalExp
  self.progress = progress
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
    drawSegments(self, i, segmentCount, self.x, self.w)
  end
end

function ExperienceIndicator.drawOrder()
  return 1
end

return Component.createFactory(ExperienceIndicator)