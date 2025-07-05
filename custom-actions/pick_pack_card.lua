local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")

local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")
local SkipPack = ModCache.load("custom-actions/skip_pack.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PickCards = setmetatable({}, { __index = NeuroAction })
PickCards.__index = PickCards

function PickCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function PickCards:_get_name()
    return "pick_cards"
end

function PickCards:_get_description()  -- use G.P_CENTERS.p-buffoon_jumbo_1.config for getting values
    local description = string.format("Pick cards to add to your deck. You can pick a max of " ..
    SMODS.OPENED_BOOSTER.config.center.config.choose
    .. " cards "
    .. "out of the " .. SMODS.OPENED_BOOSTER.config.center.config.extra .. " available." ..
    " When defining the card's index the first card will be 1, you should send these in the same order as you send the cards")

    return description
end

local function get_cards_modifiers()
    local cards = {}
    local card_type = {}
    if G.pack_cards == nil or G.pack_cards.cards == nil or G.pack_cards.cards == {} then return end
    if SMODS.OPENED_BOOSTER.config.center.kind == "Buffoon" or G.pack_cards.cards[1].ability.set == "Joker" then
        local hand = table.table_to_string(GetRunText:get_joker_details(G.pack_cards.cards))

        Context.send(string.format("This is the hand of cards that are in this pack: " ..
        hand .. "\n" ..
        "These cards will give passive bonuses after each hand played, these range from increasing the chips" ..
        " increasing the mult of a hand or giving money or consumables after certain actions."))

        card_type = GetRunText:get_joker_names(G.pack_cards.cards)
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Celestial" or G.pack_cards.cards[1].ability.set == "Celestial" then
        local hand = table.table_to_string(GetRunText:get_celestial_details(G.pack_cards.cards))

        Context.send(string.format("This is the hand of cards that are in this pack: " ..
        hand .. "\n" ..
        "These cards will level up a poker hand and improve the scoring that you will receive for playing them."))

        card_type = GetRunText:get_celestial_names(G.pack_cards.cards)
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Standard" or G.pack_cards.cards[1].ability.set == "Base" then
        local hand, enhancements, editions, seals = table.table_to_string(GetRunText:get_card_modifiers(G.pack_cards.cards)),GetRunText:get_current_hand_modifiers(G.pack_cards.cards)

        Context.send(string.format("This is the hand of cards that are in this pack: " ..
        hand .. "\n" ..
        "These are the card modifiers that are on the cards right now," ..
        " there can only be one edition,enhancement and seal on each card: \n" ..
        enhancements .. "\n" ..
        editions .. "\n" ..
        seals),true)
        -- this is temporary
        card_type = GetRunText:get_hand_names(G.pack_cards.cards)
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Spectral" or G.pack_cards.cards[1].ability.set == "Spectral" then
        sendDebugMessage("Spectral should not be called from pick_pack_card")
        return
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" or G.pack_cards.cards[1].ability.set == "Tarot" then
        sendDebugMessage("Arcana should not be called from pick_pack_card")
        return
    else -- modded packs that dont contain contain a default set or if there is something I forgot
        sendDebugMessage("card table: " .. tprint(G.pack_cards.cards,1,2))
        local hand = table.table_to_string(GetRunText:get_hand_names(G.pack_cards.cards))

        Context.send(string.format("This is the hand of cards that are in this pack: " ..
        hand))

        card_type = GetRunText:get_hand_names(G.pack_cards.cards)
    end

    for i = 1, #card_type do
        local local_card = card_type[i] or ""

        cards[i] = local_card
    end

    return cards
end

function PickCards:_get_schema()
    local hand_names = GetRunText:get_hand_names(G.pack_cards.cards) -- get length of hand
    local hand_length = {}
    for i = 1, #hand_names do
        table.insert(hand_length, i)
    end

    return JsonUtils.wrap_schema({
        hand = {
			type = "array",
            items = {
				type = "string",
				enum = get_cards_modifiers()
			},
		},
        cards_index = {
            type = "array",
            items ={
                type = "integer",
                enum = hand_length
            }
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
    local selected_index = data:get_object("cards_index")
    selected_hand = selected_hand._data
    selected_index = selected_index._data

    if #selected_hand > SMODS.OPENED_BOOSTER.config.center.config.choose then return ExecutionResult.failure("You tried to take more cards then you are allowed too.") end
    if #selected_hand == 0 then return ExecutionResult.failure("You should either take a card or skip the round") end

    if #selected_index ~= #selected_hand then return ExecutionResult.failure("You have either given more card indexs or more selected cards.") end

	local hand = get_cards_modifiers()
    local selected_amount = {}
    local hand_amount = {}

    for pos, card in ipairs(selected_hand) do
        for ipos, index in ipairs(selected_index) do
            sendDebugMessage("card: " .. card .. " index: " .. index .. " card in hand at index: " .. hand[index])
            if hand[index] ~= card and pos == ipos then
                return ExecutionResult.failure("the card: " .. card .. " is not at the index " .. index .. " in the hand")
            else
                goto continue
            end
        end
        ::continue::
    end


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

    state["cards_index"] = selected_index
    state["hand"] = selected_hand
	return ExecutionResult.success()
end

-- buy from store directly "buy_and_use"

-- id play card button: "play_button"
function PickCards:_execute_action(state)
	local selected_hand = state["hand"]
    local selected_index = state["cards_index"]

    local hand_string = get_cards_modifiers()
    local hand = G.pack_cards.cards
    local selected_amount = increment_card_table(selected_hand)

    local highlighted_cards = {}

    sendDebugMessage("pack_size: " .. tostring(G.GAME.pack_choices) .. "pack_picked" .. SMODS.OPENED_BOOSTER.config.center_key .. "config: " .. tprint(SMODS.OPENED_BOOSTER.config.center.config,1,2))

    if hand_string == nil then return false end
    for _, card in pairs(selected_hand) do
        local card_id = card
        for _, index in ipairs(selected_index) do
            if hand_string[index] == card and (highlighted_cards[card_id] or 0) < selected_amount[card] then
                sendDebugMessage("hand card: " .. hand_string[index] .. " card: " .. card)
                G.hand:add_to_highlighted(hand[index])

                local button = hand[index].children.use_button.UIRoot.children[1].children[1] -- get use button that is shown after clicking on card
                button:click()
            end
        end
    end

    self.hook.HookRan = false
    NeuroActionHandler.unregister_actions({SkipPack:new()})
	return true
end


return PickCards