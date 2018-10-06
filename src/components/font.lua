local function fontPrimary(fontSize)
  local font = love.graphics.newFont(
    -- 'built/fonts/PolygonPixel5x7Cyrillic.ttf',
    'built/fonts/StarPerv.ttf',
    fontSize
  )
  local lineHeight = 1.4
  font:setLineHeight(lineHeight)
  -- font:setFilter('linear')

  return {
    fontSize = fontSize,
    lineHeight = lineHeight,
    font = font
  }
end

local function fontSecondary(fontSize)
  local font = love.graphics.newFont(
    -- https://w.itch.io/world-of-fonts
    'built/fonts/m41.ttf',
    fontSize
  )
  local lineHeight = 2
  font:setLineHeight(lineHeight)
  return {
    fontSize = fontSize,
    lineHeight = lineHeight,
    font = font
  }
end

return {
  primary = fontPrimary(8),
  primaryLarge = fontPrimary(16),
  secondary = fontSecondary(8),
  secondaryLarge = fontSecondary(16)
}