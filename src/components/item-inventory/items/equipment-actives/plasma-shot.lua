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

local function CreateAttack(item, props)
	local Projectile = require 'components.abilities.bullet'
	local numBounces = props.numBounces and (props.numBounces + 1) or 0
	return Projectile.create(
		setProp(props)
			:set('maxBounces', 1)
			:set('numBounces', numBounces)
			:set('minDamage', 1)
			:set('maxDamage', 3)
			:set('color', bulletColor)
			:set('targetGroup', collisionGroups.create(
				collisionGroups.ai,
				collisionGroups.environment,
				collisionGroups.obstacle
			))
			:set('startOffset', weaponLength)
			:set('speed', 400)
			:set('cooldown', item.props.weaponCooldown)
			:set('onHit', itemSystem.getState(item).onHit)
	)
end

return itemSystem.registerModule({
  name = 'plasma-shot',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item, props)
    love.audio.stop(Sound.PLASMA_SHOT)
    love.audio.play(Sound.PLASMA_SHOT)
    msgBus.send(msgBus.PLAYER_WEAPON_MUZZLE_FLASH, muzzleFlashMessage)
    return CreateAttack(item, props)
  end
})