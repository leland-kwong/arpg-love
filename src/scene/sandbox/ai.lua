local groups = require 'components.groups'
local pprint = require 'utils.pprint'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local pathfinder = require 'utils.search-path'
local iterateGrid = require 'utils.iterate-grid'
local config = require 'config'
local camera = require 'components.camera'

local AiTest = {}

local grid = {
  {1,1,1,1,1,1,1},
  {1,1,1,0,0,1,1},
  {1,1,0,1,0,0,1},
  {1,1,1,1,1,0,1},
  {1,1,1,1,1,0,1},
  {1,1,1,1,1,0,1},
  {1,1,1,1,1,1,1},
}

local OBSTACLE = 0
function AiTest.init(self)
  local enemySize = config.gridSize
  self.ai = {
    x = 4 * config.gridSize,
    y = 4 * config.gridSize,
    h = enemySize,
    w = enemySize
  }
  self.ai.collisionObject = collisionObject:new(
    'ai',
    self.ai.x,
    self.ai.y,
    self.ai.h,
    self.ai.w
  ):addToWorld(collisionWorlds.map)

  self.player = {
    x = 0,
    y = 0,
    h = config.gridSize,
    w = config.gridSize,
    speed = 200
  }
  self.player.collisionObject = collisionObject:new(
    'player',
    self.player.x,
    self.player.y,
    self.player.h,
    self.player.w
  ):addToWorld(collisionWorlds.map)

  local function setupWallCollisionObjects(v, x, y)
    if v == OBSTACLE then
      local size = config.gridSize
      local obj = collisionObject:new(
        'wall',
        x * size,
        y * size,
        size,
        size
      ):addToWorld(collisionWorlds.map)
    end
  end
  iterateGrid(grid, setupWallCollisionObjects)
end

local function playerMovement(player, dt)
  local moveAmount = player.speed * dt
  local dx, dy = 0, 0

  if love.keyboard.isDown('d') then
    dx = dx + moveAmount
  end

  if love.keyboard.isDown('a') then
    dx = dx - moveAmount
  end

  if love.keyboard.isDown('w') then
    dy = dy - moveAmount
  end

  if love.keyboard.isDown('s') then
    dy = dy + moveAmount
  end

  local ax, ay = player.collisionObject:move(
    player.x + dx,
    player.y + dy
  )

  player.x = ax
  player.y = ay
end

function AiTest.update(self, dt)
  playerMovement(self.player, dt)

  camera:setPosition(self.player.x, self.player.y)
end

function AiTest.draw(self)
  iterateGrid(grid, function(v, x, y)
    if v == OBSTACLE then
      local tileSize = config.gridSize
      love.graphics.setColor(0.75,0.75,0.75,1)
      love.graphics.rectangle(
        'fill',
        x * tileSize,
        y * tileSize,
        tileSize,
        tileSize
      )
    end
  end)

  local ai = self.ai
  love.graphics.setColor(0.5,0.5,1,1)
  love.graphics.rectangle(
    'fill',
    ai.x,
    ai.y,
    ai.h,
    ai.w
  )

  local player = self.player
  love.graphics.setColor(1,1,0,1)
  love.graphics.rectangle(
    'fill',
    player.x,
    player.y,
    player.h,
    player.w
  )
end

return groups.debug.createFactory(AiTest)
