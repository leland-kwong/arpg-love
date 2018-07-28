local memoize = require 'utils.memoize'
local abs = math.abs

local function Animation(frameJson, spriteAtlas, paddingOffset, frameRate)
  local pad = paddingOffset
  -- default to 60fps
  frameRate = frameRate == nil and 60 or frameRate

  local function createAnimation(aniFrames)
    local time = 0
    local maxFrames = #aniFrames
    local frameData = frameJson.frames
    local firstFrame = frameData[aniFrames[1]]
    local w = firstFrame.sourceSize.w
    local h = firstFrame.sourceSize.h
    local sprite = love.graphics.newQuad(0, 0, w + pad, h + pad, spriteAtlas:getDimensions())
    local index = 1 -- frame index
    local timePerFrame = 1 / frameRate
    local frame = frameData[aniFrames[index]]
    local animation = {}

    -- increments the animation by the time amount
    function animation.next(dt)
      if maxFrames > 1 then
        -- whether we should move forward or backward in the animation
        local direction = dt > 0 and 1 or -1
        if abs(time) >= timePerFrame then
          time = 0
          index = index + direction
          -- reset to the start
          if (index > maxFrames) then
            index = 1
          end
          -- reset to the end
          if (index < 1) then
            index = maxFrames
          end
        end
      end
      local frameKey = aniFrames[index]
      frame = frameData[frameKey]
      sprite:setViewport(frame.frame.x - pad/2, frame.frame.y - pad/2, frame.sourceSize.w + pad, frame.spriteSourceSize.h + pad)
      time = time + dt
      return sprite
    end

    -- sets the animation to the frame index and resets the time
    function animation.setFrame(i)
      index = i
      time = 0
      return animation
    end

    function animation.getOffset()
      local pivot = frame.pivot
      local x,y,w,h = sprite:getViewport()
      local ox = (pivot.x * w)
      local oy = (pivot.y * h)
      return ox, oy
    end

    return animation
  end

  return createAnimation
end

return Animation