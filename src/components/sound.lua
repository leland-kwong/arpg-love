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

function Sound.playEffect(file, modifier)
  modifier = modifier or defaultModifier
  local source = love.audio.newSource('built/sounds/'..file, 'static')
  modifier(source)
  love.audio.play(source)
  return source
end

function Sound.stopEffect(source)
  love.audio.stop(source)
end

return Sound