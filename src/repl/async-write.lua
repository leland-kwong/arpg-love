--Threaded log append/read
local lru = require 'utils.lru'

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
      -- create directory if needed
      local dir = getDirFromPath(path)
      local info = love.filesystem.getInfo(dir)
      if (not info) then
        love.filesystem.createDirectory(dir)
      end

      file = openFile(path)
      self.files:set(path, file)
    end
    return file
  end
}
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
  if (not ok) then
    love.thread.getChannel('logAppendError'):push(errors)
  else
    love.thread.getChannel('logAppendSuccess'):push(true)
  end
end

local function readLogFile(path)
  local file = logCache:get(path)
  file:seek('set')
  local output = ''
  for line in file:lines() do
    output = output..line
  end
  love.thread.getChannel('logRead'):push(output)
end

local actionHandlers = {
  APPEND = appendEntry,
  READ = readLogFile
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