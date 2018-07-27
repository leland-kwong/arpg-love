local json = require "lua_modules.json"

local function loadJsonFile(filename)
	local jsonString = ""
	for line in io.lines(filename) do
		jsonString = jsonString..line
	end
	return json.decode(jsonString)
end

return loadJsonFile