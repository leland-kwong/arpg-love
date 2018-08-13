local function fontPrimary()
  local fontSize = 16
  local lineHeight = fontSize * 1
  local font = love.graphics.newFont(
    'built/fonts/StarPerv.ttf',
    fontSize
  )

  return {
    fontSize = fontSize,
    lineHeight = lineHeight,
    font = font
  }
end

local function fontSecondary()
  local fontSize = 8
  local lineHeight = fontSize * 1
  local font = love.graphics.newFont(
    'built/fonts/m41.ttf',
    fontSize
  )
  return {
    fontSize = fontSize,
    lineHeight = lineHeight,
    font = font
  }
end

return {
  primary = fontPrimary(),
  secondary = fontSecondary()
}