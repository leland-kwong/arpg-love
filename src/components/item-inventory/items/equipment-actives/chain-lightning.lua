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
    -- msgBus.send(msgBus.PLAYER_WEAPON_MUZZLE_FLASH, muzzleFlashMessage)
    return {
			blueprint = require 'components.abilities.chain-lightning',
			props = {
				lightningDamage = Vec2(2, 4),
				targetGroup = collisionGroups.create(
					collisionGroups.enemyAi,
					collisionGroups.environment,
					collisionGroups.obstacle
				),
			}
		}
	end,
	tooltip = function(item, props)
		return {
			template = 'Releases a chain of lightning dealing damage.',
			data = {}
		}
	end
})