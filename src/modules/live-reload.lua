local getModulePath = require 'modules.get-module-path'

local watchers = {}
local state = {
  lastModified = {}
}

local function watchFile(file, callback)
  local fullPath = getModulePath(file)

  if (not fullPath) then
    return
  end

  local watchersList = watchers[fullPath]
  if (not watchersList) then
    watchersList = {
      callbacks = {},
      stop = function(self)
        print('[WATCH FILE REMOVED]', fullPath)
        watchersList[fullPath] = nil
      end,
      execAll = function(self)
        local function removeWatcher(index)
          table.remove(self.callbacks, index)
        end

        for i=1, #self.callbacks do
          self.callbacks[i]()
        end
      end
    }
    watchers[fullPath] = watchersList
  end

  table.insert(watchersList.callbacks, callback)
end

local function checkFileChange(file)
  local info = love.filesystem.getInfo(file)
  local isRemoved = false
  if (not info) then
    isRemoved = true
    return false, isRemoved
  end

  local fileChanged = (info.type == 'file') and
    (
      state.lastModified[file] and
      (info.modtime ~= state.lastModified[file])
    )
  state.lastModified[file] = info.modtime
  return fileChanged, isRemoved
end

local optionsMt = {
  -- make all submodules also live reload
  includeSubModules = false
}
optionsMt.__index = optionsMt

local function clearPkgCache(path)
  if package.loaded[path] then
    package.loaded[path] = nil
  end
end

local LiveReload = setmetatable({
  clock = 0,
  options = {
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
          local ok, err = pcall(function()
            w:execAll()
          end)
          if (not ok) then
            print('[LIVE RELOAD]', err)
          end
        end
      end
    end
    return self
  end
}, {
  __call = function(self, loadFn, options)
    if (not self.options.enabled) then
      return loadFn(require)
    end

    options = setmetatable(options or {}, optionsMt)
    local watchedPaths = {}
    local recentlyReloaded = {}
    local oRequire = require

    local reloadHandler = function(dynamicRequire)
      recentlyReloaded = {}
      loadFn(dynamicRequire)
    end

    local function dynamicRequire(path, includeSubModules)
      local _includeSubModules = options.includeSubModules or includeSubModules

      clearPkgCache(path)

      local onReloadCallback = function()
        return reloadHandler(dynamicRequire)
      end

      if (not watchedPaths[path]) then
        watchedPaths[path] = true
        watchFile(path, onReloadCallback)
      end

      -- override require to to watch the file and live reload
      if _includeSubModules then
        require = function(path)
          local ok, result = pcall(function()
            if (not watchedPaths[path]) then
              watchedPaths[path] = true
              watchFile(path, onReloadCallback)
            end

            if (not recentlyReloaded[path]) then
              recentlyReloaded[path] = true
              clearPkgCache(path)
            end

            return oRequire(path)
          end)

          return result
        end
      end

      local ok, module = xpcall(function()
        return oRequire(path)
      end, function(err)
        print(err)
      end)

      require = oRequire
      return module
    end
    reloadHandler(dynamicRequire)
  end
})

return LiveReload