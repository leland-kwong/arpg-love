local function rgba255(r, g, b, a)
  return r/255, g/255, b/255, (a or 1)
end

local Color = {
  PRIMARY = {rgba255(81, 234, 241)},
  SKY_BLUE = {0.8,1,1,1},
  LIME = {0,1,0},
  WHITE = {1,1,1,1},
  LIME = {rgba255(35, 219, 93)},
  LIGHT_GRAY = {0.7,0.7,0.7,1},
  MED_GRAY = {0.5,0.5,0.5},
  MED_DARK_GRAY = {0.3,0.3,0.3},
  DARK_GRAY = {0.1,0.1,0.1,1},
  CYAN = {0.2,1,1},
  BLACK = {0,0,0,1},
  YELLOW = {1,1,0},
  GOLDEN_PALE = {rgba255(243, 156, 18)},

  multiply = function(a, b)
    return {
      a[1] * b[1],
      a[2] * b[2],
      a[3] * b[3],
      a[4] * b[4]
    }
  end
}

Color.rgba255 = rgba255

return Color