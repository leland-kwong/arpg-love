--Threaded log append/read
local lru = require 'utils.lru'

local dirPrefix = 'log/'

local function getDirFromPath(path)
  local lastSlash, s, e = path, string.find(path, '/[^/]*$')
  return string.sub(path, 1, s)
end

local function openFile(path)
  local saveDir = love.filesystem.getSaveDirectory()
  local absolutePath = saveDir..'/'..path
  return io.open(absolutePath, 'a+')
end

local logCache = {
  files = lru.new(20, nil, function(_, file)
    file:close()
  end),
  get = function(self, path)
    local file = self.files:get(path)
    if (not file) then
      local actualPath = dirPrefix..path
      -- create directory if needed
      local dir = getDirFromPath(actualPath)
      local info = love.filesystem.getInfo(dir)
      if (not info) then
        love.filesystem.createDirectory(dir)
      end

      file = openFile(actualPath)
      self.files:set(path, file)
    end
    return file
  end,
  unset = function(self, path)
    local file = self.files:get(path)
    if file then
      file:close()
      self.files:delete(path)
    end
  end
}

local function deleteLogFile(path)
  local file = logCache:unset(path)
  local actualPath = dirPrefix..path
  local info = love.filesystem.getInfo(actualPath)
  local channel = love.thread.getChannel('logDelete')
  if info then
    local success = love.filesystem.remove(actualPath)
    channel:push(success)
  else
    channel:push(true)
  end
end

local queue = {}

local numArgs = 3

local function processEvents(queue, callback)
  local a, b, c = table.remove(queue, 1),
    table.remove(queue, 1),
    table.remove(queue, 1)
  return a, b, c
end

local function appendEntry(path, data)
  local file = logCache:get(path)
  local ok, errors = pcall(function()
    file:seek('end')
    return file:write(data)
  end)
  local channel = love.thread.getChannel('logAppend')
  channel:push(ok)
  if (not ok) then
    print(ok)
  end
end

local function readLogFile(path)
  local ok, err = pcall(function()
    local file = logCache:get(path)
    file:seek('set')

    local logAsString = file:read('*a')
    local channel = love.thread.getChannel('logRead.'..path)
    channel:push(logAsString)
    channel:push('done')
  end)
  if not ok then
    print(err)
  end
end

local actionHandlers = {
  APPEND = appendEntry,
  READ = readLogFile,
  DELETE = deleteLogFile
}

local function observeThread()
  local channel = love.thread.getChannel('ASYNC_WRITE_TEST')
  while true do
    local message = channel:demand()
    table.insert(queue, message)
    for i=1, channel:getCount() do
      table.insert(queue, channel:pop())
    end
    while #queue >= numArgs do
      local event, a, b = processEvents(queue, appendEntry)
      actionHandlers[event](a, b)
    end
  end
end
observeThread()