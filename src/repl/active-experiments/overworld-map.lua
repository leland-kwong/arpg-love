local dynamicRequire = require 'utils.dynamic-require'
local drawBox = dynamicRequire 'components.gui.utils.draw-box'
local Component = require 'modules.component'
local AnimationFactory = dynamicRequire 'components.animation-factory'
local msgBus = require 'components.msg-bus'
local MenuManager = require 'modules.menu-manager'
local PlayerPositionIndicator = dynamicRequire 'components.hud.player-position-indicator'
local overworldMapDefinition = require 'built.maps.overworld-map'
local F = require 'utils.functional'
local Gui = require 'components.gui.gui'

print(
  string.format('%.0f', 124.254)
)

local function getTranslate(state)
  return state.translate.x + state.translate.dx,
    state.translate.y + state.translate.dy
end

local zonesLayer = F.find(overworldMapDefinition.layers, function(layer)
  return layer.name == 'zones'
end)

local function getNextPlayerPosition(self)
  local zoneData = F.find(zonesLayer.objects, function(zone)
    return zone.name == 'zone_home'
  end)
  local x, y = self.x - 1 + zoneData.x,
    self.y - 1 + zoneData.y
  local tx, ty = getTranslate(self.state)
  return x + tx, y + ty
end

local mask_shader = love.graphics.newShader[[
   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      float a = Texel(texture, texture_coords).a;
      if (a == 1.0 || a == 0.0) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }
]]

local AntiClickUnderlay = function()
  local camera = require 'components.camera'
  local w, h = camera:getSize()
  return Gui.create({
    id = 'AntiClickUnderlay',
    x = 0,
    y = 0,
    w = w,
    h = h
  })
end

local OverworldMap = Component.createFactory({
  group = 'hud',
  x = 50,
  y = 50,
  w = 1,
  h = 1,
  init = function(self)
    local parent = self

    self.state = {
      translate = {
        startX = 0,
        startY = 0,
        dx = 0,
        dy = 0,
        x = 0,
        y = 0
      },
    }

    msgBus.send(msgBus.TOGGLE_MAIN_MENU, false)
    MenuManager.clearAll()
    MenuManager.push(self)

    -- interact overlay
    Gui.create({
      id = 'OverworldMapInteract',
      onUpdate = function(self)
        self.x = parent.x
        self.y = parent.y
        self.w = parent.w
        self.h = parent.h
      end
    }):setParent(self)

    self.listeners = {
      msgBus.on(msgBus.MOUSE_DRAG, function(event)
        self.antiClickUnderlay = self.antiClickUnderlay or AntiClickUnderlay():setParent(self)

        local camera = require 'components.camera'
        -- panning
        local tx = self.state.translate
        tx.startX = event.startX/camera.scale
        tx.startY = event.startY/camera.scale
        tx.dx = math.floor(event.dx/camera.scale)
        tx.dy = math.floor(event.dy/camera.scale)
      end),

      msgBus.on(msgBus.MOUSE_DRAG_END, function(event)
        if self.antiClickUnderlay then
          self.antiClickUnderlay:delete(true)
          self.antiClickUnderlay = nil
        end

        local state = self.state
        state.movingNode = nil

        -- update tree translation
        local tx = state.translate
        tx.x, tx.y = tx.x + tx.dx, tx.y + tx.dy
        tx.startX = 0
        tx.startY = 0
        tx.dx = 0
        tx.dy = 0
      end),
    }

    self.stencil = function()
      love.graphics.setShader(mask_shader)
      drawBox(self, 'panelTranslucent')
      love.graphics.setShader()
    end
  end,
  update = function(self, dt)
    local camera = require 'components.camera'
    local w, h = camera:getSize()
    self.w = w - self.x*2
    self.h = h - self.y*2

    self.clock = (self.clock or 0) + dt
  end,
  draw = function(self)
    drawBox(self, 'panelTranslucent')

    love.graphics.stencil(self.stencil, 'replace', 1)
    love.graphics.setStencilTest('greater', 0)

    local tx, ty = getTranslate(self.state)
    local mapZone = AnimationFactory:newStaticSprite('gui-zone-1')
    mapZone:draw(
      self.x + 15 + tx,
      self.y + 15 + ty
    )

    local playerX, playerY = getNextPlayerPosition(self)
    PlayerPositionIndicator(
      playerX, playerY, self.clock
    )

    love.graphics.setStencilTest()
  end,
  drawOrder = function()
    return 9
  end,
  final = function(self)
    MenuManager.pop()
    msgBus.off(self.listeners)
  end
})

Component.create({
  id = 'OverworldMapInit',
  group = 'hud',
  init = function(self)
    self.listeners = {
      msgBus.on('MAP_TOGGLE', function()
        local ref = Component.get('OverworldMap')
        if ref then
          ref:delete(true)
        else
          OverworldMap.create({
            id = 'OverworldMap',
          })
        end
      end)
    }
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})