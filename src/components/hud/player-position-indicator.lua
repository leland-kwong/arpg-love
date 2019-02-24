local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'

local function calcPulse(freq, time)
  return 0.5 * math.sin(freq * time) + 0.5
end

return function(x, y, time)
  local spriteCore = AnimationFactory:newStaticSprite('gui-player-position-indicator')
  local spriteGlow = AnimationFactory:newStaticSprite('gui-player-position-indicator-glow')

  spriteCore:draw(x, y)

  local opacity = calcPulse(4, time)
  love.graphics.setColor(1,1,1,opacity)
  spriteGlow:draw(x, y)
end