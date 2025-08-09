local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local SkipPack = ModCache.load("custom-actions/skip_pack.lua")
local JokerInteraction = ModCache.load("custom-actions/joker_interaction.lua")
local UseConsumable = ModCache.load("custom-actions/use_consumables.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PickCards = setmetatable({}, { __index = NeuroAction })
PickCards.__index = PickCards

local cards_picked = 0

local function pick_pack_card(delay,hook)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PickCards:new(window, {hook}))
            window:add_action(SkipPack:new(window,{hook}))
            if #G.jokers.cards > 0 then
                window:add_action(JokerInteraction:new(window, {hook,{PickCards,SkipPack},UseConsumable}))
            end

            if #G.consumeables.cards > 0 then
                window:add_action(UseConsumable:new(window, {hook,{PickCards,SkipPack},JokerInteraction}))
            end
            local query,state = RunHelper:get_query_string()
            window:set_force(0.0, query, state, true)
            window:register()
            return true
        end
    }
    ))
end

function PickCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function PickCards:_get_name()
    return "pick_cards"
end

function PickCards:_get_description()
    local description = string.format("Pick cards to add to your deck. You can pick a max of " ..
    SMODS.OPENED_BOOSTER.config.center.config.choose
    .. " cards "
    .. "out of the " .. SMODS.OPENED_BOOSTER.config.center.config.extra .. " available." ..
    " When defining the card's index the first card will be 1.")

    return description
end

function PickCards:_get_schema()
    local hand_length = RunHelper:get_hand_length(G.pack_cards.cards)

    return JsonUtils.wrap_schema({
        pack_card_index = {
            enum = hand_length
        }
    })
end

function PickCards:_validate_action(data, state)
    local selected_hand_index = data._data["pack_card_index"]

    local valid_hand_indices = RunHelper:get_hand_length(G.pack_cards.cards)
    if not table.any(valid_hand_indices, function(options)
            return options == selected_hand_index
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("pack_card_index"))
    end

    local selected_card = G.pack_cards.cards[selected_hand_index]
    if selected_card.ability.set == "Joker" and #G.jokers.cards >= G.jokers.config.card_limit then
        return ExecutionResult.failure("You cannot add anymore jokers to your hand, you should either sell some or skip this pack")
    end

    if selected_card.ability.set == "Planet" and #G.consumeables.cards >= G.consumeables.config.card_limit then
        return ExecutionResult.failure("You cannot add anymore consumables to your hand, you could either sell or use some of those cards or you could skip this pack")
    end

    state["cards_index"] = selected_hand_index
	return ExecutionResult.success("Taking the " .. selected_card.base.name)
end

function PickCards:_execute_action(state)
    local selected_index = state["cards_index"]

    local hand = G.pack_cards.cards

    G.pack_cards:add_to_highlighted(hand[selected_index])
    local button = nil
    for pos, value in ipairs(hand[selected_index].children.use_button.UIRoot.children) do
        if value.config.button ~= nil then
            button = hand[selected_index].children.use_button.UIRoot.children[pos]
            break
        end
    end

    if button == nil then
        sendErrorMessage("None of the cards have a valid use button")
        return true
    end
    button:click()

    cards_picked = cards_picked + 1
    if SMODS.OPENED_BOOSTER.config.center.config.choose > cards_picked then
        pick_pack_card(5,self.hook) -- call action again if more than one pack card can be picked. This is to reduce cooldown of action being registered
        return true
    else
        cards_picked = 0
    end
    self.hook.HookRan = false
    return true
end

return PickCards