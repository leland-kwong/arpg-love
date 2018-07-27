local function print_grid(grid, separator, replacer)
	separator = separator or ","
	local output = "\n"
	for y=1, #grid do
		local row = grid[y]
		for x=1, #row do
			local value = replacer and replacer(row[x]) or row[x]
			output = output..separator..value
		end
		output = output.." -"..y.."\n"
	end
	print(output)
end

return print_grid