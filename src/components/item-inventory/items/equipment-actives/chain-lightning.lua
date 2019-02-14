local collisionGroups = require 'modules.collision-groups'
local itemSystem = require(require('alias').path.itemSystem)
local Color = require 'modules.color'
local Sound = require 'components.sound'
local msgBus = require("components.msg-bus")
local setProp = require 'utils.set-prop'
local Vec2 = require 'modules.brinevector'

local weaponLength = 26
local bulletColor = {Color.rgba255(252, 255, 255)}
local muzzleFlashMessage = {
	color = bulletColor
}

return itemSystem.registerModule({
  name = 'chain-lightning',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item, props)
    local Sound = require 'components.sound'
    Sound.playEffect('energy-beam-1.wav')
    return {
			blueprint = require 'components.abilities.chain-lightning',
			props = {
				lightningDamage = props.lightningDamage,
				targetGroup = 'enemyAi environment obstacle',
				range = 6,
				maxBounces = 2
			}
		}
	end,
	tooltip = function(item, props)
		return {
			template = 'Release a chain of lightning dealing {damageRange} damage per target. Chains up to {maxBounces} times.',
			data = {
				damageRange = {
					type = 'range',
					from = {
						prop = 'minDamage',
						val = props.lightningDamage.x
					},
					to = {
						prop = 'maxDamage',
						val = props.lightningDamage.y
					},
				},
				maxBounces = props.maxBounces
			}
		}
	end
})