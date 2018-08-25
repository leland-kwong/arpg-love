local Component = require 'modules.component'
local Color = require 'modules.color'
local groups = require 'components.groups'
local M = {}

local queue = {}

-- creates a bounding box centered to point x,y
function M.boundingBox(mode, x, y, w, h, center)
  center = center == nil and true or center
  local function draw()
    local ox, oy = center and -w/2 or 0,
      center and -h/2 or 0
    love.graphics.rectangle(
      mode,
      x + ox,
      y + oy,
      w,
      h
    )
    love.graphics.setColor(1,1,0)
    love.graphics.circle(
      'fill',
      x,
      y,
      2
    )
  end
  queue[#queue + 1] = draw
end

local Debug = {
  group = groups.debug,
  draw = function()
    for i=1, #queue do
      love.graphics.setColor(1,1,1,0.5)
      queue[i]()
      queue[i] = nil
    end
    love.graphics.setColor(1,1,1,1)
  end
}

Component.createFactory(Debug).create()

return M