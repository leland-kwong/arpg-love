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
  update = function(self)
    local camera = require 'components.camera'
    local w, h = camera.w, camera.h
    local scale = config.scale
    local x, y = self.x, self.y
    local hasChangedPosition = x ~= self.prevX or y ~= self.prevY
    if self:checkOutOfBounds(self.radius) then
      if self.light then
        self.light:Remove()
      end
      self.light = nil
    else
      local LightWorld = Component.get(self.lightWorld)
      local isNewLight = not self.light
      self.light = self.light or
        Light:new(LightWorld.lightWorld, self.radius)
          :SetColor(255, 255, 255, 255)
      if isNewLight or hasChangedPosition then
        self.light:SetPosition(x * scale + w/scale, y * scale + h/scale)
      end
    end
    self.prevX, self.prevY = self.x, self.y
  end,
  final = function(self)
    if self.light then
      self.light:Remove()
    end
  end
}

return Component.createFactory(Light)