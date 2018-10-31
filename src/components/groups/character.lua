local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local groups = require 'components.groups'
local lootSystem = require'components.groups.loot'.system
local tween = require 'modules.tween'

msgBus.on(msgBus.CHARACTER_HIT, function(msg)
  local uid = require 'utils.uid'
  local hitId = msg.source or uid()
  -- FIXME: sometimes chain lightning triggers a hit for a non-character component
  if msg.parent.isCharacter then
    if msg.parent.invulnerable then
      return nil
    end
    msg.parent.hitData[hitId] = msg
  end
  return msg
end, 1)

return function(dt)
  for _,c in pairs(groups.character.getAll()) do
    local hitManager = require 'modules.hit-manager'
    local hitCount = hitManager(c, dt, c.onDamageTaken)
    if c.isDestroyed then
      if c.destroyedAnimation then
        local complete = c.destroyedAnimation:update(dt)
        if complete then
          c:delete(true)
          if c.onFinal then
            c:onFinal()
          end
        end
      else
        c.destroyedAnimation = tween.new(0.5, c, {opacity = 0}, tween.easing.outCubic)
        Component.addToGroup(c, lootSystem, c.itemLevel)
        if c.onDestroyStart then
          c:onDestroyStart()
        end
        c.collision:delete()
        msgBus.send(msgBus.ENEMY_DESTROYED, {
          parent = c,
          x = c.x,
          y = c.y,
          experience = c.experience
        })
      end
    end
  end
end