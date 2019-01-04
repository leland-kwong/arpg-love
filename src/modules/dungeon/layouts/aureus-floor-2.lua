return function()
  local Chance = require 'utils.chance'
  local mapBlockGenerator = Chance({
    {
      chance = 1,
      value = 'room-1'
    },
    {
      chance = 1,
      value = 'room-4'
    },
    {
      chance = 1,
      value = 'room-5'
    }
  })

  local function generateMapBlockDefinitions()
    local blocks = {}
    local mapDefinitions = {
      function()
        return 'room-3'
      end,
      mapBlockGenerator,
      mapBlockGenerator,
      mapBlockGenerator
    }
    while #mapDefinitions > 0 do
      local index = math.random(1, #mapDefinitions)
      local block = table.remove(mapDefinitions, index)()
      table.insert(blocks, block)
    end

    local bossRoomIndex = math.random(#blocks - 1, #blocks)
    table.insert(blocks, bossRoomIndex, 'room-boss-1')

    return blocks
  end

  return {
    gridBlockNames = generateMapBlockDefinitions(),
    columns = 4,
    startPosition = {
      x = 3,
      y = 1
    },
    exitPosition = {
      x = 3,
      y = 1
    }
  }
end