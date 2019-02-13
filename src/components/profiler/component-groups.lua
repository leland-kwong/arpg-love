local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local config = require 'config.config'

local guiTextLayer = GuiText.create({
  group = Component.groups.system,
  font = require'components.font'.debug.font,
  outline = false
})

local profileData = {}
local totalAverageExecutionTime = 0

local function profileFn(groupName, callback)
  return require'utils.perf'({
    resetEvery = 1000,
    done = function(_, totalTime, callCount)
      if (not config.enableConsole) then
        return
      end

      local averageTime = totalTime / callCount
      totalAverageExecutionTime = totalAverageExecutionTime + averageTime
      if averageTime >= 0.1 then
        table.insert(profileData, Color.WHITE)
        table.insert(profileData, groupName..': '..string.format('%0.2f', averageTime)..'\n')
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
  if (not config.enableConsole) then
    profileData = {}
    return
  end
  -- add total average execution time
  table.insert(profileData, Color.WHITE)
  table.insert(profileData, '\ntotal avg execution time: '..string.format('%0.2f', totalAverageExecutionTime))
  -- reset
  totalAverageExecutionTime = 0

  local wrapLimit = 400
  guiTextLayer:addf(profileData, wrapLimit, 'right', love.graphics.getWidth() - wrapLimit - 5, 5)
  -- reset
  profileData = {}
end