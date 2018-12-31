local M = {}

local function gsubCapitalize(a, b)
  return string.upper(a)..b
end

M.capitalize = function(str)
  local newString = str:gsub('(%l)(%w*)', gsubCapitalize)
  return newString
end

-- split a string
function M.split(str, delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( str, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( str, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( str, delimiter, from  )
  end
  table.insert( result, string.sub( str, from  ) )
  return result
end

local function _unhex(hex) return string.char(tonumber(hex, 16)) end
--- Unescape a escaped hexadecimal representation string.
-- @param s (String) String to unescape.
function M.unescape(s)
    return string.gsub(s, "%%(%x%x)", _unhex)
end

local function _hex(c)
    return string.format("%%%02x", string.byte(c))
end
--- Encodes a string into its escaped hexadecimal representation.
-- @param s (String) String to escape.
function M.escape(s)
    return string.gsub(s, "([^A-Za-z0-9_])", _hex)
end

return M