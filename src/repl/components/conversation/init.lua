-- Creates a conversation thread that we can resume at any time

local conversationMt = {
  text = '',
  options = {} -- list of conversation options
}
conversationMt.__index = conversationMt

local dialogueRoutine = function(dialogue)
  return coroutine.create(function()
    for i=1, #dialogue do
      coroutine.yield(
        setmetatable(dialogue[i], conversationMt)
      )
    end
  end)
end

local function startConversation(self, conversation)
  self.conversate = dialogueRoutine(conversation)
  local _, nextScript = coroutine.resume(self.conversate)

  self.nextScript = nextScript
  return nextScript
end

local defaultActionsMt = {
  nextConversation = function(self, data)
    return startConversation(self, self.conversationMap[data.id])
  end,

  giveReward = function(_, reward)
    print(
      'give reward!\n',
      Inspect(reward)
    )
  end,

  giveQuest = function(_, quest)
    print(
      'give quest!\n',
      Inspect(quest)
    )
  end
}
defaultActionsMt.__index = defaultActionsMt

local Conversation = {
  new = function(self, conversationMap, customActions)

    if customActions and customActions.nextConversation then
      error('`nextConversation` action may not be redefined')
    end
    local actions = setmetatable(customActions or {}, defaultActionsMt)

    local execActions = function(self, actionsList)
      for i=1, #actionsList do
        local a = actionsList[i]
        actions[a.action](self, a.data)
      end
    end

    --[[
      For action blocks we want to trigger them immediately
      and automatically move to the next block in the conversation
    ]]
    local function autoAdvanceIfNeeded(self, nextScript)
      local autoAdvance = nextScript and nextScript.actionOnly
      if autoAdvance then
        execActions(self, nextScript.actions)
        self:resume()
      end
    end

    local c = {
      nextScript = nil,

      conversationMap = conversationMap,
      conversationId = nil,

      set = function(self, conversationId)
        local isNewConvo = conversationId ~= self.conversationId
        if isNewConvo then
          local nextScript = actions.nextConversation(self, { id = conversationId })
          autoAdvanceIfNeeded(self, nextScript)
          self.conversationId = conversationId
        elseif (not conversationId) then
          self:stop()
        end

        return self
      end,

      resume = function(self, optionSelected)
        -- prevent resuming if an option must be chosen
        if (not optionSelected) and self:hasOptions() then
          return self
        end

        local isAlive, nextScript = coroutine.resume(self.conversate)
        self.nextScript = nextScript
        autoAdvanceIfNeeded(self, nextScript)

        if self:isDone() then
          self:stop()
        end

        return self
      end,

      -- returns option selection success
      selectOption = function(self, optionNumber)
        if (self:isDone()) then
          return false
        end

        local options = self.nextScript.options
        local o = options[optionNumber]
        if o then
          self:resume(true)
          execActions(self, o.actions)
          return true
        end

        return false
      end,

      hasOptions = function(self)
        return (not self:isDone()) and #self.nextScript.options > 0
      end,

      get = function(self)
        -- a nil value means no script exists
        return self.nextScript
      end,

      isDone = function(self)
        return self.nextScript == nil
      end,

      stop = function(self)
        self.nextScript = nil
        self.conversationId = nil
        return self
      end,
    }

    return c
  end,
}

return Conversation