local function fontPrimary(fontSize)
  local font = love.graphics.newFont(
    -- 'built/fonts/BMmini_2.ttf',
    -- 'built/fonts/bm_mini/bm_mini.ttf',
    -- 'built/fonts/HelvetiPixel.ttf',
    -- 'built/fonts/HelvetiPixel_2.ttf',
    'built/fonts/TinyUnicode.ttf',
    fontSize
  )
  local lineHeight = 1
  font:setLineHeight(lineHeight)

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
  local lineHeight = 1.4
  font:setLineHeight(lineHeight)
  return {
    fontSize = fontSize,
    lineHeight = lineHeight,
    font = font
  }
end

local function fontDebug(fontSize)
  local font = love.graphics.newFont(
    'built/fonts/Roboto_Mono/RobotoMono-Medium.ttf',
    12
  )
  local lineHeight = 1
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
  secondaryLarge = fontSecondary(16),
  debug = fontDebug(12)
}