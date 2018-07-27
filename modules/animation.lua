local memoize = require 'utils.memoize'

-- returns a key/value pair of {animation name, animation coroutine}
local function Animation(frameJson, spriteAtlas)
  local function createAnimation(aniFrames)
    return memoize(function(fps)
      local frameRate = 60
      local maxFrames = #aniFrames
      local frameData = frameJson.frames
      local firstFrame = frameData[aniFrames[1]]
      local w = firstFrame.sourceSize.w
      local h = firstFrame.sourceSize.h
      local sprite = love.graphics.newQuad(0, 0, w, h, spriteAtlas:getDimensions())
      local co = function()
        local tick = 0
        local index = 1 -- frame index
        local every = frameRate / fps -- new index after every `x` ticks
        while true do
          if every == tick then
            tick = 0
            index = index + 1
            if index > maxFrames then
              index = 1
            end
          end
          local frameKey = aniFrames[index]
          local frame = frameData[frameKey]
          -- readjust position if the height is less
          local offsetY = frame.sourceSize.h - frame.frame.h
          sprite:setViewport(frame.frame.x, frame.frame.y - offsetY, frame.sourceSize.w, frame.sourceSize.h)
          coroutine.yield(sprite)
          tick = tick + 1
        end
      end
      return coroutine.wrap(co)
    end)
  end
  return createAnimation
end

return Animation