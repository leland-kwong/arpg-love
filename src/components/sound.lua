local Sound = {
  drinkPotion = love.audio.newSource('built/sounds/drink-potion.wav', 'static'),
  levelUp = love.audio.newSource('built/sounds/level-up.wav', 'static'),
  INVENTORY_PICKUP = love.audio.newSource('built/sounds/inventory-pickup.wav', 'static'),
  INVENTORY_DROP = love.audio.newSource('built/sounds/inventory-drop.wav', 'static'),
  PLASMA_SHOT = love.audio.newSource('built/sounds/plasma-shot.wav', 'static'),
  MOVE_SPEED_BOOST = love.audio.newSource('built/sounds/generic-spell-rush.wav', 'static')
}

return Sound