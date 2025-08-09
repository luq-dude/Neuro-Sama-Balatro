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
        query_string = "It's time to pick cards in your hand to play or discard. You can also use consumables re-order jokers, or sell either jokers or consumables."
        if enhancements ~= "" or editions ~= "" or seals ~= "" then -- probably dont need this if there are no card modifiers
            state_string = "These are what the modifiers on your cards in hand do. A card can have one edition, enhancement or seal on it: \n" .. enhancements .. "\n" .. editions .."\n" .. seals
        end
        state_string = state_string .. "These are the cards in your hand, their modifiers and if they are debuffed. Debuffed cards do not get scored: " .. table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards,G.GAME.blind.boss))
    elseif state == G.STATES.SHOP then
        query_string = "You are now in the shop! You can use your money to buy cards, booster packs or vouchers to help your run. You can also use consumables and sell jokers/consumables you no longer need. When done shopping, you can exit the shop to blind selection."
        state_string = "You currently have $" .. tostring(G.GAME.dollars) .. " to spend."
    elseif state == 999 then
        if SMODS.OPENED_BOOSTER.config.center.draw_hand then
            query_string = "You have opened a booster pack containing consumables and can now pick a consumable to immediately use from it. You can also select cards from your hand to use if the consumable needs it."
            local pack_cards, hand_cards = RunContext:hand_pack_booster()
            state_string = pack_cards .. "\n" .. hand_cards
        else
            query_string = "You have opened a booster pack containing cards and can now select cards to keep from it."
            state_string = RunContext:no_hand_booster()
        end
    end

    return query_string, state_string
end

return RunHelper