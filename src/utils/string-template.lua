local defaultOptions = {
  delimiters = {'{', '}'}
}

-- returns a parser function with the provided options
local function TemplateParser(options)
  options = options or defaultOptions
  local d1, d2 = unpack(options.delimiters)
  local pattern = d1..'[^'..d1..d2..']*'..d2
  local delimiterLen = #d1

  return function(txt, data)
    local i = 1
    return coroutine.wrap(function()
      while i <= #txt do
        local start, _end = string.find(txt, pattern, i)
        if start == nil then
          local isLastStringFragment = i > 1
          if isLastStringFragment then
            coroutine.yield(string.sub(txt, i))
          -- no variables in template so we just return entire string
          else
            coroutine.yield(txt)
          end
          return
        end
        -- handle string fragment in between variable fragments
        if (start ~= i) then
          local subStart = i
          local subEnd = start - 1
          coroutine.yield(string.sub(txt, subStart, subEnd), nil, start, _end)
        end

        local key = string.sub(txt, start + delimiterLen, _end - delimiterLen)
        local fragmentData = data[key]
        coroutine.yield(key, fragmentData, start, _end)
        i = _end + 1
      end
    end)
  end
end

return TemplateParser