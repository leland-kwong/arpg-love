local TemplateParser = require 'utils.string-template'
local Color = require 'modules.color'
local String = require 'utils.string'

local colors = {
  statBodyText = {Color.rgba255(81, 162, 255)},
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

local modifierPropTypeDisplayMapper = require 'components.state.base-stat-modifiers'.propTypesDisplayValue
local statsListParsers = {
  default = function(prop, val)
    local mapperFn = modifierPropTypeDisplayMapper[prop]
    local sign = signHumanized(val)
    return sign..mapperFn(val)
  end
}

local tooltipParsers = {
  range = function(val)
    local mappers = modifierPropTypeDisplayMapper
    local _from, _to = val.from, val.to
    return mappers[_from.prop](_from.val)..'-'..mappers[_to.prop](_to.val)
  end,
  default = function(val)
    return val
  end
}

local modifierParsers = {
  baseStatsList = function(data)
    local coloredText = {}
    local i = 0
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
    for prop,val in pairs(data) do
      local valType = type(val) == 'table' and val.type or 'default'
      print('valType', valType, prop)
      local parsedVal = statsListParsers[valType](prop, val)
      local constants = require 'components.state.constants'
      table.insert(coloredText, Color.MED_GRAY)
      local bulletChar = i == 0 and constants.glyphs.diamondBullet or '\n'..constants.glyphs.diamondBullet
      table.insert(coloredText, bulletChar..' ')

      table.insert(coloredText, Color.WHITE)
      table.insert(coloredText, parsedVal)

      if valType == 'default' then
        table.insert(coloredText, colors.statBodyText)
        local camelCaseHumanized = require 'utils.camel-case-humanized'
        local displayKey = ' '..camelCaseHumanized(prop)
        table.insert(coloredText, displayKey)
      end
      i = i + 1
    end
    return coloredText
  end,
  activeAbility = function(data)
    local coloredText = {}

    table.insert(coloredText, Color.LIGHT_GRAY)
    table.insert(coloredText, 'active skill: ')

    local parsed = parser(data.template, data.data)
    for fragment, value in parsed do
      local isVariable = not not value
      local valueType = type(value) == 'table' and value.type or 'default'
      local color = isVariable and Color.WHITE or colors.statBodyText
      local displayValue = isVariable and tooltipParsers[valueType](value) or fragment
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