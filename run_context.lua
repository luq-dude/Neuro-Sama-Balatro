local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local RunContext = {}

function RunContext:no_hand_booster()
	if G.pack_cards == nil or G.pack_cards.cards == nil or G.pack_cards.cards == {} then return end
    if SMODS.OPENED_BOOSTER.config.center.kind == "Buffoon" or G.pack_cards.cards[1].ability.set == "Joker" then
        local hand = table.table_to_string(GetRunText:get_joker_details(G.pack_cards.cards, false, true))

        return string.format("These are the jokers in this pack: " ..
        hand .. "\n" ..
        "You can only select a joker if you have the inventory space for it. " ..
        "Jokers are the main deckbuilding component of Balatro and can provide a variety of effects that help in scoring or provide extra money or consumables.")
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Celestial" or G.pack_cards.cards[1].ability.set == "Celestial" then
        local hand = table.table_to_string(GetRunText:get_celestial_details(G.pack_cards.cards, false, true))

        return string.format("These are the planet cards in this pack: " ..
        hand .. "\n" ..
        "Planet cards level up the base chips and mult of a specific poker hand.")
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Standard" or G.pack_cards.cards[1].ability.set == "Base" then
        local hand, enhancements, editions, seals = table.table_to_string(GetRunText:get_card_modifiers(G.pack_cards.cards)),GetRunText:get_current_hand_modifiers(table.combine_tables(G.pack_cards.cards,G.jokers.cards))

        local return_string = "These are the playing cards in this pack: " .. hand .. "\n" .. "\n"
        if enhancements ~= "" or editions ~= "" or seals ~= "" then
            return_string = return_string .. string.format("These are the card modifiers that are on the cards or on your jokers right now," ..
            " there can only be one edition,enhancement and seal on each card: \n" ..
            enhancements .. "\n" ..
            editions .. "\n" ..
            seals)
        end
        return return_string
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Spectral" or G.pack_cards.cards[1].ability.set == "Spectral" then
        sendErrorMessage("Spectral should not be called from pick_pack_card")
        return
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" or G.pack_cards.cards[1].ability.set == "Tarot" then
        sendErrorMessage("Arcana should not be called from pick_pack_card")
        return
    else -- modded packs that dont contain contain a default set or if there is something I forgot
        sendDebugMessage("card table: " .. tprint(G.pack_cards.cards,1,2))
        local hand = table.table_to_string(GetRunText:get_hand_names(G.pack_cards.cards))

        return string.format("This is the hand of cards that are in this pack: " .. hand)
    end
end

function RunContext:hand_pack_booster()
    local hand_string = ""
    if #G.hand.cards > 0 then
        local hand, modifiers = table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards)), {GetRunText:get_current_hand_modifiers(table.combine_tables(G.hand.cards,G.jokers.cards))}

        hand_string = string.format("These are the playing cards in your hand: " .. hand)
        for key, value in ipairs(modifiers) do
            if value ~= "" then
                if not string.find(hand_string,"These are what the card modifiers on your cards") then
                    hand_string = hand_string .. "\nThese are what the card modifiers on your cards or your jokers do. A playing card can have one edition, enhancements and seal at one: "
                end
                hand_string = hand_string .. "\n" .. value
            end
        end
    end

    if G.pack_cards == nil or G.pack_cards.cards == nil or G.pack_cards.cards == {} then return end
    if SMODS.OPENED_BOOSTER.config.center.kind == "Spectral" then
        local pack_hand = table.table_to_string(GetRunText:get_spectral_details(G.pack_cards.cards, false, true))
        return string.format("These are the consumables in this pack: " .. pack_hand), hand_string
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" then
        local pack_hand = table.table_to_string(GetRunText:get_tarot_details(G.pack_cards.cards, false, true))
        return string.format("These are the consumables in this pack: " .. pack_hand), hand_string
    else -- modded packs that dont contain contain a default set or if there is something I forgot
        local pack_hand = table.table_to_string(GetRunText:get_hand_details(G.pack_cards.cards, false, true))
        return string.format("These are the consumables in this pack: " .. pack_hand), hand_string
    end
end

function RunContext:hand_type_information()
    local context_hands = {}
    for name, hand in pairs(G.GAME.hands) do
        if hand.visible then
            local description = name .. ": " .. "level: " .. tostring(hand.level) .. " chips: " .. tostring(hand.chips) .. " mult: " .. tostring(hand.mult) .. " description: "

            local loc_nodes = G.localization.misc.poker_hand_descriptions[SMODS.PokerHand.obj_table[name].original_key]
            local temp_desc = ""
            for index, desc in ipairs(loc_nodes) do
                if index <= #loc_nodes - 1 then
                    desc = desc .. " "
                end
                temp_desc = temp_desc .. desc
            end
            description = description .. temp_desc
            context_hands[#context_hands+1] = description
        end
    end
    return context_hands
end

return RunContext