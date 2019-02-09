local Component = require 'modules.component'
local AnimationFactory = LiveReload 'components.animation-factory'
local Gui = require 'components.gui.gui'
local camera = require 'components.camera'
local Shaders = require 'modules.shaders'
local shader = Shaders('pixel-outline.fsh')
local Color = require 'modules.color'
local config = require 'config.config'

local Door = {
  dy = 0,
  doorOpenComplete = false,
  init = function(self)
    local parent = self
    gfx = {
      frontFacingLeftWall = AnimationFactory:newStaticSprite(
        'door-1-front-facing-left-wall'
      ),
      frontFacingCenter = AnimationFactory:new({
        'door-1-front-facing-center'
      }),
      frontFacingRightWall = AnimationFactory:newStaticSprite(
        'door-1-front-facing-right-wall'
      ),
      frontFacingLip = AnimationFactory:newStaticSprite(
        'door-1-front-facing-lip'
      )
    }

    self.doorW, self.doorH = gfx.frontFacingCenter:getWidth(),
      gfx.frontFacingCenter:getHeight()

    local triggerCloseAnimation = function()
      local quad = gfx.frontFacingCenter.sprite
      local heightToShow = 16
      local doorH = self.doorH
      local originalY = parent.y
      Component.animate(parent, {
        dy = doorH - heightToShow
      }, 0.25, 'outCubic', function(dt)
        local actualH = (doorH - parent.dy)
        gfx.frontFacingCenter:setSize(nil, actualH)
      end, function()
        parent.doorCollision:delete()
        parent.doorOpenComplete = true
      end)
    end

    local scale = camera.scale

    self.renderSideWalls = function()
      love.graphics.setColor(1,1,1,1)
      gfx.frontFacingLeftWall:draw(self.x, self.y)
      gfx.frontFacingRightWall:draw(self.x + self.doorW + gfx.frontFacingRightWall:getWidth(), self.y)
    end

    self.leftWallOffset = gfx.frontFacingLeftWall:getWidth()
    local _, centerYOffset = gfx.frontFacingCenter:getSourceOffset()
    self.clickArea = Gui.create({
      group = 'all',
      -- debug = true,
      w = self.doorW,
      h = self.doorH,
      opened = false,
      getMousePosition = function(self)
        return camera:getMousePosition()
      end,
      onClick = function(self)
        self.opened = true
        triggerCloseAnimation()
        self:delete(true)
      end,
      onUpdate = function(self, dt)
        self:setPosition(
          parent.x + parent.leftWallOffset,
          parent.y - centerYOffset
        )
      end,
      render = function(self)
      end
    }):setParent(parent)

    self.doorCollision = Component.create({
      group = 'all',
      init = function(self)
        self.c = self:addCollisionObject('obstacle', 0, 0, 1, 1)
          :addToWorld('map')
      end,
      update = function(self, dt)
        self.c:update(
          parent.clickArea.x, parent.y, parent.clickArea.w, config.gridSize
        )
      end
    }):setParent(self)
    self.wallCollisionLeft = self:addCollisionObject(
      'obstacle',
      self.x,
      self.y,
      gfx.frontFacingLeftWall:getWidth(),
      config.gridSize
    ):addToWorld('map')

    self.wallCollisionRight = self:addCollisionObject(
      'obstacle',
      self.x + parent.doorW + gfx.frontFacingLeftWall:getWidth(),
      self.y,
      gfx.frontFacingLeftWall:getWidth(),
      config.gridSize
    ):addToWorld('map')

    -- door lip
    Component.create({
      group = 'all',
      draw = function(self)
        love.graphics.setColor(1,1,1)
        local x = parent.x + gfx.frontFacingLeftWall:getWidth() + gfx.frontFacingCenter:getWidth()/2
        gfx.frontFacingLip:draw(x, parent.y)
      end,
      drawOrder = function()
        return 2
      end
    }):setParent(parent)

    -- door center
    Component.create({
      group = 'all',
      draw = function()
        local showOutline = self.clickArea.hovered and (not self.clickArea.opened)
        if (showOutline) then
          local atlasData = AnimationFactory.atlasData
          love.graphics.setShader(shader)
          shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
          shader:send('outline_width', 1)
          shader:send('outline_color', Color.WHITE)
        end

        love.graphics.setColor(1,1,1,1)
        local adjustForSpriteSheetPadding = self.clickArea.opened and (gfx.frontFacingCenter.pad) or 0
        gfx.frontFacingCenter:draw(parent.x + parent.leftWallOffset, parent.y + parent.dy - adjustForSpriteSheetPadding)

        shader:send('outline_width', 0)
      end,
      drawOrder = function()
        if parent.doorOpenComplete then
          return 2
        end
        return parent:drawOrder() + 1
      end
    }):setParent(parent)
  end,
  draw = function(self)
    local parent = self
    parent.renderSideWalls()
    local lw = Component.get('lightWorld')
    lw:addLight(parent.x + parent.leftWallOffset + parent.doorW/2, parent.y, 20)
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self)
  end
}

local Factory = Component.createFactory(Door)

Factory.create({
  id = 'DoorPrototype',
  group = 'all',
  x = 15 * 16,
  y = 6 * 16
})