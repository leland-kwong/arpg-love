local dynamicRequire = require 'utils.dynamic-require'
local drawBox = require 'components.gui.utils.draw-box'
local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local msgBus = require 'components.msg-bus'
local MenuManager = require 'modules.menu-manager'
local PlayerPositionIndicator = require 'components.hud.player-position-indicator'
local overworldMapDefinition = dynamicRequire 'built.maps.overworld-map'
local F = require 'utils.functional'
local Gui = require 'components.gui.gui'

local function getTranslate(state)
  return state.translate.x + state.translate.dx,
    state.translate.y + state.translate.dy
end

local function handleZoom(ev, state)
  local dy = ev[2]
  local clamp = require 'utils.math'.clamp
  state.nextScale = clamp(state.nextScale + dy, 1, 5)
end

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

local function handlePanning(self, event)
  self.antiClickUnderlay = self.antiClickUnderlay or AntiClickUnderlay():setParent(self)

  -- panning
  local tx = self.state.translate
  local scale = self.state.scale
  tx.startX = event.startX/scale
  tx.startY = event.startY/scale
  tx.dx = math.floor(event.dx/scale)
  tx.dy = math.floor(event.dy/scale)
end

local function handlePanningEnd(self, event)
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
end

local zonesLayer = F.find(overworldMapDefinition.layers, function(layer)
  return layer.name == 'zones'
end)

local function getNextPlayerPosition(self)
  local playerRef = Component.get('PLAYER')
  if playerRef then
    return playerRef.x, playerRef.y
  end

  return 0,0
  -- local zoneData = F.find(zonesLayer.objects, function(zone)
  --   return zone.name == 'zone_1_1'
  -- end)
  -- local x, y = self.x + zoneData.x,
  --   self.y + zoneData.y
  -- return x, y
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

local OverworldMap = Component.createFactory({
  group = 'hud',
  x = 50,
  y = 50,
  w = 1,
  h = 1,
  init = function(self)
    local parent = self

    local playerX, playerY = getNextPlayerPosition(self)
    local camera = require 'components.camera'
    local w,h = camera:getSize()
    self.state = {
      translate = {
        startX = 0,
        startY = 0,
        dx = 0,
        dy = 0,
        x = w/2 - playerX/16,
        y = h/2 - playerY/16
      },
      scale = 1,
      nextScale = 2
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
        handlePanning(self, event)
      end),

      msgBus.on(msgBus.MOUSE_DRAG_END, function(event)
        handlePanningEnd(self, ev)
      end),

      msgBus.on('MOUSE_WHEEL_MOVED', function(ev)
        handleZoom(ev, self.state)
      end)
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

    if self.state.scale ~= self.state.nextScale then
      local clamp = require 'utils.math'.clamp
      local ds = clamp(self.state.scale - self.state.nextScale, -1, 1) * -1
      self.state.scale = self.state.scale + (0.25 * ds)
    end
  end,
  draw = function(self)
    drawBox(self, 'panelTranslucent')

    local tx, ty = getTranslate(self.state)
    local scale = self.state.scale
    local scaleDiff = math.max(0, scale - 1)/scale

    love.graphics.stencil(self.stencil, 'replace', 1)
    love.graphics.setStencilTest('greater', 0)

    love.graphics.push()
    love.graphics.origin()

      local camera = require 'components.camera'
      local w,h = camera:getSize()
      local centerX, centerY = w/2, h/2
      -- translate to center of screen before zooming
      love.graphics.translate(centerX, centerY)
      love.graphics.scale(scale)
      -- move translation back to origin before doing final translation
      love.graphics.translate(-centerX * scaleDiff, -centerY * scaleDiff)
      -- move to final translation
      love.graphics.translate(tx, ty)

      local minimapRef = Component.get('miniMap')
      local gridSize = 16
      if minimapRef then
        local camera = require 'components.camera'
        local cameraX, cameraY  = camera:getPosition()
        local tx, ty = centerX - cameraX/gridSize, centerY - cameraY/gridSize
        love.graphics.setColor(1,1,1)
        love.graphics.draw(minimapRef.canvas, 0, 0)
        love.graphics.draw(minimapRef.dynamicBlocksCanvas, 0, 0)
      end

      local playerX, playerY = getNextPlayerPosition(self)
      PlayerPositionIndicator(
        playerX/gridSize, playerY/gridSize, self.clock
      )

    love.graphics.pop()
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