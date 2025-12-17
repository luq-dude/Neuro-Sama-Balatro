local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

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

function RunHelper:get_consumable_validation(card,selected_hand_index,selected_action,forced_selection)
    selected_action = selected_action or "Use"
    forced_selection = forced_selection or false
    local success_string = "Using " .. GetRunText.get_card_description(card)
    if selected_action == "Sell" then
        success_string = "Selling the " .. card.config.center.name .. " for " .. card.sell_cost
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

        if selected_action == "Use" and G.hand.cards[selected_hand_index[1]].edition then
            success_string = "Cannot use Aura on a card that already has an edition."
            return false, success_string
        end
        return true, success_string
    end

    if table.contains_key(NEURO.CARD_INFO.MODIFY_JOKER_CONSUMABLE_OVERWRITE,card.config.center_key) == true then
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
    if table.contains_key(NEURO.CARD_INFO.ADD_JOKER_CONSUMABLE_OVERWRITE,card.config.center_key) == true then
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

    return nil, success_string
end

function RunHelper.run_after(delay, func)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        func = func
    }))
end


return RunHelper