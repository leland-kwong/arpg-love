-- string pad methods

-- all of these functions return their result and a boolean
-- to notify the caller if the string was even changed

local srep = string.rep

-- pad the left side
local lpad = function (s, l, spacer)
  local res = srep(spacer or ' ', l - #s) .. s

  return res, res ~= s
end

-- pad the right side
local rpad = function (s, l, spacer)
  local res = s .. srep(spacer or ' ', l - #s)

  return res, res ~= s
end

-- pad on both sides (centering with left justification)
local pad = function (s, l, spacer)
  spacer = spacer or ' '

  local res1, stat1 = rpad(s,    (l / 2) + #s, spacer) -- pad to half-length + the length of s
  local res2, stat2 = lpad(res1,  l,           spacer) -- right-pad our left-padded string to the full length

  return res2, stat1 or stat2
end

return {
  left = lpad,
  right = rpad,
  center = pad
}