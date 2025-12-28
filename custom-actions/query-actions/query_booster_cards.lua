local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local QueryBoosterCards = setmetatable({}, { __index = NeuroAction })
QueryBoosterCards.__index = QueryBoosterCards

function QueryBoosterCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function QueryBoosterCards:_get_name()
    return "query_booster_cards"
end

function QueryBoosterCards:_get_description()
    return "Gets the cards in the currently opened booster pack."
end

function QueryBoosterCards:_get_schema()
    return JsonUtils.wrap_schema({})
end

function QueryBoosterCards:_validate_action()
    if not G.pack_cards or # G.pack_cards.cards == 0 then
        return ExecutionResult.failure("There is no booster pack currently opened.")
    end
    return ExecutionResult.success()
end

function QueryBoosterCards:_execute_action(state)
   Context.send(RunContext.booster(), true)
end

return QueryBoosterCards
