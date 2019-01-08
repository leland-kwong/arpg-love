local uid = require 'utils.uid'
local StringTemplate = require 'utils.string-template'
local Enum = require 'utils.enum'
local formatTypes = Enum({
  'BOLD',
  'EM', -- emphasis
  'HEADING'
})

local function parseBold(newString, definitions)
  -- SIDE-EFFECT
  local boldPattern = '%*%*[^ *][^*\n]+%*%*'

  return string.gsub(newString, boldPattern, function(group)
    local id = uid()
    definitions[id] = {
      text = string.sub(group, 3, -3),
      originalText = group,
      formatType = formatTypes.BOLD
    }
    return '{'.. id ..'}'
  end)
end

local function parseEmphasis(newString, definitions)
  local emphasisPattern = '%*[^ *][^*\n]+%*'

  return string.gsub(newString, emphasisPattern, function(group)
    local id = uid()
    definitions[id] = {
      text = string.sub(group, 2, -2),
      originalText = group,
      formatType = formatTypes.EM
    }
    return '{'.. id ..'}'
  end)
end

local function parseHeadings(newString, definitions)
  local headingPattern = '[#]+ [^#\n]*\n'
  return string.gsub(newString, headingPattern, function(group)
    local id = uid()
    definitions[id] = {
      text = string.sub(string.gsub(group, '#', ''), 2),
      originalText = group,
      formatType = formatTypes.HEADING
    }
    return '{'.. id ..'}'
  end)
end

local function parseBullet(newString)
  local bulletPattern = '* [^\n*]*'
  local Constants = require 'components.state.constants'
  return string.gsub(newString, bulletPattern, function(group)
    return string.gsub(group, '*', Constants.glyphs.diamondBullet)
  end)
end

local parseMarkdown = function(str)
  local definitions = {}
  local newString = str

  newString = parseBold(newString, definitions)
  newString = parseEmphasis(newString, definitions)
  newString = parseHeadings(newString, definitions)
  newString = parseBullet(newString)

  return {
    newString = newString,
    definitions = definitions
  }
end

local Parser = StringTemplate()

local formatColors = {
  default = {1,1,1},
  [formatTypes.BOLD] = {1,0.8,0},
  [formatTypes.EM] = {1,0.8,0},
  [formatTypes.HEADING] = {0,1,0.8}
}

return function(md)
  local parsed = parseMarkdown(md)
  -- print(parsed.newString)
  local strings = {}
  for key,data in Parser(parsed.newString, parsed.definitions) do
    if (not data) then
      table.insert(strings, formatColors.default)
      table.insert(strings, key)
    else
      table.insert(strings, formatColors[data.formatType])
      table.insert(strings, data.text)
    end
  end

  return {
    plainText = parsed.newString,
    formatted = strings
  }
end