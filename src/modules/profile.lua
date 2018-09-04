local Perf = require'utils.perf'

return function(fn)
  return Perf({
    done = function(_, totalTime, callCount)
      consoleLog(totalTime/callCount)
    end
  })(fn)
end