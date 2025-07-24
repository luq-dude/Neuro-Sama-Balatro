local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")

local RerollShop = setmetatable({}, { __index = NeuroAction })
RerollShop.__index = RerollShop

function RerollShop:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end


function RerollShop:_get_name()
    return "reroll_shop"
end

function RerollShop:_get_description()
    return "Reroll the shop, this will add new cards to the shop if you have the money or if you have free rerolls."
end

function RerollShop:_get_schema()
    return nil
end

function RerollShop:_validate_action(data, state)
	return ExecutionResult.success()
end

function RerollShop:_execute_action(state)
	local reroll_button = G.shop.definition.nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].config.button_UIE.children[1]
	reroll_button:click()
end

return RerollShop