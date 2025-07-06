local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local SkipBlind = setmetatable({}, {__index = NeuroAction})
SkipBlind.__index = SkipBlind

function SkipBlind:new(actionWindow, state)
     local obj = NeuroAction.new(self, actionWindow)
     return obj
end

function SkipBlind:_get_name()
    return "skip_blind"
end

function SkipBlind:_get_description()
    return "Skip the selected blind"
end


function SkipBlind:_get_schema()
    return {}
end

function SkipBlind:_validate_action()
    return ExecutionResult.success()
end

function SkipBlind:_execute_action(state)

end
