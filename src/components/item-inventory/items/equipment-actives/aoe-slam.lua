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
local actionSpeed = 0.3
local attackCooldown = 0
local hitModifierDuration = actionSpeed * 1.2

local function triggerAttack(self)
	self.collisionX, self.collisionY = self.x - (self.w/2), self.y - (self.h/2)
	self.collisionW, self.collisionH = self.w, self.h
	local cw = require 'components.collision-worlds'.map
	cw:queryRect(
		self.collisionX,
		self.collisionY,
		self.collisionW,
		self.collisionH,
		function(item)
			if (collisionGroups.matches(item.group, 'enemyAi environment')) then
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

		local tween = require 'modules.tween'
		self.yPos = -20
		self.attackAnimationDuration = self.actionSpeed * 0.2
		self.attackRecoveryAnimationDuration = self.actionSpeed * 0.8
		self.tween = tween.new(self.attackAnimationDuration, self, {
			yPos = 0,
		})
	end,
	update = function(self, dt)
		local complete = self.tween:update(dt)
		if complete and (not self.ending) then
			self.ending = true
			local tick = require 'utils.tick'
			tick.delay(function()
				self:delete(true)
				Component.addToGroup(
					Component.get('WEAPON_CORE'),
					'all'
				)
			end, self.attackRecoveryAnimationDuration)

			local ImpactDispersion = require 'components.abilities.effect-dispersion'
			ImpactDispersion.create({
				x = self.x,
				y = self.y,
				scale = {
					x = 0.5,
					y = 0.4
				},
				radius = 2,
				duration = 10,
				color = Color.YELLOW
			})

			self.onImpactFrame()

			local Sound = require 'components.sound'
			Sound.playEffect('air-slam-impact.wav')
		end
	end,
	drawSprite = function(color, x, y, angle, facingX, stretchY)
		local AnimationFactory = require 'components.animation-factory'
		local animation = AnimationFactory:newStaticSprite('companion/inner')
		local ox, oy = animation:getOffset()
		love.graphics.setColor(color)
		animation:draw(
			x,
			y,
			angle or 0,
			1 * facingX,
			-1, -- flip companion upside down
			ox,oy
		)

		local animation = AnimationFactory:newStaticSprite('companion/outer')
		local ox, oy = animation:getOffset()
		love.graphics.setColor(color)
		animation:draw(
			x,
			y,
			angle or 0,
			1 * facingX,
			-1, -- flip companion upside down
			ox,oy
		)
	end,
	draw = function(self)
		local playerRef = Component.get('PLAYER')
		local facingX = playerRef.facingDirectionX > 0 and 1 or -1

		self.drawSprite({
			1,1,1,0.3
		}, self.x, self.y + self.yPos - 15, 0, facingX)
		self.drawSprite({
			1,1,1,0.5
		}, self.x, self.y + self.yPos - 9, 0, facingX)
		self.drawSprite({
			1,1,1,0.5
		}, self.x, self.y + self.yPos - 4, 0, facingX)
		self.drawSprite({
			1,1,1,1
		}, self.x, self.y + self.yPos, 0, facingX)
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
			local playerRef = Component.get('PLAYER')
			self.x = playerRef.x + (playerRef.facingDirectionX * 30)
			self.y = playerRef.y + (playerRef.facingDirectionY * 30)
			WeaponAnimation.create({
				x = self.x,
				y = self.y,
				actionSpeed = self.actionSpeed,
				onImpactFrame = function()
					triggerAttack(self)
					self:delete()
				end
			})
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
					}
				}
			}
		}
	end
})
