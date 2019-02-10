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
  opacity = 1,
  group = 'all',
  class = 'environment',
  -- debug = true,
  init = function(self)
    local parent = self
    self.state = O.assign({
      opened = false,
      doorOpenComplete = false,
      dy = 0,
      percentOpened = 0,
    }, self.state)
    Component.addToGroup(self, 'mapStateSerializers')
    Component.addToGroup(self, 'autoVisibility')

    local gfx = {
      sideFacingLeftWall = AnimationFactory:newStaticSprite(
        'door-1-side-facing-top-wall'
      ),
      sideFacingCenter = AnimationFactory:new({
        'door-1-side-facing-center'
      }),
      sideFacingRightWall = AnimationFactory:newStaticSprite(
        'door-1-side-facing-bottom-wall'
      ),
      sideFacingLip = AnimationFactory:newStaticSprite(
        'door-1-side-facing-lip'
      )
    }
    self.gfx = gfx

    self.doorW, self.doorH = gfx.sideFacingCenter:getWidth(),
      gfx.sideFacingCenter:getHeight()

    local triggerOpenAnimation = function()
      local quad = gfx.sideFacingCenter.sprite
      local doorH = self.doorH
      local originalY = parent.y
      local Sound = require 'components.sound'
      Sound.playEffect('door-open.wav')
      Component.animate(parent.state, {
        dy = 26,
        percentOpened = 1
      }, 0.25, 'outCubic', nil, function()
        parent.state.doorOpenComplete = true
      end)
    end

    local scale = camera.scale
    self.leftWallOffset = config.gridSize

    self.renderSideWalls = function()
      love.graphics.setColor(1,1,1,self.opacity)
      gfx.sideFacingLeftWall:draw(self.x, self.y)
    end

    local _, centerYOffset = gfx.sideFacingCenter:getSourceOffset()
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
        if parent.state.opened then
          return
        end
        parent.state.opened = true
        triggerOpenAnimation()
      end,
      onUpdate = function(self, dt)
        self:setPosition(
          parent.x - 1,
          parent.y - 10
        )
        if parent.state.opened then
          self:delete(true)
        end
      end
    }):setParent(parent)

    self.frustrumCullingCollision = self:addCollisionObject('environment', 0, 0, 1, 1)
      :addToWorld('map')
    self.doorCollision = Component.create({
      group = 'all',
      -- debug = true,
      init = function(self)
        self.c = self:addCollisionObject('obstacle', 0, 0, 1, 1)
          :addToWorld('map')
      end,
      update = function(self, dt)
        local x,y,w,h = parent.x, parent.y, config.gridSize, parent.clickArea.h
        parent.frustrumCullingCollision:update(x,y,w,h)

        if parent.state.doorOpenComplete then
          self.c:delete()
        else
          self.c:update(x,y,w,h)
        end
      end,
      drawOrder = function()
        return math.pow(100, 100)
      end
    }):setParent(self)
    self.wallCollisionLeft = self:addCollisionObject(
      'obstacle',
      self.x,
      self.y,
      config.gridSize,
      config.gridSize
    ):addToWorld('map')

    self.wallCollisionRight = self:addCollisionObject(
      'obstacle',
      self.x,
      self.y + config.gridSize * 5,
      config.gridSize,
      config.gridSize
    ):addToWorld('map')

    -- door lip
    Component.create({
      group = 'all',
      draw = function(self)
        love.graphics.setColor(1,1,1)
        local x = parent.x
        local y = parent.y + parent.leftWallOffset + (config.gridSize * 2)
        gfx.sideFacingLip:draw(x, y)
      end,
      drawOrder = function()
        return 1
      end
    }):setParent(parent)

    -- door center
    Component.create({
      group = 'all',
      draw = function()
        local showOutline = self.clickArea.hovered and (not parent.state.opened)
        if (showOutline) then
          local atlasData = AnimationFactory.atlasData
          love.graphics.setShader(shader)
          shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
          shader:send('outline_width', 1)
          shader:send('outline_color', Color.WHITE)
        end

        love.graphics.setColor(1,1,1,self.opacity)
        local adjustForSpriteSheetPadding = 0
        gfx.sideFacingCenter:draw(parent.x, parent.y + parent.leftWallOffset + parent.state.dy - adjustForSpriteSheetPadding)

        shader:send('outline_width', 0)
      end,
      drawOrder = function()
        if parent.doorOpenComplete then
          return 1
        end
        return parent:drawOrder() + 1
      end
    }):setParent(parent)

    -- bottom wall
    Component.create({
      x = parent.x,
      y = parent.y + parent.leftWallOffset + (config.gridSize * 4),
      group = 'all',
      draw = function(self)
        love.graphics.setColor(1,1,1,parent.opacity)
        gfx.sideFacingRightWall:draw(self.x, self.y)
      end,
      drawOrder = function(self)
        return Component.groups.all:drawOrder(self) + 1
      end
    }):setParent(self)
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
    self.gfx.sideFacingCenter:setSize(nil, actualH)

    parent.renderSideWalls()
    local lw = Component.get('lightWorld')
    local lightRadius = 20
    lw:addLight(
      parent.x + config.gridSize/2,
      parent.y + parent.state.dy + (config.gridSize * 2) - (5 + (10 * parent.state.percentOpened)),
      lightRadius
    )
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