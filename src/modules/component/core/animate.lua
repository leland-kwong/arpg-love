local tween = require 'modules.tween'
local noop = require 'utils.noop'

return function(Component)
  local tweens = {}

  Component.animate = function (subject, target, duration, easing, onComplete)
    local tween = tween.new(duration, subject, target, easing)
    tweens[subject] = {
      tween = tween,
      onComplete = onComplete or noop
    }
    return tween
  end

  Component.animateUpdate = function(dt)
    for ref,t in pairs(tweens) do
      local complete = t.tween:update(dt)
      if complete then
        t.onComplete()
        tweens[ref] = nil
      end
    end
  end
end