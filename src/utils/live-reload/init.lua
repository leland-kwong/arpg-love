local getModulePath = require 'modules.get-module-path'
local dynamicRequire = require 'utils.dynamic-require'

local watchers = {}
local state = {
  lastModified = {}
}

local fileDataCache = {}

local function checkFileChange(file)
  local fData = fileDataCache[file]
  if (not fData) then
    local fd = io.open(file)
    fData = {
      data = fd,
      lastModified = fd:read('*a')
    }
    fileDataCache[file] = fData
  end

  if (not fData) then
    return false
  end

  local fd = io.open(file)
  local nextVal = fd:read('*a')
  fd:close()
  local hasChanged = nextVal ~= fData.lastVal
  if hasChanged then
    fData.lastVal = nextVal
  end
  return hasChanged
end

local LiveReload = {
  clock = 0,
  options = {
    rootDir = '',
    updateFrequency = 0.1,
    enabled = false,
  },
  setOptions = function(self, options)
    local _o = self.options
    for k,v in pairs(options) do
      _o[k] = v
    end
    return self
  end,
  update = function(self, dt)
    if (not self.options.enabled) then
      return
    end

    self.clock = self.clock + dt

    if self.clock >= self.options.updateFrequency then
      self.clock = 0

      for file in pairs(watchers) do
        local hasModified, isRemoved = checkFileChange(file)
        local w = watchers[file]
        if isRemoved then
          w:stop()
        elseif hasModified then
          print('[LIVE RELOAD FILE CHANGED]')
          local ok, err = pcall(function()
            w:reloadAll()
          end)
          if (not ok) then
            print('[LIVE RELOAD]', err)
          end
        end
      end
    end
    return self
  end,
  _getWatchers = function(self)
    return watchers
  end
}

local function watchFile(rootDir, file, fileToReload, reloadOptions)
  local actualPath = getModulePath(file)
  if (not actualPath) then
    error('could not load file `'..file..'`')
  end

  local fullPath = rootDir..'/'..actualPath

  if (not fullPath) then
    return
  end

  local watchersList = watchers[fullPath]
  if (not watchersList) then
    watchersList = {
      filesToHotReload = {},
      stop = function(self)
        print('[WATCH FILE REMOVED]', fullPath)
        watchersList[fullPath] = nil
      end,
      reloadAll = function(self)
        for file,options in pairs(self.filesToHotReload) do
          LiveReload(file, options)
        end
      end
    }
    watchers[fullPath] = watchersList
  end

  watchersList.filesToHotReload[fileToReload] = reloadOptions
end

local optionsMt = {
  -- make all submodules also live reload
  includeSubModules = false
}
optionsMt.__index = optionsMt

setmetatable(LiveReload, {
  __call = function(self, rootFile, options)
    if (not self.options.enabled) then
      return loadFn(require)
    end

    options = setmetatable(options or {}, optionsMt)
    local recentlyReloaded = {}
    local oRequire = require

    local _includeSubModules = options.includeSubModules or includeSubModules

    watchFile(self.options.rootDir, rootFile, rootFile, options)

    -- override require to to watch the file and live reload
    if _includeSubModules then
      require = function(path)
        local ok, result = pcall(function()
          watchFile(self.options.rootDir, path, rootFile, options)

          if (not recentlyReloaded[path]) then
            recentlyReloaded[path] = true
            return dynamicRequire(path)
          else
            return oRequire(path)
          end

        end)

        return result
      end
    end

    local ok, module = xpcall(function()
      return dynamicRequire(rootFile)
    end, function(err)
      print(err)
    end)

    require = oRequire
    return module
  end
})

return LiveReload