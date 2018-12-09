local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local CollisionWorlds = require 'components.collision-worlds'
local collisionGroups = require 'modules.collision-groups'

local Shard = Component.createFactory({
  init = function(self)
    Component.addToGroup(self, self.componentGroup)
    Component.addToGroup(self, 'gameWorld')

    self.clock = 0

    local length = 1000000
    self.x2, self.y2 = self.x + length * math.sin(-self.angle),
        self.y + length * math.cos(-self.angle) - self.z
    local initialOffset = 5
    self.x, self.y = self.x + initialOffset * math.sin(-self.angle),
      self.y + initialOffset * math.cos(-self.angle) - self.z

    self.animation = AnimationFactory:newStaticSprite('frost-orb-shard')
    self.ox, self.oy = self.animation:getOffset()
    local Position = require 'utils.position'
    self.dx, self.dy = Position.getDirection(self.x, self.y, self.x2, self.y2)
  end,
  update = function(self, dt)
    self.clock = self.clock + dt
    local isExpired = self.clock >= self.lifeTime
    if isExpired then
      return self:delete()
    end

    self.x = self.x + dt * self.dx * self.speed
    self.y = self.y + dt * self.dy * self.speed

    local items, len = self.collisionWorld:queryRect(self.x - self.ox, self.y - self.ox, 6, 6)
    if (len > 0) then
      for i=1, len do
        cItem = items[i]
        local collisionGroups = require 'modules.collision-groups'
        local isHit = collisionGroups.matches(
          cItem.group,
          self.target
        )
        if isHit then
          local msgBus = require 'components.msg-bus'
          msgBus.send(msgBus.CHARACTER_HIT, {
            parent = cItem.parent,
            source = self.source,
            coldDamage = math.random(self.coldDamage.x, self.coldDamage.y),
          })
          msgBus.send(msgBus.CHARACTER_HIT, {
            parent = cItem.parent,
            source = Component.newId(),
            modifiers = {
              freeze = math.random(0, 3) == 1 and 1 or 0
            },
            duration = 0.5
          })
          self:delete(true)
        elseif collisionGroups.matches(cItem.group, 'obstacle') then
          self:delete(true)
        end
      end
    end
  end,
  draw = function(self)
    love.graphics.setColor(self.color or {1,1,1})
    -- love.graphics.setColor(1,1,1)
    love.graphics.draw(
      AnimationFactory.atlas,
      self.animation.sprite,
      self.x,
      self.y,
      self.angle + math.pi/2,
      1, 1,
      self.ox, self.oy
    )
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self)
  end,
})

local FrostOrb = Component.createFactory({
  x = 0,
  y = 0,
  startOffset = 10,
  collisionWorld = CollisionWorlds.map,
  lifeTime = 1,
  scale = 1,
  opacity = 1,
  angle = math.pi + math.pi/2,
  speed = 50,
  projectileRate = 5,
  projectileLifeTime = 1,
  projectileSpeed = 120,
  init = function(self)
    Component.addToGroup(self, self.componentGroup)
    Component.addToGroup(self, 'gameWorld')

    self.clock = 0
    self.shardClock = 0
    self.rotation = 0

    self.x, self.y = self.x + (self.dx * self.startOffset),
      self.y + (self.dy * self.startOffset)
    self.animation = AnimationFactory:newStaticSprite('frost-orb-core')
    self.ox, self.oy = self.animation:getOffset()
    self.width, self.height = self.animation:getWidth(), self.animation:getHeight()

    local Sound = require 'components.sound'
    self.sound = Sound.playEffect('frost-orb.wav')
  end,
  update = function(self, dt)
    self.rotation = self.rotation - dt * 20
    self.clock = self.clock + dt
    self.shardClock = self.shardClock + dt

    local isExpired = self.clock >= self.lifeTime
    if isExpired then
      self:onExpire()
    end

    self.x, self.y = self.x + self.speed * dt * self.dx, self.y + self.speed * dt * self.dy
    local items, len = self.collisionWorld:queryRect(self.x - self.ox, self.y - self.oy, self.width, self.height)
    if (len > 0) then
      for i=1, len do
        if collisionGroups.matches(items[i].group, 'obstacle') then
          self:onExpire()
        end
      end
    end

    if self.expiring then
      return
    end

    local shardRate = 0.125 / self.projectileRate
    if self.shardClock > shardRate then
      self.shardClock = 0
      local params = {
        x = self.x,
        y = self.y,
        angle = self.rotation,
        coldDamage = self.coldDamage,
        collisionWorld = self.collisionWorld,
        target = self.target,
        componentGroup = self.componentGroup,
        lifeTime = self.projectileLifeTime,
        speed = self.projectileSpeed,
        source = self:getId()
      }
      Shard.create(params)
    end
  end,
  draw = function(self, dt)
    love.graphics.setColor(0,0,0,math.min(0.3, self.opacity))
    -- shadow
    self.animation:draw(
      self.x,
      self.y + self.animation:getHeight(),
      self.angle,
      self.scale/2,
      self.scale,
      self.ox,
      self.oy
    )

    love.graphics.setColor(1,1,1,self.opacity)
    self.animation:draw(
      self.x,
      self.y,
      self.angle,
      self.scale,
      self.scale,
      self.ox,
      self.oy
    )
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self)
  end,
  onExpire = function(parent)
    parent.expiring = true
    parent.speed = 0
    parent.volume = 1
    local tween = require 'modules.tween'
    Component.create({
      init = function(self)
        Component.addToGroup(self, parent.componentGroup)
        self.tween = tween.new(0.25, parent, {
          opacity = 0,
          scale = 0,
          volume = 0
        })
      end,
      update = function(self, dt)
        local complete = self.tween:update(dt)
        parent.sound:setVolume(parent.volume)
        if complete then
          parent:delete(true)
          local Sound = require 'components.sound'
          Sound.stopEffect(parent.sound)
        end
      end
    }):setParent(parent)
  end,
  final = function(self)
    love.audio.stop(self.sound)
  end
})

return FrostOrb