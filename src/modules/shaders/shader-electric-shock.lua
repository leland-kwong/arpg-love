local noiseImage = love.graphics.newImage('built/images/220px-White-noise-240x180.png')
noiseImage:setFilter('linear')

local function setElectricShockShader(time, resolution)
  local shader = require('modules.shaders')('electric-shock.fsh')
  love.graphics.setShader(shader)
  shader:send('time', time)
  shader:send('speed', 6)
  shader:send('resolution', resolution)
  shader:send('brightness', 1.5)
  shader:send('noiseImage', noiseImage)
end

return setElectricShockShader