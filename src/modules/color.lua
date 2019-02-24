local assign = require 'utils.object-utils'.assign

local Color = {}

function Color.rgba255(r, g, b, a)
  return r/255, g/255, b/255, (a or 1)
end

-- multiplies two color tables and returns the 4 channel values separately (for performance reasons)
function Color.multiply(a, b)
  if not b then
    return a[1],
      a[2],
      a[3],
      (a[4] or 1)
  end
  return
    a[1] * b[1],
    a[2] * b[2],
    a[3] * b[3],
    (a[4] or 1) * (b[4] or 1)
end

local alphaColor = {1,1,1,1}
function Color.multiplyAlpha(a, alpha)
  alphaColor[4] = alpha
  return Color.multiply(a, alphaColor)
end

local colors = {
  PRIMARY = {Color.rgba255(81, 234, 241)},
  SKY_BLUE = {0.8,1,1,1},
  DEEP_BLUE = {Color.rgba255(91, 181, 255)},
  LIME = {0,1,0,1},
  WHITE = {1,1,1,1},
  LIME = {Color.rgba255(35, 219, 93)},
  OFF_WHITE = {0.85,0.85,0.85,1},
  LIGHT_GRAY = {0.7,0.7,0.7,1},
  MED_GRAY = {0.5,0.5,0.5,1},
  MED_DARK_GRAY = {0.3,0.3,0.3,1},
  DARK_GRAY = {0.1,0.1,0.1,1},
  DARK_GRAY_BLUE = {0.1,0.12,0.125,1},
  CYAN = {0.2,1,1,1},
  BLACK = {0,0,0,1},
  YELLOW = {1,1,0,1},
  PALE_YELLOW = {Color.rgba255(254, 250, 192)},
  GOLDEN_PALE = {Color.rgba255(243, 156, 18)},
  RED = {1,0,0,1},
  DEEP_RED = {Color.rgba255(200, 43, 43)},
  TRANSPARENT = {0,0,0,0},
  PURPLE = {Color.rgba255(107, 171, 255)},

  RARITY_NORMAL = {1,1,1,1},
  RARITY_MAGICAL = {Color.rgba255(107, 171, 255)}, -- blueish-purple
  RARITY_RARE = {1,1,0,1}, -- yellow
  RARITY_EPIC = {Color.rgba255(228, 96, 255)}, -- magenta
  RARITY_LEGENDARY = {Color.rgba255(229, 140, 16)} -- gold
}
-- validate colors
for name,color in pairs(colors) do
  local inspect = require 'utils.inspect'
  assert(#color == 4, 'colors should be a table of 4-channel rgba values. Color was \n' .. inspect(color))
  for k,v in pairs(color) do
    assert(type(v) == 'number' and v >= 0 and v <= 1, 'color channel value must be between 0 and 1')
  end
end

assign(Color, colors)

return Color