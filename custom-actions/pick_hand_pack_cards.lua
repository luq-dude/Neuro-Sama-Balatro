local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PickHandPackCards = setmetatable({}, { __index = NeuroAction })
PickHandPackCards.__index = PickHandPackCards

local cards_picked = 0

local function pick_hand_pack_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PickHandPackCards:new(window, nil))
            window:register()
            return true
        end
    }
    ))
end

function PickHandPackCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function PickHandPackCards:_get_name()
    return "pick_hand_cards"
end

function PickHandPackCards:_get_description()  -- use G.P_CENTERS.p-buffoon_jumbo_1.config for getting values
    local description = string.format("Pick cards from this pack, you can pick a max of " ..
    SMODS.OPENED_BOOSTER.config.center.config.choose
    .. " cards "
    .. "out of the " ..
    SMODS.OPENED_BOOSTER.config.center.config.extra .. " available.")

    return description
end

local function get_cards_names()
    local cards = {}
    local card_type = {}

	local card_mod = GetRunText:get_hand_names(G.hand.cards)

	for i = 1, #card_mod do
		local cards_type = card_mod[i] or ""

		cards[i] = cards_type
	end
	return cards
end

local function get_pack_cards() -- this is tarot type cards
	local cards = {}
	local card_type = {}

    if SMODS.OPENED_BOOSTER.config.center.kind == "Spectral" then
        card_type = GetRunText:get_spectral_names(G.pack_cards.cards)
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" then
        card_type = GetRunText:get_tarot_names(G.pack_cards.cards)
    else -- modded packs or if there is something I forgot
        local card_mod = GetRunText:get_hand_names(G.hand.cards)

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

	return cards
end

function PickHandPackCards:_get_schema()
    return JsonUtils.wrap_schema({
        hand = {
			type = "array",
            items = {
				type = "string",
				enum = get_cards_names()
			},
		},
		pack_card = { -- this is the tarot or spectral card
			enum = get_pack_cards()
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

function PickHandPackCards:_validate_action(data, state)
    local selected_hand = data:get_object("hand")
    local selected_pack_card = data:get_string("pack_card")
    selected_hand = selected_hand._data

	local hand = get_cards_names()
    local pack_hand = get_pack_cards()
    local selected_amount = {}
    local hand_amount = {}

    if #selected_hand > #hand then return ExecutionResult.failure("You tried to take more cards then you are allowed too.") end
    if #selected_hand == 0 then return ExecutionResult.failure("You should either pick a hand then pick a card from the pack or skip the round") end

    if not table.any(pack_hand, function(card)
            return card == selected_pack_card
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("pack_card"))
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
    state["pack_cards"] = selected_pack_card
	return ExecutionResult.success()
end

function PickHandPackCards:_execute_action(state)
	local selected_hand = state["hand"]
    local selected_pack_card = state["pack_cards"]

    local hand_string = get_cards_names()
    local pack_hand_string = get_pack_cards()
    local hand = G.hand.cards
    local pack_cards_hand = G.pack_cards.cards
    local selected_amount = increment_card_table(selected_hand)

    local highlighted_cards = {}

    -- select main hand cards
    for _, card in pairs(selected_hand) do
        local card_id = card
        for index = 1, #hand_string, 1 do
            if card == hand_string[index] and (highlighted_cards[card_id] or 0) < selected_amount[card] then
                G.hand:add_to_highlighted(hand[index])
                highlighted_cards[card_id] = (highlighted_cards[card_id] or 0) + 1
            end
        end
    end

    for _, card in ipairs(pack_hand_string) do
        for i = 1, #pack_cards_hand, 1 do
            if card == selected_pack_card then
                G.hand:add_to_highlighted(pack_cards_hand[i])
                local button = pack_cards_hand[i].children.use_button.UIRoot.children[2].children[1] -- get use button that is shown after clicking on card
                button:click()
                if SMODS.OPENED_BOOSTER.config.center.config.choose > cards_picked then
                    cards_picked = cards_picked + 1
                    pick_hand_pack_card(5) -- call action again if more than one pack card can be picked
                else
                    cards_picked = 0
                    return true
                end
                return true
            end
        end
    end

	return true
end


return PickHandPackCards