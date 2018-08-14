local Color = {
  SKY_BLUE = {0.8,1,1,1},
  WHITE = {1,1,1,1},
  MED_GRAY = {0.7,0.7,0.7,1},
  LIGHT_GRAY = {0.5,0.5,0.5},
  BLACK = {0,0,0},

  multiply = function(a, b)
    return {
      a[1] * b[1],
      a[2] * b[2],
      a[3] * b[3],
      a[4] * b[4]
    }
  end
}

return Color