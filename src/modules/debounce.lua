local tick = require 'utils.tick'

return function(fn, delay)
  local isReady = true
  local function debounceReady()
    isReady = true
  end
  return function(a, b, c, d, e, f, g)
    if isReady then
      fn(a, b, c, d, e, f, g)
      tick.delay(debounceReady, delay)
    end
    isReady = false
  end
end