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
        local modifiers = {GetRunText:get_current_hand_modifiers(table.combine_tables(G.hand.cards,G.jokers.cards))}
        query_string = "It's time to pick cards in your hand to play or discard. You can also use consumables re-order jokers, or sell either jokers or consumables."
        state_string = "You have " .. tostring(G.GAME.current_round.hands_left) .. " hands left and " .. tostring(G.GAME.current_round.discards_left) .. " discards left. " ..
                        "You have " .. tostring(#G.deck.cards) .. " cards remaining in your deck that can be drawn, out of the " .. tostring(G.deck.config.card_limit) .. " cards in it.\n"
        for key, value in ipairs(modifiers) do
            if value ~= "" then
                if not string.find(state_string,"These are what the card modifiers on your cards") then
                    state_string = state_string .. "These are what the card modifiers on your cards or your jokers do. A playing card can have one edition, enhancements and seal at one: "
                end
                state_string = state_string .. "\n" .. value
            end
        end
        if #state_string ~= 0 then
            state_string = state_string .. "\n"
        end
        if G.GAME.blind.boss then
            state_string = state_string .. "These are the cards in your hand, their modifiers and if they are debuffed. Debuffed cards do not get scored: "
        else
            state_string = state_string .. "These are the cards in your hand and their modifiers: "
        end
        local forced = false
        if table.any(G.hand.cards,function (card)
                return card.ability.forced_selection
            end) == true then
            forced = true
            state_string = string.sub(state_string,1,#state_string - 2) .. ". If a card is forced you must select it when playing, discarding or using a consumable that needs cards: " -- string sub to remove colon from boss blinds
        end
        state_string = state_string .. table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards, G.GAME.blind.boss, forced))
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

    if #G.jokers.cards > 0 then
        local cards = GetRunText:get_card_modifiers(G.jokers.cards)

        for pos, value in ipairs(cards) do
            cards[pos] = "\n" .. pos .. ": " .. string.sub(value,2) .. ", sell cost: " .. G.jokers.cards[pos].sell_cost
        end
        state_string = state_string .. "\nThese are the names of jokers in your hand, their abilites, modifiers and sell cost: ".. table.concat(cards, "", 1, #cards)
    else
        state_string = state_string .. "\nYou do not have any jokers as of right now."
    end

    if #G.consumeables.cards > 0 then
        local cards = GetRunText:get_consumeables_text(G.consumeables.cards)

        for pos, value in ipairs(cards) do
            cards[pos] = "\n" .. pos .. ": " .. value .. " sell value: " .. G.consumeables.cards[pos].sell_cost
        end
        state_string = state_string .. "\nThese are the names of the consumeables in your hand, their abililties and their sell cost: " .. table.concat(cards, "", 1, #cards)
    else
        state_string = state_string .. "\nYou do not have any consumeables as of right now."
    end

    return query_string, state_string
end

function RunHelper:get_consumable_validation(card,selected_hand_index,selected_action,forced_selection)
    selected_action = selected_action or "Use"
    forced_selection = forced_selection or false
    local success_string = "Using " .. string.sub(GetRunText:get_consumeables_text({card})[1], 1)
    if selected_action == "Sell" then
        success_string = "Selling the " .. card.config.center.name .. " for " .. card.sell_cost
    end

    if table.contains_key(Non_Valid_Modify_Joker_Consumables,card.config.center_key) == true then
        if #G.jokers.cards < 1 and selected_action == "Use" then
            success_string = "This card requires a joker to be used."
            return false, success_string
        end

        if #selected_hand_index > 0 then
            success_string = "You cannot select any cards when using this card."
            return false, success_string
        end

        return true, success_string
    end

    -- these are cards that need room but do not list needed space in their config. These all add to joker
    if table.contains_key(Non_Valid_Add_Joker_Consumables,card.config.center_key) == true then
        if #G.jokers.cards >= G.jokers.config.card_limit and selected_action == "Use" then
            success_string = "You can not use this card as you already have the maximum amount of jokers."
            return false, success_string
        end

        if #selected_hand_index > 0 then
            success_string = "You cannot select any cards when using this card"
            return false, success_string
        end

        return true, success_string
    end

    if card.config.center.name == "The Fool" and G.GAME.last_tarot_planet == nil or G.GAME.last_tarot_planet == 'c_fool' then
        return false, "You cannot use The Fool right now, as you have either not played a tarot card yet, or your last played tarot card was also The Fool."
    end

    -- specific check for the fool since if its from a pack then we need to check inventory space
    -- if its from the inventory then later on free space will always be at least 1 so were fine
    if #table.get_keys(card.ability.consumeable) or card.config.center.name == "The Fool" > 0 then
        local card_amount = 0
        if card.config.center.name == "The Fool" then card_amount = 1 end
        for card_type, amount in pairs(card.ability.consumeable) do
            if card_type == "spectrals" or card_type == "planets" or card_type == "tarots" then
                card_amount = card_amount + amount
            else -- certain other cards use .consumeable, we don't want those though.
                return nil, success_string
            end
        end

        if #selected_hand_index > 0 then
            success_string = "You cannot select any cards when using this card"
            return false, success_string
        end

        -- if its from the inventory then add 1 since were using up the card to create the extra ones
        local free_space = G.consumeables.config.card_limit - #G.consumeables.cards + (card.area == G.pack_cards and 0 or 1)
        if selected_action == "Use" then
            if free_space <= 0 then
                success_string = "You do not have any space in your consumable inventory to use this"
                return false, success_string
            elseif free_space >= card_amount then
                return true, success_string
            else
                success_string = success_string .. ". Only creating " .. card_amount - free_space .. " cards since your inventory is now full"
                return true, success_string
            end
        end

        return true, success_string
    end

    if forced_selection and table.any(G.hand.cards,function (force_card) return force_card.ability.forced_selection end) == true then
        local index = -1
        for _, card_index in ipairs(selected_hand_index) do
            if G.hand.cards[card_index].ability.forced_selection then
                index = card_index
            end
        end

        if index == -1 and card.config.center_key == "c_aura" then
            success_string = "You must select the force selected card."
            return false, success_string
        end
    end

    if card.config.center_key == "c_aura" then
        if G.STATE == G.STATES.SHOP and selected_action == "Use" then
            success_string = "You cannot use aura in the shop."
            return false, success_string
        end

        if #selected_hand_index ~= 1 and selected_action == "Use" then
            success_string = "Aura requires for only one card to be selected."
            return false, success_string
        end

        return true, success_string
    end

    return nil, success_string
end

return RunHelper