-- Load FFI
local ffi = require("ffi")

if ffi.os == "Windows" then
	ffi.cdef([[
	typedef int BOOL;
	typedef long LONG;
	typedef struct{
		LONG x, y;
	}POINT, *LPPOINT;
	BOOL GetCursorPos(LPPOINT);
  ]])
end

local ppoint = ffi.new("POINT[1]")
local pos = {}

return function()
  if ffi.C.GetCursorPos(ppoint) == 0 then
    error("Couldn't get cursor position!", 2)
  end
  pos.x, pos.y = ppoint[0].x, ppoint[0].y
  return pos
end