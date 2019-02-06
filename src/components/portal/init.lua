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
local function portalCollisionFilter(item, other)
  if collisionGroups.matches(other.group, collisionGroups.player) then
    return 'touch'
  end
  return false
end

local function guiDrawOrder(self)
  return 1000
end
GuiText.create({
  id = 'PortalTextLayer',
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
  class = 'portal',
  posOffset = {
    x = 0,
    z = 18
  },
  style = 1,
  color = {1,0.9,0},
  location = {
    tooltipText = 'no location'
  },
  -- debug = true,
  init = function(self)
    Component.addToGroup(self, 'gameWorld')

    local root = self
    self.x = self.x + self.posOffset.x
    self.z = self.z + self.posOffset.z

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
        if (not root.portalActionEnabled) then
          return
        end
        msgBus.send(msgBus.PORTAL_ENTER, root.location)
      end,
      onUpdate = function(self)
        local portalTooltipText = root.location.tooltipText
        local textWidth, textHeight = GuiText.getTextSize(portalTooltipText, Font.primary.font)
        self.w = textWidth + padding
        self.h = textHeight + padding
        self.portalTooltipText = portalTooltipText

        self:setDrawDisabled(not root.portalActionEnabled)
      end,
      getMousePosition = function()
        local camera = require 'components.camera'
        return camera:getMousePosition()
      end,
      draw = function(self)
        love.graphics.setColor(Color.multiplyAlpha(Color.BLACK, 0.8))
        local paddingOffset = padding/2
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
        Component.get('PortalTextLayer'):add(self.portalTooltipText, Color.WHITE, self.x + paddingOffset, self.y + paddingOffset + Font.primary.lineHeight)

        if self.hovered then
          love.graphics.setColor(1,1,1)
          love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
        end
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

    local PortalAnimation = require 'components.portal.animation'
    PortalAnimation.create({
      x = root.x,
      y = root.y,
      z = root.z,
      style = root.style,
      color = root.color
    }):setParent(root)
  end,
  update = function(self, dt)
    self.angle = self.angle + dt * 20
    local collisionSize = spiralSize * 2
    local _, _, cols, len = self.collision:check(
      self.collision.x,
      self.collision.y,
      portalCollisionFilter
    )
    self.portalActionEnabled = len > 0
    self.collision:update(self.x, self.y)
  end
}

function Portal.serialize(self)
  local Vec2 = require 'modules.brinevector'
  return {
    position = Vec2(self.x, self.y)
  }
end

return Component.createFactory(Portal)