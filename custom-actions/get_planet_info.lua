local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")
local RunContext = ModCache.load("run_context.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local PlanetInfo = setmetatable({}, { __index = NeuroAction })
PlanetInfo.__index = PlanetInfo

function PlanetInfo:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
	obj.hook = state[1]
    return obj
end

function PlanetInfo:_get_name()
    return "get_hand_information"
end

function PlanetInfo:_get_description()
    return "Get the current information relating to the poker hand available."
end

function PlanetInfo:_get_schema()
    return JsonUtils.wrap_schema({},false)
end

function PlanetInfo:_validate_action()
    return ExecutionResult.success()
end

function PlanetInfo:_execute_action(state)
	Context.send(table.concat(RunContext:hand_type_information(),"\n"))
	self.hook:play_card(0,false)
end

return PlanetInfo
