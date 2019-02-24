local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local Shaders = dynamicRequire 'modules.shaders'
local AnimationFactory = dynamicRequire 'components.animation-factory'
local F = require 'utils.functional'

local atlasData = AnimationFactory.atlasData
local shaderSpriteSize = {atlasData.meta.size.w, atlasData.meta.size.h}

local outlineShader = Shaders('pixel-outline.fsh')
local postProcessOutlines = love.graphics.newShader([[
  uniform vec4 colorToReplace = vec4(0,0,0,1);
  vec4 colorTransparent = vec4(0,0,0,0);

  vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
  {
    vec4 texColor = Texel(texture, texture_coords);
    return texColor == colorToReplace ? colorTransparent : texColor;
  }
]])

local slimeAnimation = AnimationFactory:new({
  'slime/slime12',
  'slime/slime13',
  'slime/slime14',
  'slime/slime15',
  'slime/slime16'
}):setDuration(1)

local function drawWithOptimization(self)
  love.graphics.setColor(1,1,1)
  outlineShader:send('outline_width', 0)
  for i=1, #self.sprites do
    local s = self.sprites[i]
    slimeAnimation:draw(s.x, s.y)
  end

  love.graphics.setShader(outlineShader)
  outlineShader:send('sprite_size', shaderSpriteSize)
  outlineShader:send('outline_only', true)
  outlineShader:send('outline_width', 1)
  love.graphics.setCanvas(self.outlinesCanvas)
  love.graphics.clear()
  for i=1, #self.sprites do
    local s = self.sprites[i]
    if s.outline then
      love.graphics.setColor(s.outlineColor)
    else
      love.graphics.setColor(1,1,1,0)
    end
    slimeAnimation:draw(s.x, s.y)
  end
  love.graphics.setShader()
  love.graphics.setCanvas()
  self.drawOutlines()
end

local function drawUnoptimized(self)
  love.graphics.setShader(outlineShader)
  outlineShader:send('sprite_size', shaderSpriteSize)
  outlineShader:send('outline_width', 1)
  love.graphics.setColor(1,1,1)
  F.forEach(self.sprites, function(s)
    outlineShader:send('outline_color', s.outlineColor or {1,1,1,0})
    slimeAnimation:draw(s.x, s.y)
  end)
end

Component.create({
  group = 'gui',
  id = 'ShaderOptimizationTest',

  init = function(self)
    self.sprites = {
      {
        x = 120,
        y = 40,
        outline = true,
        outlineColor = {1,1,0,1}
      },
      {
        x = 100,
        y = 50,
        outline = true,
        outlineColor = {0.2,0.6,1,1}
      },
      {
        x = 130,
        y = 52,
        outline = true,
        outlineColor = {0,1,1,0.5}
      },
      {
        x = 110,
        y = 60
      }
    }

    for i=1, 300 do
      table.insert(self.sprites, {
        x = math.random(130, 200),
        y = math.random(50, 350),
        outline= true,
        outlineColor = {0.5,0,1,0.8},
      })
    end

    self.outlinesCanvas = love.graphics.newCanvas(4096, 4096)
    self.drawOutlines = function()
      love.graphics.push()
      love.graphics.origin()
        love.graphics.setColor(1,1,1)
        love.graphics.setShader(postProcessOutlines)
        postProcessOutlines:send('colorToReplace', {0,0,0,1})
        love.graphics.draw(self.outlinesCanvas)
        love.graphics.setShader()
      love.graphics.pop()
    end
  end,

  update = function(self, dt)
    slimeAnimation:update(dt)
  end,

  draw = function(self)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.scale(2)

    drawWithOptimization(self)
    -- drawUnoptimized(self)

    love.graphics.pop()
  end
})