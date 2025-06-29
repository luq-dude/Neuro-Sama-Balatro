local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local GetText = ModCache.load("get_text.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PickCards = setmetatable({}, { __index = NeuroAction })
PickCards.__index = PickCards

function PickCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function PickCards:_get_name()
    return "pick_cards"
end

function PickCards:_get_description()  -- use G.P_CENTERS.p-buffoon_jumbo_1.config for getting values
    local description = string.format("Pick cards to add to your deck. You can pick a max of " ..
    SMODS.OPENED_BOOSTER.config.center.config.choose
    .. " cards "
    .. "out of the " .. SMODS.OPENED_BOOSTER.config.center.config.extra .. " available.")

    return description
end

local function get_cards_modifiers()
    local cards = {}
    local card_type = {}
    if SMODS.OPENED_BOOSTER.config.center.kind == "Buffoon" then
        card_type = GetRunText:get_joker_names(G.pack_cards.cards)
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Celestial" then
        card_type = GetRunText:get_celestial_names(G.pack_cards.cards)
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Spectral" then
        card_type = GetRunText:get_spectral_details(G.pack_cards.cards)
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" then
        -- card_type = GetRunText:get_arcana_details()
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Standard" then
        -- this is temporary
        local card_mod = GetText:get_hand_names(G.pack_cards.cards)

        for i = 1, #card_mod do
            local cards_type = card_mod[i] or ""

            cards[i] = cards_type
        end
        return cards
    else -- modded packs or if there is something I forgot
        local card_mod = GetText:get_hand_names(G.pack_cards.cards)

        for i = 1, #card_mod do
            local cards_type = card_mod[i] or ""

            cards[i] = cards_type
        end
        return cards
    end

    for i = 1, #card_type do
        local cards_type = card_type[i] or ""

        cards[i] = cards_type
    end

    -- for i = 1, #cards do
        -- local planet = planet_cards[i] or ""
        -- local jokers = joker_cards[i] or ""
        -- local spectral = spectral_cards[i] or ""

        -- cards[i] = planet
        -- cards[i] = jokers
        -- cards[i] = spectral
    -- end

    return cards
end

function PickCards:_get_schema()
    return JsonUtils.wrap_schema({
        hand = {
			type = "array",
            items = {
				type = "string",
				enum = get_cards_modifiers()
			},
		}
    })
end

local function increment_card_table(table)
    local selected_table = {}
    for _, card in pairs(table) do
        if selected_table[card] == nil then
            selected_table[card] = 1
        else
            selected_table[card] = selected_table[card] + 1 -- should increment for each type of card in hand
        end
    end
    return selected_table
end

function PickCards:_validate_action(data, state)
    local selected_hand = data:get_object("hand")
    selected_hand = selected_hand._data

    if #selected_hand > SMODS.OPENED_BOOSTER.config.center.config.choose then return ExecutionResult.failure("You tried to take more cards then you are allowed too.") end
    if #selected_hand == 0 then return ExecutionResult.failure("You should either take a card or skip the round") end

	local hand = get_cards_modifiers()
    local selected_amount = {}
    local hand_amount = {}

    -- check if card exist
	for _, selected_card in pairs(selected_hand) do
        if not table.any(hand, function(hand_card)
                return hand_card == selected_card
            end) then
            return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter(selected_card .. " is not in your hand."))
        end
    end

    -- add one for each card that is in the hand
    hand_amount = increment_card_table(hand)

    -- add one for each card that is in the selected hand
    selected_amount = increment_card_table(selected_hand)

    -- get if trying to play more cards than in hand
    for _, card in pairs(selected_hand) do
        if selected_amount[card] > hand_amount[card] then
            return ExecutionResult.failure("You can only use the cards given in the hand. You tried to play more " .. card .. "'s when those do not exist")
        else
            sendDebugMessage("lowering " .. card .. "by 1")
            selected_amount[card] = selected_amount[card] - 1
        end
    end

    state["hand"] = selected_hand
	return ExecutionResult.success()
end

-- buy from store directly "buy_and_use"

-- id play card button: "play_button"
function PickCards:_execute_action(state)
	local selected_hand = state["hand"]

    local hand_string = get_cards_modifiers()
    local hand = G.pack_cards.cards
    local selected_amount = increment_card_table(selected_hand)

    local highlighted_cards = {}

    sendDebugMessage("pack_size: " .. tostring(G.GAME.pack_choices) .. "pack_picked" .. SMODS.OPENED_BOOSTER.config.center_key .. "config: " .. tprint(SMODS.OPENED_BOOSTER.config.center.config,1,2))

    for _, card in pairs(selected_hand) do
        local card_id = card
        for index = 1, #hand_string, 1  do
            if card == hand_string[index] and (highlighted_cards[card_id] or 0) < selected_amount[card] then
                G.hand:add_to_highlighted(hand[index])
                sendDebugMessage("Final card print: " .. tprint(hand[index].children.use_button.UIRoot.children[1].children[1],1,2))

                local button = hand[index].children.use_button.UIRoot.children[1].children[1] -- get use button that is shown after clicking on card
                button:click() -- idk if this will work for multiple joker pack

            end
        end
    end

	return true
end


return PickCards