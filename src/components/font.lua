local function fontPrimary(fontSize)
  local font = love.graphics.newFont(
    'built/fonts/StarPerv.ttf',
    fontSize
  )

  return {
    fontSize = fontSize,
    lineHeight = 1.2,
    font = font
  }
end

local function fontSecondary()
  local fontSize = 8
  local font = love.graphics.newFont(
    'built/fonts/m41.ttf',
    fontSize
  )
  return {
    fontSize = fontSize,
    lineHeight = 1.2,
    font = font
  }
end

return {
  primary = fontPrimary(8),
  primaryLarge = fontPrimary(16),
  secondary = fontSecondary()
}