local typeCheck = require("utils.type-check")

return function(fn, predicate)
	typeCheck.validate(fn, typeCheck.FUNCTION)
	typeCheck.validate(predicate, typeCheck.FUNCTION)
	
	return function(a1, a2, a3, a4, a5, a6)
		local shouldCall = predicate(a1, a2, a3, a4, a5, a6)
		if shouldCall then
			fn(a1, a2, a3, a4, a5, a6)
		end
	end
end