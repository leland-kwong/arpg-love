local AutoCache = require 'utils.auto-cache'

return AutoCache.new({
  newValue = function(effect)
    return require('components.effects.'..effect)
  end
})