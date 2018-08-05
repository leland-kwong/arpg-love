local pprint = require 'utils.pprint'
local flowField = require 'scene.sandbox.ai.flow-field'
local groups = require 'components.groups'

local arrow = love.graphics.newImage('scene/sandbox/ai/arrow-up.png')

local grid = {
  {1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1},
  -- {1,1,1,1,1,1,1},
  -- {1,1,1,1,1,1,1},
  -- {1,1,1,1,1,1,1},
}

-- pprint(
--   flowField(grid, 2, 1)
-- )

local flowFieldTestBlueprint = {}

function flowFieldTestBlueprint.init(self)
  self.flowField = flowField(grid, 2, 2)
end

local function arrowRotationFromDirection(d)
  local dx, dy = d[1], d[2]
  if dx < 0 then
    return math.rad(-90)
  end
  if dx > 0 then
    return math.rad(90)
  end
  if dy < 0 then
    return math.rad(0)
  end
  return math.rad(180)
end

function flowFieldTestBlueprint.draw(self)
  love.graphics.clear(0,0,0,1)

  local offX, offY = 250, 100

  for y=1, #self.flowField do
    local row = self.flowField[y]
    for x=1, #row do
      local size = 80
      local drawX, drawY =
        (x * size) + offX,
        (y * size) + offY
      love.graphics.setColor(0.2,0.3,0.5,1)
      love.graphics.rectangle(
        'fill',
        drawX + 1,
        drawY + 1,
        size - 1,
        size - 1
      )
      love.graphics.setColor(0.6,0.6,0.6,1)
      love.graphics.print(
        row[x][1]..' '..row[x][2],
        drawX + 10,
        drawY + 10
      )

      -- arrow
      love.graphics.setColor(1,1,0.2)
      local direction = row[x]
      local isStartPoint = direction[1] == 0 and direction[2] == 0
      if not isStartPoint then
        local rot = arrowRotationFromDirection(direction)
        local offsetCenter = 8
        love.graphics.draw(
          arrow,
          drawX + 38,
          drawY + 43,
          rot,
          1,
          1,
          8,
          8
        )
      end
    end
  end
end

return groups.gui.createFactory(flowFieldTestBlueprint)