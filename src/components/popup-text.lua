local Component = require 'modules.component'
local font = require 'components.font'
local groups = require 'components.groups'
local tween = require 'modules.tween'
local f = require 'utils.functional'
local TablePool = require 'utils.table-pool'
local setProp = require 'utils.set-prop'

local PopupTextBlueprint = {
  group = groups.overlay,
  font = font.secondary.font,
  color = {1,1,1,1},
  x = 0,
  y = 0,
}

local subjectPool = TablePool.newAuto()

local tweenEndState = {offset = -10}
local function animationCo(duration)
  local frame = 0
  local subject = setProp(subjectPool.get())
    :set('offset', 0)
  local posTween = tween.new(duration, subject, tweenEndState, tween.easing.outExpo)
  local complete = false

  while (not complete) do
    complete = posTween:update(1/60)
    coroutine.yield(subject.offset)
  end
  subjectPool.release(subject)
end

function PopupTextBlueprint:new(text, x, y, duration)
  local animation = coroutine.wrap(animationCo)
  table.insert(self.textObjectsList, {text, x, y, animation, duration or 0.3})
end

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {0,0,0,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local w, h = 16, 16

function PopupTextBlueprint.init(self)
  self.textObj = love.graphics.newText(self.font, '')
  self.textObjectsList = {}
end

function PopupTextBlueprint.update(self)
  self.textObj:clear()

  local i = 1
  while i <= #self.textObjectsList do
    local obj = self.textObjectsList[i]
    local text, x, y, animation, duration = obj[1], obj[2], obj[3], obj[4], obj[5]
    local offsetY, errors = animation(duration)

    local isComplete = offsetY == nil
    if isComplete then
      table.remove(self.textObjectsList, i)
    else
      i = i + 1
      self.textObj:add(text, x, y + offsetY)
    end
  end
end

local spriteSize = {w, h}

function PopupTextBlueprint.draw(self)
  shader:send('sprite_size', spriteSize)
  shader:send('outline_width', 2/16)
  shader:send('outline_color', outlineColor)
  shader:send('use_drawing_color', true)
  shader:send('include_corners', true)

  love.graphics.setShader(shader)
  love.graphics.setColor(self.color)
  love.graphics.draw(
    self.textObj,
    self.x,
    self.y
  )
  love.graphics.setShader()
end

return Component.createFactory(PopupTextBlueprint)