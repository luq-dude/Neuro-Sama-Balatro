local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")
local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local JokerInteraction = ModCache.load("custom-actions/joker_interaction.lua")
local UseConsumables = ModCache.load("custom-actions/use_consumables.lua")

local ExitShop = setmetatable({}, { __index = NeuroAction })
ExitShop.__index = ExitShop

function ExitShop:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function ExitShop:_get_name()
    return "exit_shop"
end

function ExitShop:_get_description()
    return "This will exit the shop and take you to picking the next blind."
end

function ExitShop:_get_schema()
    return JsonUtils.wrap_schema({},false)
end

function ExitShop:_validate_action(data, state)
    return ExecutionResult.success()
end

function ExitShop:_execute_action(state)
	local exit_shop_button = G.shop.definition.nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].config.button_UIE.children[1]
	exit_shop_button:click()
end

return ExitShop