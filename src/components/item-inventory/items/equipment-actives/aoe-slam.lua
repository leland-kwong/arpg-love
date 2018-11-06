local Component = require 'modules.component'
local Color = require 'modules.color'
local groups = require 'components.groups'
local functional = require 'utils.functional'
local msgBus = require 'components.msg-bus'
local AbilityBase = require 'components.abilities.base-class'
local tween = require 'modules.tween'
local collisionGroups = require 'modules.collision-groups'
local config = require 'config.config'
local filter = require 'utils.filter-call'
local itemSystem = require(require('alias').path.itemSystem)
local calcDamage = require 'modules.abilities.calc-damage'

local bump = require 'modules.bump'
local hammerWorld = bump.newWorld(4)
local hitModifers = {
	armor = -200
}
local attackTime = 0.3
local attackCooldown = 0
local hitModifierDuration = attackTime * 1.2

local function triggerAttack(self)
	local Position = require 'utils.position'
	local dx, dy = Position.getDirection(self.x, self.y, self.x2, self.y2)
	self.dx, self.dy = dx, dy
	local attackPosX, attackPosY = 30 * dx, 30 * dy
	self.collisionX, self.collisionY = self.x - (self.w/2) + attackPosX, self.y - (self.h/2) + attackPosY
	self.collisionW, self.collisionH = self.w, self.h
	local cw = require 'components.collision-worlds'.map
	cw:queryRect(
		self.collisionX,
		self.collisionY,
		self.collisionW,
		self.collisionH,
		function(item)
			if (collisionGroups.matches(item.group, collisionGroups.create(collisionGroups.enemyAi, collisionGroups.environment))) then
				local aiCollision = item
				local aiCollisionX, aiCollisionY = aiCollision:getPositionWithOffset()
				hammerWorld:add(
					item.parent,
					aiCollisionX,
					aiCollisionY,
					aiCollision.w,
					aiCollision.h
				)
				return true
			end
		end
	)
	hammerWorld:queryRect(
		self.collisionX,
		self.collisionY,
		self.collisionW,
		self.collisionH,
		function(item)
			msgBus.send(msgBus.CHARACTER_HIT, {
				parent = item,
				damage = calcDamage(self),
				source = self:getId()
			})
			-- attack modifier
			msgBus.send(msgBus.CHARACTER_HIT, {
				parent = item,
				duration = hitModifierDuration,
				modifiers = hitModifers,
				source = 'HAMMER_MODIFIER_EFFECT'
			})
		end
	)

	local itemsAddedToWorld, len = hammerWorld:getItems()
	for i=1, len do
		hammerWorld:remove(itemsAddedToWorld[i])
	end
end

local WeaponAnimation = Component.createFactory({
	init = function(self)
		Component.addToGroup(self, 'all')
		Component.removeFromGroup(
			Component.get('WEAPON_CORE'),
			'all'
		)
	end,
	drawSprite = function(color, x, y, angle, facingX)
		local AnimationFactory = require 'components.animation-factory'
		local animation = AnimationFactory:newStaticSprite('companion/companion')
		local ox, oy = animation:getOffset()
		love.graphics.setColor(color)
		love.graphics.draw(
			AnimationFactory.atlas,
			animation.sprite,
			x,
			y,
			angle or 0,
			1 * facingX,
			1,
			ox,oy
		)
	end,
	draw = function(self)
		local playerRef = Component.get('PLAYER')
		local x, y = playerRef.x + (playerRef.facingDirectionX * 15), playerRef.y
		local facingX = playerRef.facingDirectionX > 0 and 1 or -1

		self.drawSprite({
			1,1,1,0.2
		}, x, y - 30, 0, facingX)

		self.drawSprite({
			1,1,1,0.4
		}, x, y - 20, 0, facingX)

		self.drawSprite({
			1,1,1,1
		}, x, y + 5, 0, facingX)
	end
})

local Attack = Component.createFactory(
	AbilityBase({
		group = groups.all,
		w = 1,
		h = 1,
		impactAnimationDuration = 0.4,
		cooldown = attackCooldown,
		opacity = 1,
		init = function(self)
			self.animationTween = tween.new(self.impactAnimationDuration, self, { opacity = 0 }, tween.easing.inExpo)
			WeaponAnimation.create()
		end,
		update = function(self, dt)
			-- we must trigger after init since the attack gets modified immediately upon creation
			if (not self.triggered) then
				triggerAttack(self)
				self.triggered = true
			end
			local complete = self.animationTween:update(dt)
			if complete then
				self:delete()
			end
		end,
		draw = function(self)
			love.graphics.setColor(
				Color.rgba255(244, 177, 70, 0.3 * self.opacity)
			)
			love.graphics.rectangle('fill',
				self.collisionX,
				self.collisionY,
				self.collisionW,
				self.collisionH
			)
		end,
		drawOrder = function(self)
			return 1
		end
	})
)

return itemSystem.registerModule({
  name = 'aoe-slam',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item, props)
    return {
			blueprint = Attack,
			props = props
    }
	end,
	tooltip = function(item, props)
		return {
			template = 'deals {minDamage} - {maxDamage} area of effect damage in front of the player',
			data = props
		}
	end
})
