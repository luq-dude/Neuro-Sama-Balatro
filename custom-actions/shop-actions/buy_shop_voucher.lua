local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local BuyVoucher = setmetatable({}, { __index = NeuroAction })
BuyVoucher.__index = BuyVoucher

function BuyVoucher:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function BuyVoucher:_get_name()
    return "buy_voucher"
end

function BuyVoucher:_get_description()
    return "This will buy the voucher available in the shop."
end

function BuyVoucher:_get_schema()
	local hand_length = RunHelper:get_hand_length(G.shop_vouchers.cards)
    return JsonUtils.wrap_schema({})
end

function BuyVoucher:_validate_action(data, state)
	local voucher = G.shop_vouchers.cards[1]

    if voucher.children.price.parent.cost > G.GAME.dollars then
        return ExecutionResult.failure("You do not have the money to buy the voucher.")
    end

    return ExecutionResult.success()
end

function BuyVoucher:_execute_action(state)
	local voucher = G.shop_vouchers.cards[1]

	voucher.children.buy_button.definition.nodes[1].config.button_UIE:click()

	self.hook:register_store_actions(2 * G.SPEEDFACTOR,self.hook)
end

return BuyVoucher