local itemSystem = require 'components.item-inventory.items.item-system'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local modDefinitions = require 'components.item-inventory.modifier-definitions'
local tick = require 'utils.tick'
local baseStatModifiers = require 'components.state.base-stat-modifiers'
local Component = require 'modules.component'

--[[
  props [TABLE]
  {props.maxStacks} = [INT]
  {props.resetStackDelay} = [INT]
]]

return itemSystem.registerModule({
  name = 'frenzy',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(_, props, state)
    state.stacks = 0
    local stackClearTimer

    local function resetStacks()
      state.stacks = 0
      msgBus.send(msgBus.PLAYER_STATS_NEW_MODIFIERS)
    end

    msgBus.on(msgBus.CHARACTER_HIT, function(msg)
      if (not state.equipped) then
        return msgBus.CLEANUP
      end

      if (msg.parent == Component.get('PLAYER')) then
        return
      end

      if stackClearTimer then
        stackClearTimer:stop()
      end
      state.stacks = math.min(props.maxStacks, state.stacks + 1)
      stackClearTimer = tick.delay(resetStacks, props.resetStackDelay)

      msgBus.send(msgBus.PLAYER_STATS_NEW_MODIFIERS)
    end)

    msgBus.on(msgBus.PLAYER_STATS_NEW_MODIFIERS, function(mods)
      if (not state.equipped) then
        return msgBus.CLEANUP
      end

      mods.attackTimeReduction = mods.attackTimeReduction + (props.attackTimeReduction * state.stacks)
      mods.energyCostReduction = mods.energyCostReduction + (props.energyCostReduction * state.stacks)
      mods.cooldownReduction = mods.cooldownReduction + (props.cooldownReduction * state.stacks)
      return mods
    end, 1)
  end,
  tooltip = function(_, props)
    local transformedProps = {}
    for k,v in pairs(props) do
      local displayValueTransformer = baseStatModifiers.propTypesDisplayValue[k]
      transformedProps[k] = displayValueTransformer(v)
    end
    return {
      type = 'upgrade',
      data = {
        experienceRequired = 0,
        title = 'frenzy',
        description = {
          template =
            'Each time you hit an enemy, gain a frenzy stack.'

            ..'\n\nEach frenzy stack gives:'
              ..'\n\t+{attackTimeReduction} attack time reduction'
              ..'\n\t+{cooldownReduction} cooldown reduction'
              ..'\n\t+{energyCostReduction} energy cost reduction'

            ..'\n\nMaximum of {maxStacks} stacks. Stacks reset after not attacking for {resetStackDelay}s.',
          data = transformedProps
        }
      }
    }
  end
})