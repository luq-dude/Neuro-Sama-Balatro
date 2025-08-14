local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")
local GetRunText = ModCache.load("get_run_text.lua")

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
    return "This will buy a voucher available in the shop."
end

function BuyVoucher:_get_schema()
	local hand_length = RunHelper:get_hand_length(G.shop_vouchers.cards)
    if #G.shop_vouchers.cards > 1 then
        return JsonUtils.wrap_schema({
            voucher_index = {
                enum = hand_length
        }
        })
    end
    return JsonUtils.wrap_schema({},false)
end

function BuyVoucher:_validate_action(data, state)
    local selected_index = data._data["voucher_index"] or 1
	local voucher = G.shop_vouchers.cards[selected_index]

    if ((G.GAME.dollars-G.GAME.bankrupt_at) - voucher.children.price.parent.cost < 0) then
        return ExecutionResult.failure("You do not have the money to buy the voucher.")
    end

    if #G.shop_vouchers.cards <= 1 then
        return ExecutionResult.success("Bought " .. string.sub(GetRunText:get_shop_text({voucher})[1], 2))
    end

    local valid_voucher_indices = RunHelper:get_hand_length(G.shop_vouchers.cards)
    if not RunHelper:value_in_table(valid_voucher_indices,selected_index) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("voucher_index"))
    end

    state["voucher_index"] = selected_index
    return ExecutionResult.success("Bought " .. string.sub(GetRunText:get_shop_text({voucher})[1], 2))
end

function BuyVoucher:_execute_action(state)
    local selected_index = state["voucher_index"] or 1
	local voucher = G.shop_vouchers.cards[selected_index]

	voucher.children.buy_button.definition.nodes[1].config.button_UIE:click()

	self.hook:register_store_actions(2,self.hook)
end

return BuyVoucher