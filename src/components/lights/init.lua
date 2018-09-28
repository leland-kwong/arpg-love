local Component = require 'modules.component'
local groups = require 'components.groups'
local Light = require 'shadows.Light'
local config = require 'config.config'

local Light = {
  group = groups.all,
  radius = 400,
  x = 0,
  y = 0,
  lightWorld = 'DUNGEON_LIGHT_WORLD',
  init = function(self)
    local LightWorld = Component.get(self.lightWorld)
    self.light = Light:new(LightWorld.lightWorld, self.radius)
      :SetColor(255, 255, 255, 255)
  end,
  update = function(self)
    local camera = require 'components.camera'
    local w, h = camera.w, camera.h
    local scale = config.scale
    self.light:SetPosition(self.x * scale + w/scale, self.y * scale + h/scale)
  end,
  final = function(self)
    self.light:Remove()
  end
}

return Component.createFactory(Light)