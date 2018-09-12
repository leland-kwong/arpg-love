local function setElectricShockShader(time)
  local shader = electricShockShader
  love.graphics.setShader(shader)
  shader:send('time', time)
  shader:send('speed', 6)
  shader:send('resolution', 1)
  shader:send('brightness', 1.0)
  shader:send('noiseImage', image)
end

return setElectricShockShader