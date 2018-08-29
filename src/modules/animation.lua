--[[
  animation library for handling sprite atlas animations in Love2d
]]

local abs = math.abs

local meta = {}

local function createAnimationFactory(
  frameJson,
  spriteAtlas,
  paddingOffset,
  frameRate
)
  -- default to 60fps
  frameRate = frameRate == nil and 60 or frameRate

  local factory = {
    atlas = spriteAtlas,
    atlasData = frameJson,
    frameData = frameJson.frames,
    pad = paddingOffset,
    frameRate = frameRate
  }
  setmetatable(factory, meta)
  meta.__index = meta

  return factory
end

function meta:new(aniFrames)
  local animation = {
    maxFrames = #aniFrames,
    aniFrames = aniFrames,
    timePerFrame = 1 / self.frameRate,
    frame = nil,
    sprite = love.graphics.newQuad(0, 0, 0, 0, self.atlas:getDimensions()),
    time = 0, -- animation time
    index = 1 -- frame index
  }
  setmetatable(animation, self)
  self.__index = self

  -- set initial frame
  animation:update(0)
  return animation
end

local max = math.max
-- sets the animation to the frame index and resets the time
function meta:setFrame(index)
  self.index = i
  self.time = 0
  return self
end

-- returns the offset positions relative to the viewport including any padding.
-- This is useful for drawing operations since the padding allows for shader effects.
function meta:getOffset()
  local pivot = self.frame.pivot
  local w,h = self:getSourceSize()
  local pad = self.pad
  -- NOTE: add padding afterwards because its not part of the sprite pivot calculation
  local ox = (pivot.x * w) + pad
  local oy = (pivot.y * h) + pad
  return ox, oy
end

-- returns the offset positions relative to the original sprite sans padding.
-- This is useful for positioning other objects relative to the sprite.
function meta:getSourceOffset()
  local pivot = self.frame.pivot
  local w,h = self:getSourceSize()
  local ox = (pivot.x * w)
  local oy = (pivot.y * h)
  return ox, oy
end

-- returns the sprite source size
-- NOTE: this is different from sprite:getViewport() which includes padding
function meta:getSourceSize()
  return
    self.frame.sourceSize.w,
    self.frame.sourceSize.h
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

  self.time = self.time + dt
  local isSameFrame = self.index == self.lastIndex
  if isSameFrame then
    return self
  end

  local frameKey = self.aniFrames[self.index]
  self.frame = self.frameData[frameKey]
  local pad = self.pad
  self.sprite:setViewport(
    self.frame.frame.x - pad,
    self.frame.frame.y - pad,
    self.frame.sourceSize.w + (pad * 2),
    self.frame.spriteSourceSize.h + (pad * 2)
  )
  self.lastIndex = self.index
  local isLastFrame = frameKey == self.aniFrames[#self.aniFrames]
  return self, isLastFrame
end

function meta:getSpriteSize(spriteName, includePadding)
  local sourceSize = self.frameData[spriteName].sourceSize
  local padding = includePadding and (self.pad * 2) or 0
  return sourceSize.w + padding, sourceSize.h + padding
end

return createAnimationFactory