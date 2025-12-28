local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local QueryShop = setmetatable({}, { __index = NeuroAction })
QueryShop.__index = QueryShop

function QueryShop:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function QueryShop:_get_name()
    return "query_shop"
end

function QueryShop:_get_description()
    return "Gets what is currently being sold in shop."
end

function QueryShop:_get_schema()
    return JsonUtils.wrap_schema({})
end

function QueryShop:_validate_action()
    return ExecutionResult.success()
end

function QueryShop:_execute_action(state)
    local ctx = RunContext.get_shop_context()
    Context.send(ctx.state, true)
end

return QueryShop
