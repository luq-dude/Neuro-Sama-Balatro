local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local QueryConsumables = setmetatable({}, { __index = NeuroAction })
QueryConsumables.__index = QueryConsumables

function QueryConsumables:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function QueryConsumables:_get_name()
    return "query_consumables"
end

function QueryConsumables:_get_description()
    return "Gets the consumables currently owned."
end

function QueryConsumables:_get_schema()
    return JsonUtils.wrap_schema({})
end

function QueryConsumables:_validate_action()
    return ExecutionResult.success()
end

function QueryConsumables:_execute_action(state)
    Context.send(RunContext.get_consumeables_text(), true)
end

return QueryConsumables
