PROF_CAPTURE = false
local jprof = require('jprof')

local isFrameReady = false
local oPush = jprof.push
jprof.push = function(name, annotation)
  if (name == 'frame') then
    isFrameReady = true
  end
  if (not isFrameReady) then
    return
  end
  oPush(name, annotation)
end

local oPop = jprof.pop
jprof.pop = function(name)
  if isFrameReady then
    oPop(name)
  end

  if (name == 'frame') then
    isFrameReady = false
  end
end

return jprof