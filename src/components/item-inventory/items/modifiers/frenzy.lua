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
  active = function(item, props, state)
    local itemId = item.__id
    state.stacks = 0
    local stackClearTimer

    local function resetStacks()
      state.stacks = 0
      msgBus.send(msgBus.PLAYER_STATS_NEW_MODIFIERS)
    end

    local function stackRenderer(x, y)
      local AnimationFactory = require 'components.animation-factory'
      local icon = AnimationFactory:newStaticSprite('status-frenzy')
      local width = icon:getWidth()
      Component.get('hudTextSmallLayer'):add(state.stacks, Color.WHITE, x + width - 4, y)
      love.graphics.setColor(1,1,1)
      love.graphics.draw(AnimationFactory.atlas, icon.sprite, x, y)
    end

    msgBus.on(msgBus.UPDATE, function(msg)
      if (not state.equipped) then
        return msgBus.CLEANUP
      end
      Component.addToGroup(itemId, 'hudStatusIcons', {
        icon = 'status-frenzy',
        text = state.stacks,
        color = Color.WHITE
      })
    end)

    msgBus.on(msgBus.CHARACTER_HIT, function(msg)
      if (not state.equipped) then
        return msgBus.CLEANUP
      end

      if (not msg.itemSource) then
        return
      end

      if stackClearTimer then
        stackClearTimer:stop()
      end
      state.stacks = math.min(props.maxStacks, state.stacks + 1)
      stackClearTimer = tick.delay(resetStacks, props.resetStackDelay)

      msgBus.send(msgBus.PLAYER_STATS_NEW_MODIFIERS)
    end)

    msgBus.on(msgBus.PLAYER_UPDATE_START, function(mods)
      if (not state.equipped) then
        return msgBus.CLEANUP
      end

      Component.get('PLAYER').stats
        :add('attackSpeed', props.attackSpeed * state.stacks)
        :add('energyCostReduction', props.energyCostReduction * state.stacks)
        :add('cooldownReduction', props.cooldownReduction * state.stacks)
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
            'Gain increased offensive capabilities at the expense of increased energy cost.'

            ..'\n\nWhenever you hit an enemy, gain a frenzy stack that gives:'
              ..'\n\t+{attackSpeed} attack speed'
              ..'\n\t+{cooldownReduction} cooldown reduction'
              ..'\n\t+{energyCostReduction} energy cost reduction'

            ..'\n\nMaximum of {maxStacks} stacks. Stacks reset after not attacking for {resetStackDelay}s.',
          data = transformedProps
        }
      }
    }
  end
})