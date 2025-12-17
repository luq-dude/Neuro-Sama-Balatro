local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local RunHelper = NEURO.MOD_CACHE.load("run_functions_helper.lua")
local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")

local PickCards = setmetatable({}, { __index = NeuroAction })
PickCards.__index = PickCards

function PickCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
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
        return ExecutionResult.failure(NEURO.SDK_STRINGS.action_failed_invalid_parameter("pack_card_index"))
    end

    local selected_card = G.pack_cards.cards[selected_hand_index]
    if selected_card.ability.set == "Joker" and #G.jokers.cards >= G.jokers.config.card_limit and (selected_card.edition == nil or selected_card.edition.key ~= "e_negative") then
        return ExecutionResult.failure("You cannot add anymore jokers to your hand, you should either sell some or skip this pack")
    end

    state["cards_index"] = selected_hand_index
	return ExecutionResult.success("Taking the " .. GetRunText.get_card_description(selected_card))
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

    local can_pick_another = (G.GAME.pack_choices or 1) > 1
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 5 * G.SPEEDFACTOR,
        blocking = false,
        func = function ()
            if can_pick_another then
                NEURO.DEC_STATE()
            else
                NEURO.INC_STATE()
            end
            return true
        end
    }))
    return true
end

return PickCards