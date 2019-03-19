local function replaceWithStringAndLowercase(char)
  return ' '..string.lower(char)
end

local function camelCaseHumanized(str)
  local result = str.gsub(str, '[A-Z]', replaceWithStringAndLowercase)
  return result
end

return camelCaseHumanized