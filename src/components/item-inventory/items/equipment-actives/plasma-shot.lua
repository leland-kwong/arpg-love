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
    love.audio.stop(Sound.PLASMA_SHOT)
    love.audio.play(Sound.PLASMA_SHOT)
    msgBus.send(msgBus.PLAYER_WEAPON_MUZZLE_FLASH, muzzleFlashMessage)
    return {
			blueprint = require 'components.abilities.bullet',
			props = {
				minDamage = 1,
				maxDamage = 3,
				color = bulletColor,
				targetGroup = collisionGroups.create(
					collisionGroups.ai,
					collisionGroups.environment,
					collisionGroups.obstacle
				),
				startOffset = weaponLength,
				speed = 400,
			}
		}
  end
})