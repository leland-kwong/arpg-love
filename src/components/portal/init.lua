local Component = require 'modules.component'
local collisionGroups = require 'modules.collision-groups'
local groups = require 'components.groups'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Font = require 'components.font'
local msgBus = require 'components.msg-bus'
local collisionWorlds = require 'components.collision-worlds'
local loadImage = require 'modules.load-image'
local Color = require 'modules.color'

local spiralScale = 0.4
local spiralSize = 62 * spiralScale
local scaleX, scaleY = 0.8, 1
local function portalCollisionFilter(item, other)
  if collisionGroups.matches(other.group, collisionGroups.player) then
    return 'touch'
  end
  return false
end

local function guiDrawOrder(self)
  return 1000
end
local guiText = GuiText.create({
  font = Font.primary.font,
  group = groups.all,
  outline = false,
  drawOrder = function(self)
    return guiDrawOrder(self) + 1
  end
})

local function portalOpenSound()
  local source = love.audio.newSource('built/sounds/portal.wav', 'static')
  love.audio.play(source)
end

local function portalEnterSound()
  local source = love.audio.newSource('built/sounds/portal-enter.wav', 'static')
  love.audio.play(source)
end

local Portal = {
  group = groups.all,
  locationName = '', -- name of location
  posOffset = {
    x = 2,
    y = -18
  },
  -- debug = true,
  init = function(self)
    local root = self
    self.x = self.x + self.posOffset.x
    self.y = self.y + self.posOffset.y

    self.spiralStencil = function()
      love.graphics.circle('fill', self.x, self.y, spiralSize)
    end

    portalOpenSound()

    local padding = 6
    self.teleportButton = Gui.create({
      type = Gui.types.BUTTON,
      group = groups.all,
      x = self.x,
      y = self.y - spiralSize,
      w = 1,
      h = 1,
      onClick = function()
        portalEnterSound()
        msgBus.send(msgBus.PORTAL_ENTER)
      end,
      onUpdate = function(self)
        local portalTooltipText = 'teleport to '..(root.locationName or 'no location')
        local textWidth, textHeight = GuiText.getTextSize(portalTooltipText, Font.primary.font)
        self.w = textWidth + padding
        self.h = textHeight + padding
        self.portalTooltipText = portalTooltipText

        local hasChangedPosition = self.x ~= self.prevX or self.y ~= self.prevY
        if hasChangedPosition then
          portalOpenSound()
        end
        self.prevX, self.prevY = self.x, self.y
      end,
      getMousePosition = function()
        local camera = require 'components.camera'
        return camera:getMousePosition()
      end,
      draw = function(self)
        love.graphics.setColor(
          self.hovered and Color.YELLOW or Color.PRIMARY
        )
        local paddingOffset = padding/2
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
        love.graphics.setColor(Color.BLACK)
        love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
        guiText:add(self.portalTooltipText, Color.BLACK, self.x + paddingOffset, self.y + paddingOffset + Font.primary.lineHeight)
      end,
      drawOrder = guiDrawOrder
    }):setParent(self)
    local collisionSize = spiralSize
    local offset = collisionSize/2
    self.collision = self:addCollisionObject(
      collisionGroups.hotSpot,
      self.x,
      self.y,
      collisionSize,
      collisionSize,
      offset,
      offset - offset * 0.6
    ):addToWorld(collisionWorlds.map)
  end,
  update = function(self, dt)
    self.angle = self.angle + dt * 20
    local collisionSize = spiralSize * 2
    local _, _, cols, len = self.collision:check(
      self.collision.x,
      self.collision.y,
      portalCollisionFilter
    )
    local portalActionEnabled = len > 0
    self.teleportButton:setDisabled(not portalActionEnabled)
    self.collision:update(self.x, self.y)
  end,
  draw = function(self)
    local scaleXDiff = 1 - scaleX
    local x, y = self.x, self.y
    local offset = {x = 50, y = 30}
    love.graphics.setColor(0,0.7,1,0.3)
    love.graphics.circle('fill', x, y, spiralSize)
    love.graphics.circle('fill', x, y, spiralSize * 0.8)
    love.graphics.circle('fill', x, y, spiralSize * 0.5)
    love.graphics.setColor(0,0.3,0.5,0.3)
    love.graphics.circle('fill', x, y, spiralSize * 0.2)

    love.graphics.stencil(self.spiralStencil, 'replace', 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.setColor(1,1,1,0.3)
    local teleportSpiral = loadImage('built/images/fibonnaci-spiral.png')
    love.graphics.draw(
      teleportSpiral,
      x, y,
      self.angle,
      1, 1,
      offset.x,
      offset.y
    )
    love.graphics.setStencilTest()
  end,
  drawOrder = function(self)
    return self.group:drawOrder(self) + 1
  end
}

return Component.createFactory(Portal)