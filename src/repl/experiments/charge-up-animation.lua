local AnimationFactory = LiveReload 'components.animation-factory'
local Component = require 'modules.component'
local camera = require 'components.camera'

local hueShiftShader = [[
  // https://gamedev.stackexchange.com/questions/59797/glsl-shader-change-hue-saturation-brightness/59879

  uniform float hueAdjustAngle = 1.0;
  uniform float brightness = 1.0;

  vec3 rgb2hsv(vec3 c)
  {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
  }

  vec3 hsv2rgb(vec3 c)
  {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
  }

  vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
    vec4 textureColor = texture2D(texture, texture_coords);
    vec3 fragRGB = textureColor.rgb;
    vec3 fragHSV = rgb2hsv(fragRGB).xyz;
    fragHSV.x += color.x / hueAdjustAngle;
    fragHSV.yz *= color.yz;
    fragHSV.xyz = mod(fragHSV.xyz, brightness * 10.0);
    fragRGB = hsv2rgb(fragHSV);
    return vec4(fragRGB, textureColor.w);
  }
]]
local shader = love.graphics.newShader(hueShiftShader)

local ChargeUpAnimation = Component.createFactory({
  group = 'all',
  color = {1,1,0},
  scale = 1,
  x = 0,
  y = 0,
  duration = 1,
  clock = 0,
  hueAdjust = 1,
  init = function(self)
    local frames = {}
    for i=0, 106 do
      table.insert(frames, string.format('charging/charging_%d', i))
    end
    self.animation = AnimationFactory:new(frames)
      :setDuration(self.duration)
  end,
  update = function(self, dt)
    self.clock = self.clock + dt
    if self.clock >= self.duration then
      -- self.animation:setFrame(100)
      -- self:delete(true)
      self.clock = 0
    end
    self.animation:update(dt)
  end,
  draw = function(self)
    local oShader = love.graphics.getShader()
    love.graphics.setShader(shader)
    shader:send('hueAdjustAngle', self.hueAdjust)
    -- shader:send('brightness', 1)

    love.graphics.setColor(1,1,1)
    love.graphics.push()
    love.graphics.scale(self.scale)
    local scaleDiff = (1 - self.scale)/self.scale
    love.graphics.translate(self.x * scaleDiff, self.y * scaleDiff)
    local oBlend = love.graphics.getBlendMode()
    love.graphics.setBlendMode('add')
    self.animation:draw(self.x, self.y)
    love.graphics.setBlendMode(oBlend)
    love.graphics.pop()

    love.graphics.setShader(oShader)
  end
})

for _,c in pairs(Component.groups.testComponents.getAll()) do
  c:delete(true)
end

-- for i=1, 30 do
--   local animation = ChargeUpAnimation.create({
--     -- x = 0,
--     -- y = 0,
--     x = math.random(-10, 10) * 20,
--     y = math.random(-7, 7) * 20,
--     hueAdjust = math.random(-30, 30)/10,
--     drawOrder = function()
--       return i
--     end
--   })
--   Component.addToGroup(animation, 'testComponents')
-- end

return ChargeUpAnimation