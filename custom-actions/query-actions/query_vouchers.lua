local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

local QueryVouchers = setmetatable({}, { __index = NeuroAction })
QueryVouchers.__index = QueryVouchers

function QueryVouchers:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function QueryVouchers:_get_name()
    return "query_vouchers"
end

function QueryVouchers:_get_description()
    return "Gets all the vouchers redeemed so far."
end

function QueryVouchers:_get_schema()
    return JsonUtils.wrap_schema({})
end

function QueryVouchers:_validate_action()
    if not G.vouchers or #G.vouchers.cards == 0 then
        return ExecutionResult.failure("No vouchers have been redeemed.")
    end
    return ExecutionResult.success()
end

function QueryVouchers:_execute_action(state)
    local parts = GetRunText.get_hand_details(G.vouchers.cards)
    Context.send("These are the vouchers you have collected:\n" .. table.concat(parts, "\n"), true)
end

return QueryVouchers
