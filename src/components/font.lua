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

local function fontSecondary(fontSize)
  local font = love.graphics.newFont(
    -- https://w.itch.io/world-of-fonts
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
  secondary = fontSecondary(8),
  secondaryLarge = fontSecondary(16)
}