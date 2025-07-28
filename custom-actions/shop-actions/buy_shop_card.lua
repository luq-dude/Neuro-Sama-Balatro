local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local BuyShopCard = setmetatable({}, { __index = NeuroAction })
BuyShopCard.__index = BuyShopCard

function BuyShopCard:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end


function BuyShopCard:_get_name()
    return "buy_card"
end

function BuyShopCard:_get_description()
    return "Buy a card from the shop, this will be from the card category"
end

local function card_actions()
    return {"buy","buy and use"}
end

function BuyShopCard:_get_schema()
    local hand_length = RunHelper:get_hand_length(G.shop_jokers.cards)
    return JsonUtils.wrap_schema({
		card_action = {
			enum = card_actions()
		},
        card_index = {
            enum = hand_length
        }
    })
end

function BuyShopCard:_validate_action(data, state)
    local selected_action = data:get_string("card_action")
    local selected_index = data._data["card_index"]

    local option = card_actions()
    if not RunHelper:value_in_table(option,selected_action) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("card_action"))
    end

    local valid_hand_indices = RunHelper:get_hand_length(G.shop_jokers.cards)
    if not RunHelper:value_in_table(valid_hand_indices,selected_index) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("card_index"))
    end

    local card = G.shop_jokers.cards[selected_index]

    if card.children.price.parent.cost > G.GAME.dollars then
        return ExecutionResult.failure("You do not have the money to buy this card")
    end

    if card.children.buy_button == nil and selected_action == "buy" then
        return ExecutionResult.failure("You can not buy this card, maybe try to buy and use it.")
    end

    if card.children.buy_and_use_button == nil and selected_action == "buy and use" then
        return ExecutionResult.failure("You can only buy this card")
    end

    if card.ability.set == "Joker" and #G.jokers.cards >= G.jokers.config.card_limit then
        return ExecutionResult.failure("You do not have enough space to add a joker.")
    end

    if card.ability.set ~= "Joker" and selected_action == "buy" and #G.consumeables.cards >= G.consumeables.config.card_limit then -- might cause issues with modded sets if they don't use G.consumeables
        return ExecutionResult.failure("You can not store this card, due to there already being too many consumables stored. You should either use of some of the stored consumables or just buy this one.")
    end

    -- we do this to load buy_and_use_button as visible is only set after being highlighted and because cards buy_button visible are only set to true if they are highlighted
    G.shop_jokers:add_to_highlighted(card,true) -- need to wait a frame after this is called for card:draw to create the button hence the event
    G.E_MANAGER:add_event(Event({
        trigger = "before",
        blocking = false,
        function ()
            if card.ability.set ~= "Joker" and selected_action == "buy and use" and card.children.buy_and_use_button.states.visible == false then
                G.shop_jokers:unhighlight_all()
                return ExecutionResult.failure("You can not buy and use this card, as it does not allow it. You should try to buy it")
            end

            if card.ability.set ~= "Joker" and selected_action == "buy" and card.children.buy_button.states.visible == false then
                G.shop_jokers:unhighlight_all()
                return ExecutionResult.failure("You can not buy this card, as it does not allow it. You should try to buy and use it")
            end
            G.shop_jokers:unhighlight_all()
        end}))

    state["selected_action"] = selected_action
    state["selected_index"] = selected_index
    return ExecutionResult.success()
end

function BuyShopCard:_execute_action(state)
    local selected_action = state["selected_action"]
    local selected_index = state["selected_index"]

    local card = G.shop_jokers.cards[selected_index]

    if selected_action == "buy" then
        card.children.buy_button.definition.nodes[1].config.button_UIE:click()
    else
        card.children.buy_and_use_button.definition.nodes[1].config.button_UIE:click()
    end

    self.hook:register_store_actions(3,self.hook)
end

return BuyShopCard