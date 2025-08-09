local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

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
    return JsonUtils.wrap_schema({},false)
end

function RerollShop:_validate_action(data, state)
    if G.GAME.current_round.free_rerolls >= 1 then
        return ExecutionResult.success("You have skipped this round using a free reroll, you have " .. tostring(G.GAME.current_round.free_rerolls) .. " free rerolls left.")
    else
        return ExecutionResult.success("You have skipped this round using your money, it cost: " .. tostring(G.GAME.current_round.reroll_cost))
    end
end

function RerollShop:_execute_action(state)
	local reroll_button = G.shop.definition.nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].config.button_UIE.children[1]
	reroll_button:click()
end

return RerollShop