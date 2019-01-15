local Component = require 'modules.component'
local dynamic = require 'utils.dynamic-require'
local slice9 = dynamic 'components.gui.utils.draw-box'

Component.create({
  id = 'slice-9',
  init = function(self)
    -- Component.addToGroup(self, 'gui')
  end,
  draw = function()
    local padding = 10

    love.graphics.push()
    love.graphics.origin()
    love.graphics.scale(2)

    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    love.graphics.rectangle('fill', 0, 0, 250, 200)

    local ok, err = pcall(function()
      slice9({
        x = 100,
        y = 60,
        w = 100,
        h = 100,
        padding = padding
      })
    end)

    if (not ok) then
      print(err)
    end

    -- content box
    love.graphics.setColor(1, 1, 0, 0.2)
    love.graphics.rectangle('fill', 100, 60, 100, 100)

    love.graphics.pop()
  end
})