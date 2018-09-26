local Component = require 'modules.component'
local collisionGroups = require 'modules.collision-groups'
local groups = require 'components.groups'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Font = require 'components.font'
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

local Portal = {
  group = groups.all,
  locationName = nil, -- name of location
  scene = nil, -- a scene component to load when clicked
  posOffset = {
    x = 2,
    y = -18
  },
  debug = true,
  init = function(self)
    self.x = self.x + self.posOffset.x
    self.y = self.y + self.posOffset.y

    self.spiralStencil = function()
      love.graphics.circle('fill', self.x, self.y, spiralSize)
    end
    local portalTooltipText = 'teleport to '..self.locationName
    local textWidth, textHeight = GuiText.getTextSize(portalTooltipText, Font.primary.font)
    local padding = 6
    self.teleportButton = Gui.create({
      type = Gui.types.BUTTON,
      group = groups.all,
      x = self.x,
      y = self.y - spiralSize,
      w = textWidth + padding,
      h = textHeight + padding,
      onClick = function()
        local msgBusMainMenu = require 'components.msg-bus-main-menu'
        local Scene = require 'scene.scene-main'
        msgBusMainMenu.send(
          msgBusMainMenu.SCENE_SWITCH, {
            scene = Scene
          }
        )
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
        guiText:add(portalTooltipText, Color.BLACK, self.x + paddingOffset, self.y + paddingOffset + Font.primary.lineHeight)
      end,
      drawOrder = guiDrawOrder
    }):setParent(self)
    local collisionSize = spiralSize
    local offset = collisionSize/2
    self.collision = self:addCollisionObject(
      collisionGroups.hotSpot,
      self.x - offset,
      self.y - offset + offset * 0.6,
      collisionSize,
      collisionSize
    ):addToWorld(collisionWorlds.map)
  end,
  update = function(self, dt)
    self.angle = self.angle + dt * 6
    local collisionSize = spiralSize * 2
    local _, _, cols, len = self.collision:check(
      self.collision.x,
      self.collision.y,
      portalCollisionFilter
    )
    local portalActionEnabled = len > 0
    self.teleportButton:setDisabled(not portalActionEnabled)
  end,
  draw = function(self)
    local scaleXDiff = 1 - scaleX
    local x, y = self.x, self.y
    local offset = {x = 50, y = 30}
    love.graphics.setColor(0,0.7,1,0.3)
    love.graphics.circle('fill', x, y, spiralSize)
    love.graphics.circle('fill', x, y, spiralSize * 0.8)
    love.graphics.circle('fill', x, y, spiralSize * 0.5)

    love.graphics.stencil(self.spiralStencil, 'replace', 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.setColor(1,1,1)
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