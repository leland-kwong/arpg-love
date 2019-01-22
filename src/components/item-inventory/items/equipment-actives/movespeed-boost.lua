local Component = require 'modules.component'
local itemSystem =require("components.item-inventory.items.item-system")
local msgBus = require 'components.msg-bus'
local Sound = require 'components.sound'
local Color = require('modules.color')
local Vec2 = require 'modules.brinevector'

local speedBoostSoundFilter = {
  type = 'lowpass',
  volume = .5,
}

local VECTOR_ZERO = Vec2()

local Shaders = require 'modules.shaders'
local shader = Shaders('pixel-outline.fsh')
local animationFactory = require 'components.animation-factory'
local atlasData = animationFactory.atlasData
local shaderSpriteSize = {atlasData.meta.size.w, atlasData.meta.size.h}

return itemSystem.registerModule({
  name = 'movespeed-boost',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item, props)
    local playerRef = Component.get('PLAYER')
    if playerRef then
      Sound.playEffect('dash.wav')
      local magnitude = Vec2(
        playerRef.moveDirectionX * props.distance,
        playerRef.moveDirectionY * props.distance
      )
      if magnitude == VECTOR_ZERO then
        magnitude = Vec2(
          playerRef.facingDirectionX * props.distance,
          playerRef.facingDirectionY * props.distance
        )
      end

      local imageDrawOrder = playerRef:drawOrder()
      Component.create({
        imageDuration = 0.5,
        init = function(self)
          Component.addToGroup(self, 'all')
          self.lifetime = props.duration
          self.images = {}
        end,
        update = function(self, dt)
          self.lifetime = self.lifetime - dt
          local shouldMakeImages = self.lifetime > 0
          if shouldMakeImages then
            local colorChange = (#self.images * 40)
            local color = {Color.rgba255(244 - colorChange, 244, 65)}

            local ox, oy = playerRef.animation:getSourceOffset()
            table.insert(self.images, {
              position = Vec2(playerRef.x, playerRef.y),
              sprite = playerRef.animation.sprite,
              ox = ox,
              oy = oy,
              lifetime = self.imageDuration,
              color = color
            })
          end

          local i = 1
          while (i <= #self.images) do
            local image = self.images[i]
            image.lifetime = image.lifetime - dt * 2
            if (image.lifetime <= 0) then
              table.remove(self.images, i)
            else
              i = i + 1
            end
          end

          local complete = #self.images == 0
          if complete then
            self:delete()
          end
        end,
        draw = function(self)
          love.graphics.setShader(shader)
          shader:send('pure_color', true)
          for i=1, #self.images do
            local image = self.images[i]
            local opacity = image.lifetime / self.imageDuration
            love.graphics.setColor(
              Color.multiplyAlpha(image.color, opacity)
            )
            love.graphics.draw(
              animationFactory.atlas,
              image.sprite,
              image.position.x,
              image.position.y,
              0,
              playerRef.facingDirectionX > 0 and 1 or -1,
              1,
              image.ox,
              image.oy
            )
          end
          shader:send('pure_color', false)
        end,
        drawOrder = function(self)
          return imageDrawOrder
        end
      })

      Component.addToGroup('dash-force', 'gravForce', {
        magnitude = magnitude,
        actsOn = 'PLAYER',
        duration = props.duration
      })
    end
  end,
  tooltip = function(item, props)
    return {
      template = 'Quickly dashes in the direction that your are moving or facing',
      data = props
    }
  end
})