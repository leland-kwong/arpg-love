local InputContext = {}

local activeContext = nil

function InputContext.set(context)
  activeContext = context
end

function InputContext.is(contextName)
  return contextName == activeContext
end

function InputContext.get()
  return activeContext
end

return InputContext