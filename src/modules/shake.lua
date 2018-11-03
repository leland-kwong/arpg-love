local socket = require 'socket'
local Shake = {}

math.randomseed(socket.gettime())

function Shake.__call(self, duration, frequency)
  -- The duration in miliseconds
  self.duration = duration

  -- The frequency in Hz
  self.frequency = frequency

  -- The sample count = number of peaks/valleys in the Shake
  local sampleCount = duration * frequency

  -- Populate the samples array with randomized values between -1.0 and 1.0
  self.samples = {}
  for i=1, sampleCount do
    table.insert(self.samples, math.random() * 2 - 1)
  end

  -- Init the time variables
  self.startTime = nil
  self.t = nil

  -- Flag that represents if the shake is active
  self.isShaking = false
  return self
end

function Shake:start()
  self.t = 0
  self.isShaking = true
end

--[[
  Update the shake, setting the current time variable
]]
function Shake:update(dt)
  self.t = self.t + dt
  if(self.t > self.duration) then
    self.isShaking = false
  end
end

--[[
  Retrieve the amplitude. If "t" is passed, it will get the amplitude for the
  specified time, otherwise it will use the internal time.
  @param {int} t (optional) The time since the start of the shake in miliseconds
 ]]
 function Shake:amplitude(t)
  -- Check if optional param was passed
  if(t == nil) then
    -- return zero if we are done shaking
    if(not self.isShaking) then
      return 0
    end
    t = self.t
  end

  -- Get the previous and next sample
  local s = (t * self.frequency) + 1
  local s0 = math.floor(s)
  local s1 = s0 + 1

  -- Get the current decay
  local k = self:decay(t)

  -- Return the current amplitide
  return (self:noise(s0) + (s - s0)*(self:noise(s1) - self:noise(s0))) * k
 end

--[[
  Retrieve the noise at the specified sample.
  @param {int} s The randomized sample we are interested in.
]]
function Shake:noise(s)
  -- Retrieve the randomized value from the samples
  if(s >= #self.samples) then
    return 0
  end
  return self.samples[s]
end

--[[
  Get the decay of the shake as a floating point value from 0.0 to 1.0
  @param {int} t The time since the start of the shake in miliseconds
]]
function Shake:decay(t)
  -- Linear decay
  if(t >= self.duration) then
    return 0
  end
  return (self.duration - t) / self.duration
end

setmetatable(Shake, Shake)

return Shake