local itemConfig = require("components.item-inventory.items.config")
local config = require 'config.config'
local msgBus = require("components.msg-bus")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require 'modules.color'
local functional = require("utils.functional")
local equipmentBaseSubscriber = require 'components.item-inventory.items.equipment-base-subscriber'
local groups = require 'components.groups'

local mathFloor = math.floor

local enemiesPerDamageIncrease = 30
local maxBonusDamage = 2
local baseDamage = 2

local function onEnemyDestroyedIncreaseDamage(self)
	local s = self.state
	s.enemiesKilled = s.enemiesKilled + 1
	s.bonusDamage = mathFloor(s.enemiesKilled / enemiesPerDamageIncrease)
	if s.bonusDamage > maxBonusDamage then
		s.bonusDamage = maxBonusDamage
	end
	self.flatDamage = s.bonusDamage
end

local function statValue(stat, color, type)
	local sign = stat >= 0 and "+" or "-"
	return {
		color, sign..stat..' ',
		{1,1,1}, type
	}
end

local function concatTable(a, b)
	for i=1, #b do
		local elem = b[i]
		table.insert(a, elem)
	end
	return a
end

local MUZZLE_FLASH_COLOR = {Color.rgba255(232, 187, 27, 1)}
local muzzleFlashMessage = {
	color = MUZZLE_FLASH_COLOR
}

return itemDefs.registerType({
	type = 'pod-module-fireball',

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			state = {
				baseDamage = baseDamage,
				bonusDamage = 0,
				enemiesKilled = 0,
			},

			-- static properties
			weaponDamage = baseDamage,
			experience = 0
		}
	end,

	properties = {
		sprite = "weapon-module-fireball",
		title = 'tz-819 mortar',
		rarity = itemConfig.rarity.LEGENDARY,
		category = itemConfig.category.POD_MODULE,

		levelRequirement = 3,
		attackTime = 0.4,
		energyCost = function(self)
			return 2
		end,

		upgrades = {
			{
				sprite = 'item-upgrade-placeholder-unlocked',
				title = 'Daze',
				description = 'Attacks slow the target',
				experienceRequired = 45,
				props = {
					knockBackDistance = 50
				}
			},
			{
				sprite = 'item-upgrade-placeholder-unlocked',
				title = 'Scorch',
				description = 'Chance to create an area of ground fire, dealing damage over time to those who step into it.',
				experienceRequired = 135,
				props = {
					duration = 3,
					minDamagePerSecond = 1,
					maxDamagePerSecond = 3,
				}
			}
		},

		tooltip = function(self)
			local _state = self.state
			local stats = {
				{
					Color.WHITE, '\nWhile equipped: \nPermanently gain +1 damage for every 10 enemies killed.\n',
					Color.CYAN, _state.enemiesKilled, Color.WHITE, ' enemies killed'
				}
			}
			return functional.reduce(stats, function(combined, textObj)
				return concatTable(combined, textObj)
			end, {})
		end,

		onEquip = function(self)
			equipmentBaseSubscriber(self)
			local state = itemDefs.getState(self)
			local definition = itemDefs.getDefinition(self)
			local upgrades = definition.upgrades

			state.onHit = function(attack, hitMessage)
				local target = hitMessage.parent
				local up1 = upgrades[1]
				local up1Ready = self.experience >= up1.experienceRequired
				if up1Ready then
					msgBus.send(msgBus.CHARACTER_HIT, {
						parent = target,
						statusIcon = 'status-slow',
						duration = 1,
						modifiers = {
							moveSpeed = function(t)
								return t.moveSpeed * -0.5
							end
						},
						source = definition.title
					})
				end
				return hitMessage
			end

			local function handleUpgrade2(attack)
				local up2 = upgrades[2]
				local up2Ready = self.experience >= up2.experienceRequired
				if up2Ready then
					local GroundFlame = require 'components.particle.ground-flame'
					local x, y = attack.x, attack.y
					local width, height = 16, 16
					GroundFlame.create({
						group = groups.all,
						x = x,
						y = y,
						width = width,
						height = height,
						gridSize = config.gridSize,
						duration = up2.props.duration
					})

					local collisionWorlds = require 'components.collision-worlds'
					local tick = require 'utils.tick'
					local tickCount = 0
					local timer
					timer = tick.recur(function()
						tickCount = tickCount + 1
						if tickCount >= up2.props.duration then
							timer:stop()
						end
						collisionWorlds.map:queryRect(
							x - config.gridSize,
							y - config.gridSize,
							width * 2,
							height * 2,
							function(item)
								if item.group == 'ai' then
									msgBus.send(msgBus.CHARACTER_HIT, {
										parent = item.parent,
										damage = math.random(
											up2.props.minDamagePerSecond,
											up2.props.maxDamagePerSecond
										)
									})
								end
							end
						)
					end, 1)
				end
			end
			state.final = handleUpgrade2
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

		onActivateWhenEquipped = function(self, props)
			local Fireball = require 'components.fireball'
			local F = require 'utils.functional'
			props.minDamage = 0
			props.maxDamage = 0
			props.cooldown = 0.7
			props.startOffset = 26
			props.onHit = itemDefs.getState(self).onHit
			props.final = F.wrap(
				props.final,
				itemDefs.getState(self).final
			)
			msgBus.send(msgBus.PLAYER_WEAPON_MUZZLE_FLASH, muzzleFlashMessage)

			local Sound = require 'components.sound'
			love.audio.play(Sound.functions.fireBlast())
			return Fireball.create(props)
		end,

		onMessage = function(self, msgType)
			if msgBus.ENEMY_DESTROYED == msgType then
				onEnemyDestroyedIncreaseDamage(self)
			end
		end
	}
})