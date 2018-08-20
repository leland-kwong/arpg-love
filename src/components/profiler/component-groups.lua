local groups = require 'components.groups'

return function(console)
  for k,v in pairs(groups) do
    local originalUpdateAll = groups[k].updateAll
    local totalTimeUpdate = 0
    local framesUpdate = 0
    groups[k].updateAll = require'utils.perf'({
      done = function(t)
        totalTimeUpdate = totalTimeUpdate + t
        framesUpdate = framesUpdate + 1
        local averageTime = totalTimeUpdate / framesUpdate
        console:debug(k..' update: '..averageTime)
      end
    })(originalUpdateAll)

    local totalTimeDraw = 0
    local framesDraw = 0
    local originalDrawAll = groups[k].drawAll
    groups[k].drawAll = require'utils.perf'({
      done = function(t)
        totalTimeDraw = totalTimeDraw + t
        framesDraw = framesDraw + 1
        local averageTime = totalTimeDraw / framesDraw
        console:debug(k..' draw: '..averageTime)
      end
    })(originalDrawAll)
  end
end