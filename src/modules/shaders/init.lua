local AutoCache = require 'utils.auto-cache'

return AutoCache.new({
  newValue = function(shaderSource)
    local source = love.filesystem.read('modules/shaders/'..shaderSource)
    return love.graphics.newShader(
      source
    )
  end
})