local TemplateParser = require 'utils.string-template'
local Color = require 'modules.color'
local String = require 'utils.string'

local colors = {
  statBodyText = {0.8,0.8,0.8},
  upgradeTitle = Color.WHITE
}

local parser = TemplateParser({
  delimiters = {'{', '}'}
})

local upgradeFragmentHandlers = {
  title = function(title)
    if (not title) then
      return nil
    end
    return colors.upgradeTitle, String.capitalize(title..': ')
  end,
  description = function(description)
    local parsed = parser(description.template, description.data)
    return function(coloredText)
      for fragment, data in parsed do
        local isVariable = not not data
        local color = isVariable and Color.WHITE or colors.statBodyText
        local value = isVariable and data or fragment
        table.insert(coloredText, color)
        table.insert(coloredText, value)
      end
    end
  end,
}

local signHumanized = function(v)
  return v >= 0 and '+' or '' -- minus sign is part of negative value
end

local modifierParsers = {
  baseStatsList = function(data)
    local coloredText = {}
    local i = 0
    local modifierPropTypeDisplayMapper = require 'components.state.base-stat-modifiers'.propTypesDisplayValue
    for k,v in pairs(data) do
      table.insert(coloredText, colors.statBodyText)
      if i > 0 then
        table.insert(coloredText, '\n')
      end

      -- stat name
      table.insert(coloredText, colors.statBodyText)
      local camelCaseHumanized = require 'utils.camel-case-humanized'
      local displayKey = camelCaseHumanized(k)..': '
      table.insert(coloredText, displayKey)

      -- state value
      table.insert(coloredText, Color.WHITE)
      local mapperFn = modifierPropTypeDisplayMapper[k]
      table.insert(coloredText, mapperFn(v))
      i = i + 1
    end
    return coloredText
  end,
  -- modifier stats
  statsList = function(data)
    local coloredText = {}
    local i = 0
    local modifierPropTypeDisplayMapper = require 'components.state.base-stat-modifiers'.propTypesDisplayValue
    for k,v in pairs(data) do
      table.insert(coloredText, colors.statBodyText)
      local sign = signHumanized(v)
      if i == 0 then
        table.insert(coloredText, sign)
      else
        table.insert(coloredText, '\n'..sign)
      end

      table.insert(coloredText, Color.WHITE)
      local mapperFn = modifierPropTypeDisplayMapper[k]
      table.insert(coloredText, mapperFn(v))

      table.insert(coloredText, colors.statBodyText)
      local camelCaseHumanized = require 'utils.camel-case-humanized'
      local displayKey = ' '..camelCaseHumanized(k)
      table.insert(coloredText, displayKey)
      i = i + 1
    end
    return coloredText
  end,
  activeAbility = function(data)
    local coloredText = {}

    table.insert(coloredText, Color.DEEP_BLUE)
    table.insert(coloredText, 'active skill: ')

    local parsed = parser(data.template, data.data)
    for fragment, value in parsed do
      local isVariable = not not value
      local color = isVariable and Color.WHITE or colors.statBodyText
      local displayValue = isVariable and value or fragment
      table.insert(coloredText, color)
      table.insert(coloredText, displayValue)
    end
    return coloredText
  end,
  upgrade = function(data)
    local template = '{title}{description}'
    local parsed = parser(template, data)
    local coloredText = {}
    for variable, data in parsed do
      local color, value = upgradeFragmentHandlers[variable](data)
      local isFunc = type(color) == 'function'
      if isFunc then
        color(coloredText)
      elseif (color and value) then
        table.insert(coloredText, color)
        table.insert(coloredText, value)
      end
    end
    return coloredText
  end
}

return function(data)
  if (not data) then
    return {}
  end
  assert(
    modifierParsers[data.type],
    'invalid modifier type'
  )
  return modifierParsers[data.type](data.data)
end