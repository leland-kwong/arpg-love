local Component = require 'modules.component'
local gameConfig = require 'config.config'
local itemSystem = require("components.item-inventory.items.item-system")
local msgBus = require 'components.msg-bus'
local extend = require 'utils.object-utils'.extend
local Color = require 'modules.color'

return itemSystem.registerModule({
  name = 'upgrade-slow-on-hit',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(item, props)
    local id = item.__id
    local itemState = itemSystem.getState(item)
    local modifiers = {
      moveSpeed = function(target)
        return target.moveSpeed * -1 * props.slowAmount
      end
    }
    msgBus.on(msgBus.CHARACTER_HIT, function(hitMessage)
      if (not itemState.equipped) then
        return msgBus.CLEANUP
      end

      if hitMessage.source ~= id then
          return
      end

      local Chance = require 'utils.chance'
      local shouldSlow = Chance.roll(props.chance)
      if shouldSlow then
        msgBus.send(msgBus.CHARACTER_HIT, {
          parent = hitMessage.parent,
          duration = props.slowDuration,
          modifiers = modifiers,
          statusIcon = 'status-slow',
          source = 'UPGRADE_SLOW_ON_HIT'
        })
      end
      return hitMessage
    end, 1)
  end,
  tooltip = function(item, props)
    return {
      type = 'upgrade',
      data = {
        experienceRequired = props.experienceRequired,
        description = {
          template = '+%{chance} chance to slow target move speed by %{slowAmount} for {slowDuration}s on hit',
          data = {
            chance = props.chance * 100,
            slowAmount = props.slowAmount * 100,
            slowDuration = props.slowDuration
          }
        }
      }
    }
  end
})