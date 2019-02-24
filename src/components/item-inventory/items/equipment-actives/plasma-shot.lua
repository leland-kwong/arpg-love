local collisionGroups = require 'modules.collision-groups'
local itemSystem = require(require('alias').path.itemSystem)
local Color = require 'modules.color'
local Sound = require 'components.sound'
local msgBus = require("components.msg-bus")
local setProp = require 'utils.set-prop'

local weaponLength = 26
local bulletColor = {Color.rgba255(252, 122, 255)}
local muzzleFlashMessage = {
	color = bulletColor
}

return itemSystem.registerModule({
  name = 'plasma-shot',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item, props)
		Sound.playEffect('plasma-shot.wav')
    msgBus.send(msgBus.PLAYER_WEAPON_MUZZLE_FLASH, muzzleFlashMessage)
    return {
			blueprint = require 'components.abilities.bullet',
			props = {
				minDamage = props.minDamage,
				maxDamage = props.maxDamage,
				color = bulletColor,
				targetGroup = 'enemyAi environment obstacle',
				startOffset = weaponLength,
				speed = 400,
			}
		}
	end,
	tooltip = function(item, props)
		return {
			template = 'Shoots a plasma shot dealing {damageRange} damage.',
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