local Component = require 'modules.component'
local config = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require 'modules.color'
local functional = require("utils.functional")
local AnimationFactory = require 'components.animation-factory'
local setProp = require 'utils.set-prop'

local baseDamage = 2
local bulletColor = {Color.rgba255(252, 122, 255)}

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

return itemDefs.registerType({
	type = "pod-one",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			-- static properties
			weaponDamage = baseDamage
		}
	end,

	properties = {
		sprite = "pod-one",
		title = 'Pod One',
		rarity = config.rarity.LEGENDARY,
		category = config.category.WEAPON_1,

		onEquip = function(self)
			itemDefs.getState(self)
				:set(
					'animation',
					AnimationFactory:new({
						'pod-one'
					})
				)
				:set('isAttacking', false)
		end,

		tooltip = function(self)
			local stats = {
				statValue(self.weaponDamage, Color.CYAN, "damage \n"),
			}
			return functional.reduce(stats, concatTable, {})
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

		onActivateWhenEquipped = function(self, props)
			local Projectile = require 'components.abilities.bullet'
			return Projectile.create(
				setProp(props)
					:set('color', bulletColor)
					:set('targetGroup', 'ai')
					:set('speed', 400)
			)
		end,

		modifier = function(self, msgType, msgValue)
			if msgBus.PLAYER_ATTACK == msgType then
				msgValue.flatDamage = self.state.bonusDamage
			end
			return msgValue
		end,

		update = function(self)
			itemDefs.getState(self)
				:set('isAttacking', false)
		end,

		render = function(self)
			local state = itemDefs.getState(self)
			local playerRef = Component.get('PLAYER')
			if not playerRef then
				return
			end
			local posX, posY = playerRef:getPosition()
			local centerOffsetX, centerOffsetY = state.animation:getOffset()
			local facingX, facingY = playerRef:getProp('facingDirectionX'),
															 playerRef:getProp('facingDirectionY')
			local facingSide = facingX > 0 and 1 or -1
			local offsetX = (facingSide * -1) * 30
			local angle = (math.atan2(facingX, facingY) * -1) + (math.pi/2)
			love.graphics.draw(
				AnimationFactory.atlas,
				state.animation.sprite,
				posX,
				posY,
				angle,
				1,
				-- vertically flip when facing other side so the shadow is in the right position
				1 * facingSide,
				centerOffsetX, centerOffsetY
			)
		end
	}
})