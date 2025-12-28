local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local QueryModifiers = setmetatable({}, { __index = NeuroAction })
QueryModifiers.__index = QueryModifiers

function QueryModifiers:new(actionWindow)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function QueryModifiers:_get_name()
    return "query_modifiers"
end

function QueryModifiers:_get_description()
    return "Get the description of all of the card modifiers and what they do."
end

function QueryModifiers:_get_schema()
    return JsonUtils.wrap_schema({})
end

function QueryModifiers:_validate_action(data, state)
    return ExecutionResult.success()
end

function QueryModifiers:_execute_action(state)
    Context.send(RunContext.get_all_modifier_desc(), true)
    NEURO.DEC_STATE_IF_MODE("solo")
end

return QueryModifiers
