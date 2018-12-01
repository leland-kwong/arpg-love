local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'

local guiTextLayer = GuiText.create({
  group = Component.groups.system,
  font = require'components.font'.primaryLarge.font,
  outline = false
})

local profileData = {}
local totalAverageExecutionTime = 0

msgBus.PROFILE_FUNC = 'PROFILE_FUNC'
msgBus.on(msgBus.PROFILE_FUNC, function(profileProps)
  return require 'utils.perf'({
    resetEvery = 1000,
    done = function(_, totalTime, callCount)
      if (not msgBus.send(msgBus.IS_CONSOLE_ENABLED)) then
        return
      end

      local averageTime = totalTime / callCount
      totalAverageExecutionTime = totalAverageExecutionTime + averageTime
      local passedThreshold = averageTime <= (profileProps.threshold or 0.1)
      if passedThreshold then
        return
      end
      table.insert(profileData, Color.WHITE)
      table.insert(profileData, '\n'..profileProps.name..' '..string.format('%0.2f', averageTime))
    end
  })(profileProps.call)
end)

local function profileFn(groupName, callback)
  return require'utils.perf'({
    resetEvery = 1000,
    done = function(_, totalTime, callCount)
      if (not msgBus.send(msgBus.IS_CONSOLE_ENABLED)) then
        return
      end

      local averageTime = totalTime / callCount
      totalAverageExecutionTime = totalAverageExecutionTime + averageTime
      if averageTime >= 0.1 then
        table.insert(profileData, Color.WHITE)
        table.insert(profileData, '\n'..groupName..': '..string.format('%0.2f', averageTime))
      end
    end
  })(callback)
end

-- profile all systems
for k,group in pairs(groups) do
  group.updateAll = profileFn(k..' update', group.updateAll)
  group.drawAll = profileFn(k..' draw', group.drawAll)
end

return function()
  if (not msgBus.send(msgBus.IS_CONSOLE_ENABLED)) then
    return
  end
  -- add total average execution time
  table.insert(profileData, Color.WHITE)
  table.insert(profileData, '\ntotal avg execution time: '..string.format('%0.2f', totalAverageExecutionTime))
  -- reset
  totalAverageExecutionTime = 0

  local wrapLimit = 400
  guiTextLayer:addf(profileData, wrapLimit, 'right', love.graphics.getWidth() - wrapLimit - 10, 10)
  -- reset
  profileData = {}
end