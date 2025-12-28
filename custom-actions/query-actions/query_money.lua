local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")

local QueryMoney = setmetatable({}, { __index = NeuroAction })
QueryMoney.__index = QueryMoney

function QueryMoney:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function QueryMoney:_get_name()
    return "query_money"
end

function QueryMoney:_get_description()
    return "Gets the amount of money you currently have."
end

function QueryMoney:_get_schema()
    return JsonUtils.wrap_schema({})
end

function QueryMoney:_validate_action()
    return ExecutionResult.success()
end

function QueryMoney:_execute_action(state)
    Context.send(string.format("You currently have $%d", G.GAME.dollars), true)
end

return QueryMoney
