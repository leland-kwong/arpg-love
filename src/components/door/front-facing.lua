local Component = require 'modules.component'
local AnimationFactory = LiveReload 'components.animation-factory'
local Gui = require 'components.gui.gui'
local camera = require 'components.camera'
local Shaders = require 'modules.shaders'
local shader = Shaders('pixel-outline.fsh')
local Color = require 'modules.color'
local config = require 'config.config'
local O = require 'utils.object-utils'

local Door = {
  group = 'all',
  class = 'environment',
  init = function(self)
    local parent = self
    self.state = O.assign({
      opened = false,
      doorOpenComplete = false,
      dy = 0,
    }, self.state)
    Component.addToGroup(self, 'mapStateSerializers')
    Component.addToGroup(self, 'autoVisibility')

    local gfx = {
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
    self.gfx = gfx

    self.doorW, self.doorH = gfx.frontFacingCenter:getWidth(),
      gfx.frontFacingCenter:getHeight()

    local triggerCloseAnimation = function()
      local quad = gfx.frontFacingCenter.sprite
      local heightToShow = 16
      local doorH = self.doorH
      local originalY = parent.y
      Component.animate(parent.state, {
        dy = doorH - heightToShow
      }, 0.25, 'outCubic', nil, function()
        parent.state.doorOpenComplete = true
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
      getMousePosition = function(self)
        return camera:getMousePosition()
      end,
      onClick = function(self)
        if parent.state.opened then
          return
        end
        parent.state.opened = true
        triggerCloseAnimation()
      end,
      onUpdate = function(self, dt)
        self:setPosition(
          parent.x + parent.leftWallOffset,
          parent.y - centerYOffset
        )
        if parent.state.opened then
          self:delete(true)
        end
      end,
      render = function(self)
      end
    }):setParent(parent)

    self.frustrumCullingCollision = self:addCollisionObject('environment', 0, 0, 1, 1)
      :addToWorld('map')

    self.doorCollision = Component.create({
      group = 'all',
      init = function(self)
        self.c = self:addCollisionObject('obstacle', 0, 0, 1, 1)
          :addToWorld('map')
      end,
      update = function(self, dt)
        local x,y,w,h = parent.clickArea.x, parent.y, parent.clickArea.w, config.gridSize
        parent.frustrumCullingCollision:update(x,y,w,h)

        if parent.state.doorOpenComplete then
          self.c:delete()
        else
          self.c:update(x,y,w,h)
        end
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
    local doorLip = Component.create({
      group = 'all',
      draw = function(self)
        love.graphics.setColor(1,1,1)
        local x = parent.x + gfx.frontFacingLeftWall:getWidth() + gfx.frontFacingCenter:getWidth()/2
        gfx.frontFacingLip:draw(x, parent.y)
      end,
      drawOrder = function()
        return 1
      end
    }):setParent(parent)

    -- door center
    local doorCenter = Component.create({
      group = 'all',
      draw = function()
        if (not parent.isInViewOfPlayer) then
          return
        end

        local showOutline = self.clickArea.hovered and (not parent.state.opened)
        if (showOutline) then
          local atlasData = AnimationFactory.atlasData
          love.graphics.setShader(shader)
          shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
          shader:send('outline_width', 1)
          shader:send('outline_color', Color.WHITE)
        end

        love.graphics.setColor(1,1,1,1)
        local adjustForSpriteSheetPadding = parent.state.opened and (gfx.frontFacingCenter.pad) or 0
        gfx.frontFacingCenter:draw(parent.x + parent.leftWallOffset, parent.y + parent.state.dy - adjustForSpriteSheetPadding)

        shader:send('outline_width', 0)
      end,
      drawOrder = function()
        if parent.state.doorOpenComplete then
          return 1
        end
        return parent:drawOrder() + 1
      end
    }):setParent(parent)
  end,
  update = function(self)
    local children = Component.getChildren(self)
    for _,c in pairs(children) do
      c:setDrawDisabled(not self.isInViewOfPlayer)
    end
    self:setDrawDisabled(not self.isInViewOfPlayer)
  end,
  draw = function(self)
    local parent = self
    local actualH = (parent.doorH - parent.state.dy)
    self.gfx.frontFacingCenter:setSize(nil, actualH)

    parent.renderSideWalls()
    local lw = Component.get('lightWorld')
    lw:addLight(parent.x + parent.leftWallOffset + parent.doorW/2, parent.y, 20)
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self) + 1
  end,
  serialize = function(self)
    return O.assign({},
      self.initialProps,
      { state = self.state }
    )
  end
}

return Component.createFactory(Door)