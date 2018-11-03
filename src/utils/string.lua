local String = {}

local function gsubCapitalize(a, b)
  return string.upper(a)..b
end

String.capitalize = function(str)
  local newString = str:gsub('(%l)(%w*)', gsubCapitalize)
  return newString
end

return String