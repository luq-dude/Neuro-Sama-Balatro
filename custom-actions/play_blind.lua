local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PlayBlind = setmetatable({}, {__index = NeuroAction})
PlayBlind.__index = PlayBlind

function PlayBlind:new(actionWindow, state)
     local obj = NeuroAction.new(self, actionWindow)
     return obj
end

function PlayBlind:_get_name()
    return "play_blind"
end

function PlayBlind:_get_description()
    return "Start the selected blind"
end


function PlayBlind:_get_schema()
    return {}
end

function PlayBlind:_validate_action()
    return ExecutionResult.success()
end

function PlayBlind:_execute_action(state)
    
end
