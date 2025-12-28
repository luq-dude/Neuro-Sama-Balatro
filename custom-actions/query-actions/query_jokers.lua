local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local QueryJokers = setmetatable({}, { __index = NeuroAction })
QueryJokers.__index = QueryJokers

function QueryJokers:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function QueryJokers:_get_name()
    return "query_jokers"
end

function QueryJokers:_get_description()
    return "Gets the jokers currently owned."
end

function QueryJokers:_get_schema()
    return JsonUtils.wrap_schema({})
end

function QueryJokers:_validate_action()
    return ExecutionResult.success()
end

function QueryJokers:_execute_action(state)
    Context.send(RunContext.get_jokers_text(), true)
end

return QueryJokers
