local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local itemSystem = require 'components.item-inventory.items.item-system'
local collisionWorlds = require 'components.collision-worlds'
local calcDamage = require 'modules.abilities.calc-damage'
local cWorld = require 'components.collision-worlds'.map
local bump = require 'modules.bump'

local function triggerHit(self)
  local playerRef = Component.get('PLAYER')
  local distFromPlayer = 22
  local dx, dy = playerRef.facingDirectionX, playerRef.facingDirectionY
  local x, y = playerRef.x, playerRef.y
  local startAngle = math.atan2(dx, dy)
  local sideLength = distFromPlayer - 6

  self.hitPositions = {
    {
      x = x + dx * distFromPlayer,
      y = y + dy * distFromPlayer,
    },
    -- upper-half of crescent
    {
      x = x + sideLength * math.sin(startAngle + math.pi/4),
      y = y + sideLength * math.cos(startAngle + math.pi/4)
    },
    {
      x = x + (sideLength + 2) * math.sin(startAngle + math.pi/8),
      y = y + (sideLength + 2) * math.cos(startAngle + math.pi/8)
    },
    -- bottom-half of crescent
    {
      x = x + sideLength * math.sin(startAngle - math.pi/4),
      y = y + sideLength * math.cos(startAngle - math.pi/4)
    },
    {
      x = x + (sideLength + 2) * math.sin(startAngle - math.pi/8),
      y = y + (sideLength + 2) * math.cos(startAngle - math.pi/8)
    },
  }

  self.itemsHit = {}

  -- set hit states for collided rectangles
  for i=1, #self.hitPositions do
    local point = self.hitPositions[i]
    local collisionGroups = require 'modules.collision-groups'
    local cGroup = collisionGroups.create('enemyAi', 'environment')
    local items, len = cWorld:querySegment(x, y, point.x, point.y, function(item)
      if (not item.parent) then
        return
      end
      return collisionGroups.matches(item.group, cGroup)
    end)
    for i=1, len do
      local parent = items[i].parent
      local pid = parent:getId()
      local alreadyHit = self.itemsHit[pid]
      self.itemsHit[pid] = true
      if (not alreadyHit) then
        local msgBus = require 'components.msg-bus'
        msgBus.send(msgBus.CHARACTER_HIT, {
          parent = parent,
          damage = calcDamage(self),
          source = self:getId()
        })

        local ImpactAnimation = require 'components.abilities.effect-impact'
        ImpactAnimation.create({
          x = point.x,
          y = point.y
        })
      end
    end
  end
end

local Swipe = {}

function Swipe.init(self)
  Component.addToGroup(self, 'all')
  Component.removeFromGroup(
    Component.get('WEAPON_CORE'),
    'all'
  )

  local frames = {}
  local frameCount = 8
  for i=1, frameCount do
    table.insert(frames, 'ability-swipe-'..i)
  end
  self.animation = AnimationFactory:new(frames):setDuration(self.attackTime)

  local playerRef = Component.get('PLAYER')
  self.angle = (math.atan2(self.dx, self.dy) * -1) + (math.pi/2)

  local Sound = require 'components.sound'
  Sound.playEffect('whoosh-very-fast.wav')
end

function Swipe.update(self, dt)
  self.clock = (self.clock or 0) + dt
  self.animation:update(dt)

  local isHitFrame = self.animation.index == 4
  if isHitFrame and (not self.collisionChecked) then
    self.collisionChecked = true
    triggerHit(self)
  end

  if self.animation:isLastFrame() then
    self:delete(true)

    Component.addToGroup(
      Component.get('WEAPON_CORE'),
      'all'
    )
  end
end

function Swipe.draw(self)
  local ox, oy = self.animation:getOffset()
  local swipeHeight = 12
  local range = 10
  local hitX, hitY = self.x + (self.dx * range),
    self.y + (self.dy * range)
  love.graphics.setColor(1,1,1)
  love.graphics.draw(
    AnimationFactory.atlas,
    self.animation.sprite,
    hitX, hitY,
    self.angle,
    1,
    1,
    ox,oy
  )
end

function Swipe.drawOrder()
  return Component.get('PLAYER'):drawOrder() + 20
end

local SwipeFactory = Component.createFactory(Swipe)

return itemSystem.registerModule({
  name = 'swipe',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
	active = function(item, props)
    return {
			blueprint = SwipeFactory,
			props = props
    }
	end,
	tooltip = function(item, props)
		return {
			template = 'deals {damageRange} area of effect damage in front of the player',
			data = {
        damageRange = {
					type = 'range',
					from = {
						prop = 'minDamage',
						val = props.minDamage
					},
					to = {
						prop = 'maxDamage',
						val = props.maxDamage
					},
				}
      }
		}
	end
})

