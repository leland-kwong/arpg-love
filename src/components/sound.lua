local setupChanceFunctions = require 'utils.chance'

local Sound = {
  drinkPotion = love.audio.newSource('built/sounds/drink-potion.wav', 'static'),
  levelUp = love.audio.newSource('built/sounds/level-up.wav', 'static'),
  INVENTORY_PICKUP = love.audio.newSource('built/sounds/inventory-pickup.wav', 'static'),
  INVENTORY_DROP = love.audio.newSource('built/sounds/inventory-drop.wav', 'static'),
  BLASTER_2 = love.audio.newSource('built/sounds/blaster-2.wav', 'static'),
  MOVE_SPEED_BOOST = love.audio.newSource('built/sounds/generic-spell-rush.wav', 'static'),
  LOW_HEALTH_WARNING = love.audio.newSource('built/sounds/low-health-warning.wav', 'static'),
  ACTION_ERROR = love.audio.newSource('built/sounds/action-error.wav', 'static'),
  ENEMY_IMPACT = love.audio.newSource('built/sounds/attack-impact-1.wav', 'static'),
  ENERGY_BEAM = love.audio.newSource('built/sounds/energy-beam-1.wav', 'static'),
  FROST_SHOT = love.audio.newSource('built/sounds/ice-shot.wav', 'static'),
  SLOW_TIME = love.audio.newSource('built/sounds/slow-time.wav', 'static'),
  ELECTRIC_SHOCK_SHORT = love.audio.newSource('built/sounds/electric-shock-short.wav', 'static'),
  -- FIRE_BLAST = love.audio.newSource('built/sounds/fire-blast.wav', 'static'),

  functions = {
    fireBlast = function()
      local source = love.audio.newSource('built/sounds/fire-blast.wav', 'static')
      source:setVolume(0.6)
      return source
    end,
    robotDestroyed = setupChanceFunctions({
      {
        chance = 1,
        __call = function()
          local source = love.audio.newSource('built/sounds/robot-destroyed-1.wav', 'static')
          source:setVolume(0.7)
          return source
        end
      },
      {
        chance = 1,
        __call = function()
          return love.audio.newSource('built/sounds/robot-destroyed-2.wav', 'static')
        end
      }
    }),
    creatureDestroyed = setupChanceFunctions({
      {
        chance = 1,
        __call = function()
          return love.audio.newSource('built/sounds/creature-destroyed-1.wav', 'static')
        end
      },
      {
        chance = 1,
        __call = function()
          return love.audio.newSource('built/sounds/creature-destroyed-2.wav', 'static')
        end
      }
    })
  },
  music = {
    homeScreen = love.audio.newSource('built/music/Spartan_Secrets.mp3', 'stream'),
    mainGame = love.audio.newSource('built/music/Infinite_Vortex.mp3', 'stream')
  }
}

local defaultModifier = function(v)
  return v
end

local activeSources = {}
local default = {
  maxActiveSources = 10
}

function Sound.playEffect(file, modifier, maxActiveSources)
  local sourceList = activeSources[file]
  if (not sourceList) then
    sourceList = {}
    activeSources[file] = sourceList
  end

  -- remove all finished sources first
  local i = 1
  while i <= #sourceList do
    local s = sourceList[i]
    if (not s:isPlaying()) then
      table.remove(sourceList, i)
    else
      i = i + 1
    end
  end

  local canPlay = #sourceList < (maxActiveSources or default.maxActiveSources)
  local activeSource
  if canPlay then
    activeSource = love.audio.newSource('built/sounds/'..file, 'static')
    table.insert(
      sourceList,
      activeSource
    )
    love.audio.play(activeSource)

    modifier = modifier or defaultModifier
    modifier(activeSource)
  end

  return activeSource
end

function Sound.stopEffect(source)
  if source then
    love.audio.stop(source)
  end
end

function Sound.modify(source, action, a, b, c, d, e)
  if source then
    source[action](source, a, b, c, d, e)
  end
end

return Sound