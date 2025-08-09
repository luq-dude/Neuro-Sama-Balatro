local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")
local BuyBooster = setmetatable({}, { __index = NeuroAction })
BuyBooster.__index = BuyBooster

function BuyBooster:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function BuyBooster:_get_name()
    return "buy_booster_pack"
end

function BuyBooster:_get_description()
    return "Buy a booster pack in shop. These contain a certain number of cards that you can choose from."
end

function BuyBooster:_get_schema()
	local hand_length = RunHelper:get_hand_length(G.shop_booster.cards)
    return JsonUtils.wrap_schema({
        booster_index = {
            enum = hand_length
        }
    })
end

function BuyBooster:_validate_action(data, state)
	local selected_index = data._data["booster_index"]

	local valid_booster_indices = RunHelper:get_hand_length(G.shop_booster.cards)
    if not RunHelper:value_in_table(valid_booster_indices,selected_index) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("booster_index"))
    end

	local booster = G.shop_booster.cards[selected_index]

    if ((G.GAME.dollars-G.GAME.bankrupt_at) - booster.children.price.parent.cost < 0) then
        return ExecutionResult.failure("You do not have the money to buy this pack")
    end

	state["booster_index"] = selected_index
    return ExecutionResult.success("opening " .. booster.ability.name)
end

function BuyBooster:_execute_action(state)
	local selected_index = state["booster_index"]

	sendDebugMessage(type(selected_index))
	local booster = G.shop_booster.cards[selected_index]

	booster.children.buy_button.definition.nodes[1].config.button_UIE:click()
end

return BuyBooster