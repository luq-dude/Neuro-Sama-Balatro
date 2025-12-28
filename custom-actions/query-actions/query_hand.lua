local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

local QueryHand = setmetatable({}, { __index = NeuroAction })
QueryHand.__index = QueryHand

function QueryHand:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function QueryHand:_get_name()
    return "query_hand"
end

function QueryHand:_get_description()
    return "Gets the cards currently in hand."
end

function QueryHand:_get_schema()
    return JsonUtils.wrap_schema({})
end

function QueryHand:_validate_action()
    if not G.hand or #G.hand.cards == 0 then
        return ExecutionResult.failure("There is no hand drawn to get the cards for.")
    end
    return ExecutionResult.success()
end

function QueryHand:_execute_action(state)
    local hand = GetRunText.get_hand_details(G.hand.cards, true)
    Context.send("These are the cards currently in hand:\n" .. table.concat(hand), true)
    NEURO.DEC_STATE()
end

return QueryHand
