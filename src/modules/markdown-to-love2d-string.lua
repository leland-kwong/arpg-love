local StringTemplate = require 'utils.string-template'
local Enum = require 'utils.enum'
local formatTypes = Enum({
  'BOLD',
  'HEADING'
})
local parseMarkdown = function(str)
  local uid = require 'utils.uid'
  local definitions = {}

  -- SIDE-EFFECT
  local boldPattern = '%*%*[^ *][^\n*]*%*%*'
  local newString = string.gsub(str, boldPattern, function(group)
    local id = uid()
    definitions[id] = {
      text = string.sub(group, 3, -3),
      originalText = group,
      formatType = formatTypes.BOLD
    }
    return '{'.. id ..'}'
  end)

  -- SIDE-EFFECT
  local headingPattern = '[#]+ [^#\n]*\n'
  newString = string.gsub(newString, headingPattern, function(group)
    local id = uid()
    definitions[id] = {
      text = string.sub(string.gsub(group, '#', ''), 2),
      originalText = group,
      formatType = formatTypes.HEADING
    }
    return '{'.. id ..'}'
  end)

  local bulletPattern = '* [^\n*]*'
  local Constants = require 'components.state.constants'
  newString = string.gsub(newString, bulletPattern, function(group)
    return string.gsub(group, '*', Constants.glyphs.diamondBullet)
  end)

  return {
    newString = newString,
    definitions = definitions
  }
end

local Parser = StringTemplate()

local formatColors = {
  default = {1,1,1},
  [formatTypes.BOLD] = {1,0.8,0},
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