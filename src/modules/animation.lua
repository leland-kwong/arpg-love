local memoize = require 'utils.memoize'
local abs = math.abs

local function Animation(frameJson, spriteAtlas, paddingOffset, frameRate)
  -- default to 60fps
  frameRate = frameRate == nil and 60 or frameRate

  local function createAnimation(aniFrames)
    local time = 0
    local maxFrames = #aniFrames
    local frameData = frameJson.frames
    local firstFrame = frameData[aniFrames[1]]
    local w = firstFrame.sourceSize.w
    local h = firstFrame.sourceSize.h
    local sprite = love.graphics.newQuad(0, 0, w, h, spriteAtlas:getDimensions())
    local index = 1 -- frame index
    local timePerFrame = 1 / frameRate
    local animation = {}

    -- increments the animation by the time amount
    function animation.next(dt)
      -- whether we should move forward or backward in the animation
      local direction = dt > 0 and 1 or -1
      if abs(time) >= timePerFrame then
        time = 0
        index = index + direction
        -- reset to the start
        if (direction == 1) and (index > maxFrames) then
          index = 1
        end
        -- reset to the end
        if (direction == -1) and (index < 1) then
          index = maxFrames
        end
      end
      local frameKey = aniFrames[index]
      local frame = frameData[frameKey]
      -- readjust position if the height is less
      local offsetY = frame.sourceSize.h - frame.frame.h
      sprite:setViewport(frame.frame.x - paddingOffset, frame.frame.y - offsetY, frame.sourceSize.w + paddingOffset, frame.spriteSourceSize.h + paddingOffset)
      time = time + dt
      return sprite
    end

    -- sets the animation to the frame index and resets the time
    function animation.setFrame(i)
      index = i
      time = 0
      return animation
    end

    return animation
  end

  return createAnimation
end

return Animation