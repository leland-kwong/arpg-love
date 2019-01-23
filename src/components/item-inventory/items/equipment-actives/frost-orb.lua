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
  name = 'frost-orb',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item, props)
    return {
			blueprint = require 'components.abilities.frost-orb',
			props = {
        group = 'all',
        damage = props.damage,
        coldDamage = props.coldDamage,
				target = collisionGroups.create(
					collisionGroups.enemyAi,
					collisionGroups.environment
        ),
        speed = 150,
        projectileSpeed = 250,
        projectileRate = 5,
        projectileLifeTime = props.lifeTime or 0.5
			}
		}
	end,
	tooltip = function(item, props)
		return {
			template = 'Creates an orb of frost that releases piercing shards of ice, each dealing {damageRange} cold damage.',
			data = {
				damageRange = {
					type = 'range',
					from = {
						prop = 'minDamage',
						val = props.coldDamage.x
					},
					to = {
						prop = 'maxDamage',
						val = props.coldDamage.y
					},
				}
			}
		}
	end
})