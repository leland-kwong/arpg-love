local memoize = require 'utils.memoize'

local fontPrimary = memoize(function (fontSize)
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
end)

local fontSecondary = memoize(function (fontSize)
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
end)

local fontDebug = memoize(function (fontSize)
  local font = love.graphics.newFont(
    'built/fonts/Roboto_Mono/RobotoMono-Medium.ttf',
    fontSize
  )
  local lineHeight = 1
  font:setLineHeight(lineHeight)
  return {
    fontSize = fontSize,
    lineHeight = lineHeight,
    font = font
  }
end)

local fontAlias = {
  ['M41_LOVEBIT'] = function (fontSize)
    return fontSecondary(fontSize)
  end
}

return setmetatable({
  primary = fontPrimary(8),
  primaryLarge = fontPrimary(16),
  secondary = fontSecondary(8),
  secondaryLarge = fontSecondary(16),
  debug = fontDebug(12)
}, {
  __call = function(_, fontFileOrFontName, fontSize)
    local fontHandler = fontAlias[fontFileOrFontName]
    if fontHandler == nil then
      print('invalid font ', fontFileOrFontName)
    end

    local defaultFontSize = 16 -- tiled app has no font size when the font size is 16
    return fontHandler(fontSize or 16)
  end
})