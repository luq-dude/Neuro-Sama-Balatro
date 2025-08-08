local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")
local RunContext = ModCache.load("run_context.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local PokerHandInfo = setmetatable({}, { __index = NeuroAction })
PokerHandInfo.__index = PokerHandInfo

function PokerHandInfo:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
	obj.hook = state[1]
    return obj
end

function PokerHandInfo:_get_name()
    return "get_poker_hand_information"
end

function PokerHandInfo:_get_description()
    return "Gets the level and stats for every poker hand."
end

function PokerHandInfo:_get_schema()
    return JsonUtils.wrap_schema({},false)
end

function PokerHandInfo:_validate_action()
    return ExecutionResult.success()
end

function PokerHandInfo:_execute_action(state)
	Context.send(table.concat(RunContext:hand_type_information(),"\n"))
    if G.STATE == G.STATES.SHOP then
        self.hook:register_store_actions(0)
        return
    end
	self.hook:play_card(0)
end

return PokerHandInfo
