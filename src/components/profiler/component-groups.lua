local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local Color = require 'modules.color'

local guiTextLayer = GuiText.create({
  font = require'components.font'.primary.font,
  outline = false
})

return function(console)
  local i = 0
  local yStart = 210

  for k,v in pairs(groups) do
    i = i + 1
    local y1 = i

    local originalUpdateAll = groups[k].updateAll
    local totalTimeUpdate = 0
    local framesUpdate = 0
    groups[k].updateAll = require'utils.perf'({
      done = function(t)
        totalTimeUpdate = totalTimeUpdate + t
        framesUpdate = framesUpdate + 1
        local averageTime = totalTimeUpdate / framesUpdate
        guiTextLayer:add(k..' update:'..averageTime, Color.WHITE, 5, y1 * 10 + yStart)
      end
    })(originalUpdateAll)

    i = i + 1
    local y2 = i
    local totalTimeDraw = 0
    local framesDraw = 0
    local originalDrawAll = groups[k].drawAll
    groups[k].drawAll = require'utils.perf'({
      done = function(t)
        totalTimeDraw = totalTimeDraw + t
        framesDraw = framesDraw + 1
        local averageTime = totalTimeDraw / framesDraw
        guiTextLayer:add(k..' draw:'..averageTime, Color.WHITE, 5, y2 * 10 + yStart)
      end
    })(originalDrawAll)
  end
end