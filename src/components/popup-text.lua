local Component = require 'modules.component'
local font = require 'components.font'
local groups = require 'components.groups'
local tween = require 'modules.tween'
local f = require 'utils.functional'
local TablePool = require 'utils.table-pool'
local setProp = require 'utils.set-prop'
local GuiText = require 'components.gui.gui-text'

local lastDirection = 0
local function getDirection()
  lastDirection = lastDirection + 1
  if lastDirection > 1 then
    lastDirection = -1
  end
  return lastDirection
end

local PopupTextBlueprint = {
  group = groups.overlay,
  font = font.secondary.font,
  color = {1,1,1,1},
  x = 0,
  y = 0
}

local subjectPool = TablePool.newAuto()

local tweenEndState = {offset = -10, time = 1}
local function animationCo(duration, textWidth)
  local frame = 0
  local subject = setProp(subjectPool.get())
    :set('offset', 0)
    :set('time', 0)
    :set('dx', getDirection() * (textWidth + 4))
    :set('dy', math.random(0, 2) * 4)
  local posTween = tween.new(duration, subject, tweenEndState, tween.easing.outExpo)
  local complete = false

  while (not complete) do
    complete = posTween:update(1/60)
    coroutine.yield(subject.offset, subject.time, subject.dx, subject.dy)
  end
  subjectPool.release(subject)
end

function PopupTextBlueprint:new(text, x, y, duration, color)
  duration = duration or 0.3
  local textWidth = GuiText.getTextSize(text, self.font)
  local animation = coroutine.wrap(animationCo)
  animation(duration, textWidth)
  table.insert(self.textObjectsList, {text, x, y, animation, duration, color})
end

local outlineColor = {0,0,0,1}
local shader = require('modules.shaders')('pixel-outline.fsh')
local w, h = 16, 16

function PopupTextBlueprint.init(self)
  self.textObj = love.graphics.newText(self.font, '')
  self.textObjectsList = {}
end

local textObjShared = {}

function PopupTextBlueprint.update(self)
  self.textObj:clear()

  local i = 1
  while i <= #self.textObjectsList do
    local obj = self.textObjectsList[i]
    local text, x, y, animation, duration, color = obj[1], obj[2], obj[3], obj[4], obj[5], obj[6]
    local offsetY, time, dx, dy, errors = animation(duration)

    local isComplete = offsetY == nil
    if isComplete then
      table.remove(self.textObjectsList, i)
    else
      i = i + 1
      textObjShared[1] = color or self.color
      textObjShared[2] = text
      self.textObj:add(textObjShared, x + (time * dx), y + offsetY + dy)
    end
  end
end

local spriteSize = {w, h}

function PopupTextBlueprint.draw(self)
  shader:send('enabled', true)
  shader:send('sprite_size', spriteSize)
  shader:send('outline_width', 2/16)
  shader:send('outline_color', outlineColor)
  shader:send('include_corners', true)

  love.graphics.setShader(shader)
  love.graphics.setColor(self.color)
  love.graphics.draw(
    self.textObj,
    self.x,
    self.y
  )

  shader:send('enabled', false)
end

return Component.createFactory(PopupTextBlueprint)