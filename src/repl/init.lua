local Component = require 'modules.component'

local state = {
  lastModified = {}
}

local function reloadFile(file)
  local info = love.filesystem.getInfo(file)
  local shouldReload = info.modtime ~= state.lastModified[file]
  state.lastModified[file] = info.modtime

  -- reload the file
  if shouldReload then
    print('\n-- RELOAD -- '..file)
    love.filesystem.load(file)()
  end
end

Component.create({
  updateFrequency = 0.1,
  init = function(self)
    Component.addToGroup(self, 'all')
    self.clock = 0
  end,
  update = function(self, dt)
    self.clock = self.clock + dt

    if self.clock >= self.updateFrequency then
      self.clock = 0

      local rootDir = '/repl/active-experiments'
      local files = love.filesystem.getDirectoryItems(rootDir)
      for _,f in ipairs(files) do
        local ok, result = pcall(function()
          return reloadFile(rootDir..'/'..f)
        end)
        if (not ok) then
          print('[ERROR]', result)
        end
      end
    end
  end,
})
