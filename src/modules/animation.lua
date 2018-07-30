--[[
  animation library for handling sprite atlas animations in Love2d
]]

local abs = math.abs

local function Animation(frameJson, spriteAtlas, paddingOffset, frameRate)
  local pad = paddingOffset
  -- default to 60fps
  frameRate = frameRate == nil and 60 or frameRate

  local meta = {}

  -- sets the animation to the frame index and resets the time
  function meta:setFrame(i)
    self.index = i
    self.time = 0
    return self
  end

  function meta:getOffset()
    local pivot = self.frame.pivot
    local x,y,w,h = self.sprite:getViewport()
    local ox = (pivot.x * w)
    local oy = (pivot.y * h)
    return ox, oy
  end

  function meta:getHeight()
    return self.frame.sourceSize.h
  end

  function meta:getWidth()
    return self.frame.sourceSize.w
  end

  -- increments the animation by the time amount
  function meta:update(dt)
    if self.maxFrames > 1 then
      -- whether we should move forward or backward in the animation
      local direction = dt > 0 and 1 or -1
      if abs(self.time) >= self.timePerFrame then
        self.time = 0
        self.index = self.index + direction
        -- reset to the start
        if (self.index > self.maxFrames) then
          self.index = 1
        end
        -- reset to the end
        if (self.index < 1) then
          self.index = self.maxFrames
        end
      end
    end
    local frameKey = self.aniFrames[self.index]
    self.frame = self.frameData[frameKey]
    self.sprite:setViewport(
      self.frame.frame.x - pad/2,
      self.frame.frame.y - pad/2,
      self.frame.sourceSize.w + pad/2,
      self.frame.spriteSourceSize.h + pad
    )
    self.time = self.time + dt
    return self
  end

  local function createAnimation(aniFrames)
    local frameData = frameJson.frames
    local firstFrame = frameData[aniFrames[1]]
    local w = firstFrame.sourceSize.w
    local h = firstFrame.sourceSize.h
    local sprite = love.graphics.newQuad(0, 0, w, h, spriteAtlas:getDimensions())
    local animation = {
      maxFrames = #aniFrames,
      aniFrames = aniFrames,
      timePerFrame = 1 / frameRate,
      frame = frameData[aniFrames[1]],
      frameData = frameData,
      sprite = sprite,
      time = 0, -- animation time
      index = 1 -- frame index
    }
    setmetatable(animation, meta)
    meta.__index = meta

    return animation
  end

  return createAnimation
end

return Animation