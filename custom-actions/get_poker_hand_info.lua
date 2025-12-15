local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local PokerHandInfo = setmetatable({}, { __index = NeuroAction })
PokerHandInfo.__index = PokerHandInfo

function PokerHandInfo:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function PokerHandInfo:_get_name()
    return "get_poker_hand_information"
end

function PokerHandInfo:_get_description()
    return "Gets the level and stats for every poker hand."
end

function PokerHandInfo:_get_schema()
    return JsonUtils.wrap_schema({})
end

function PokerHandInfo:_validate_action()
    return ExecutionResult.success()
end

function PokerHandInfo:_execute_action(state)
	Context.send(table.concat(RunContext:hand_type_information(),"\n"))
	NEURO.DEC_STATE()
end

return PokerHandInfo
