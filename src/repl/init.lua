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
  init = function(self)
    Component.addToGroup(self, 'all')
  end,
  update = function(self, dt)
    local rootDir = '/repl/experiments'
    local files = love.filesystem.getDirectoryItems(rootDir)
    for _,f in ipairs(files) do
      local ok, result = pcall(function()
        return reloadFile(rootDir..'/'..f)
      end)
      if (not ok) then
        print('[ERROR]', result)
      end
    end
  end,
})
