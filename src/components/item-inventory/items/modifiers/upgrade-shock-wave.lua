local Component = require 'modules.component'
local groups = require 'components.groups'
local itemSystem = require(require('alias').path.itemSystem)
local AbilityBase = require 'components.abilities.base-class'
local msgBus = require 'components.msg-bus'
local collisionGroups = require 'modules.collision-groups'
local calcDamage = require 'modules.abilities.calc-damage'

local function angleFromDirection(dx, dy, startAngle)
	return (math.atan2(dx, dy) * -1) + startAngle
end
local setupChanceFunctions = require 'utils.chance'
local genFloorCrackStyle = setupChanceFunctions({
	{
		chance = 1,
		__call = function()
			return 'floor-crack-1'
		end
	},
	{
		chance = 1,
		__call = function()
			return 'floor-crack-2'
		end
	},
	{
		chance = 1,
		__call = function()
			return 'floor-crack-3'
		end
	}
})

local function drawFloorCrack(style, x, y, angle)
	local AnimationFactory = require 'components.animation-factory'
	local floorCrackSprite = AnimationFactory:newStaticSprite(style)
	local ox, oy = floorCrackSprite:getSourceOffset()
	love.graphics.draw(
		AnimationFactory.atlas,
		floorCrackSprite.sprite,
		x, y,
		angle,
		1, 1,
		ox, oy
	)
end

local Fissure = Component.createFactory(
	AbilityBase({
		group = groups.all,
		weaponDamageScaling = 1.3,
		width = 10,
		speed = 250,
		lifeTime = 0,
		maxAnimationLifeTime = 1,
		init = function(self)
			local Position = require 'utils.position'
			self.dx, self.dy = Position.getDirection(self.x, self.y, self.x2, self.y2)

			self.crackSize = 32
			local collisionWorlds = require 'components.collision-worlds'
			local collisionSize = self.crackSize
			self.collision = self:addCollisionObject(
				collisionGroups.projectile,
				self.x,
				self.y,
				collisionSize,
				collisionSize,
				self.crackSize/2,
				self.crackSize/2
			):addToWorld(collisionWorlds.map)

			self.floorCrackStyles = {}
			for i=1, 4 do
				table.insert(self.floorCrackStyles, genFloorCrackStyle())
			end

			local shockWaveDistance = (#self.floorCrackStyles) * self.crackSize
			local finalX = self.x + self.dx * shockWaveDistance
			local finalY = self.y + self.dy * shockWaveDistance
			self.collision:move(finalX, finalY, function(item, other)
				if collisionGroups.matches(other.group, collisionGroups.create(collisionGroups.ai, collisionGroups.environment)) then
					msgBus.send(msgBus.CHARACTER_HIT, {
						parent =  other.parent,
						damage = calcDamage(self)
					})
					return 'touch'
				end
			end)
		end,
		update = function(self, dt)
			self.lifeTime = self.lifeTime + dt
			if self.lifeTime > self.maxAnimationLifeTime then
				self:delete()
			end
		end,
    draw = function(self)
			local opacity = 1 - (self.lifeTime / self.maxAnimationLifeTime)
      local crackStyles = self.floorCrackStyles

			love.graphics.setColor(0,0,0,0.3 * opacity)
			for i=1, #crackStyles do
				local dist = self.crackSize * i
				drawFloorCrack(
					crackStyles[i],
					self.x + dist * self.dx,
					self.y + dist * self.dy - 2,
					angleFromDirection(self.dx, self.dy, math.pi/2)
				)
			end

			love.graphics.setColor(0,0,0,0.8 * opacity)
			for i=1, #crackStyles do
				local dist = self.crackSize * i
				drawFloorCrack(
					crackStyles[i],
					self.x + dist * self.dx,
					self.y + dist * self.dy,
					angleFromDirection(self.dx, self.dy, math.pi/2)
				)
      end
    end,

    drawOrder = function()
      return 2
    end
	})
)

return itemSystem.registerModule({
  name = 'upgrade-shock-wave',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(item, props)
    local itemState = itemSystem.getState(item)
    msgBus.on(msgBus.PLAYER_WEAPON_ATTACK, function(msg)
      if (not itemState.equipped) then
        return msgBus.CLEANUP
      end
      Fissure.create({
				minDamage = props.minDamage,
				maxDamage = props.maxDamage,
        x = msg.fromPos.x,
        y = msg.fromPos.y,
        x2 = msg.targetPos.x,
        y2 = msg.targetPos.y,
      })
    end, nil, function(msg)
      return (not itemState.equipped)
        or (
					(item.experience >= props.experienceRequired) and
					msg.source == item.__id
				)
    end)
	end,
	tooltip = function(_, props)
		return {
			type = 'upgrade',
			data = {
				title = 'shockwave',
				description = {
					template = 'deals {minDamage} - {maxDamage} damage in a line',
					data = props
				}
			}
		}
	end
})