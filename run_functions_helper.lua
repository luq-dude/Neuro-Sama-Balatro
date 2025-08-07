local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local RunContext = ModCache.load("run_context.lua")

local RunHelper = {}

function RunHelper:value_in_table(tbl,val)
	for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

function RunHelper:get_hand_length(card_table)
    local hand_length = {}
    for i = 1, #card_table do
        table.insert(hand_length, i)
    end
    return hand_length
end

function RunHelper:increment_card_table(table)
    local selected_table = {}
    for _, card in pairs(table) do
        if selected_table[card] == nil then
            selected_table[card] = 1
        else
            selected_table[card] = selected_table[card] + 1
        end
    end
    return selected_table
end

function RunHelper:check_for_duplicates(table)
    local seen = {}
    for _, idx in ipairs(table) do
        if seen[idx] then
            return false
        end
        seen[idx] = true
    end
    return true
end

function RunHelper:reorder_card_area(card_area, new_indicies)
    card_area.cards = table.reorder_list(card_area.cards, new_indicies)
    card_area:align_cards()
end

function RunHelper:get_query_string(state)
    state = state or G.STATE
    local query_string = ""
    local state_string = ""
    if state == G.STATES.SELECTING_HAND or state == G.STATES.PLAY_TAROT then
        local enhancements, editions, seals = GetRunText:get_current_hand_modifiers(G.hand.cards)
        query_string = "It is now time for you to pick cards to either play or discard, if you want to sell or move your jokers or use consumeables you should do that now."
        if enhancements ~= "" or editions ~= "" or seals ~= "" then -- probably dont need this if there are no card modifiers
            state_string = "These are what the card's modifiers do, there can only be one edition,enhancement and seal on each card: \n" .. enhancements .. "\n" .. editions .."\n" .. seals
        end
        state_string = state_string .. "These are the current cards in your hand, their modifiers and if they are debuffed: " .. table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards,G.GAME.blind.boss))
    elseif state == G.STATES.SHOP then
        query_string = "You are now in the shop! you can either use your money to, buy items to help you in this run or reroll to see new items."
        state_string = "You currently have $" .. tostring(G.GAME.dollars) .. " to spend."
    elseif state == 999 then
        if SMODS.OPENED_BOOSTER.config.center.draw_hand then
            query_string = "You have opened a booster and now you need to pick a card from it, you may need to also select cards from your hand."
            local pack_cards, hand_cards = RunContext:hand_pack_booster()
            state_string = pack_cards .. "\n" .. hand_cards
        else
            query_string = "You have opened a booster and now you need to pick a card from it."
            state_string = RunContext:no_hand_booster()
        end
    end

    return query_string, state_string
end

return RunHelper