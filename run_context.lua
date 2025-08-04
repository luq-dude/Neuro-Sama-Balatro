local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local RunContext = {}

function RunContext:no_hand_booster()
	if G.pack_cards == nil or G.pack_cards.cards == nil or G.pack_cards.cards == {} then return end
    if SMODS.OPENED_BOOSTER.config.center.kind == "Buffoon" or G.pack_cards.cards[1].ability.set == "Joker" then
            local hand = table.table_to_string(GetRunText:get_joker_details(G.pack_cards.cards))

            Context.send(string.format("This is the hand of cards that are in this pack: " ..
            hand .. "\n" ..
            "These cards will give passive bonuses after each hand played, these range from increasing the chips" ..
            " increasing the mult of a hand or giving money or consumables after certain actions."))

    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Celestial" or G.pack_cards.cards[1].ability.set == "Celestial" then
        local hand = table.table_to_string(GetRunText:get_celestial_details(G.pack_cards.cards))

        Context.send(string.format("This is the hand of cards that are in this pack: " ..
        hand .. "\n" ..
        "These cards will level up a poker hand and improve the scoring that you will receive for playing them."))
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Standard" or G.pack_cards.cards[1].ability.set == "Base" then
        local hand, enhancements, editions, seals = table.table_to_string(GetRunText:get_card_modifiers(G.pack_cards.cards)),GetRunText:get_current_hand_modifiers(G.pack_cards.cards)

        Context.send(string.format("This is the hand of cards that are in this pack: " ..
        hand .. "\n" .. "\n" ..
        "These are the card modifiers that are on the cards right now," ..
        " there can only be one edition,enhancement and seal on each card: \n" ..
        enhancements .. "\n" ..
        editions .. "\n" ..
        seals),true)
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
    end
end


function RunContext:hand_pack_booster()
    if #G.hand.cards > 0 then
        local hand, enhancements, editions, seals = table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards)),
            GetRunText:get_current_hand_modifiers(G.hand.cards)

        Context.send(string.format(
            "These are the playing cards in your hand \n" .. hand .. "\n" ..
            "These are the card modifiers that are on the cards right now," ..
            " there can only be one edition,enhancement and seal on each card: \n" ..
            enhancements .. "\n" ..
            editions .. "\n" ..
            seals), true)
    end

    if G.pack_cards == nil or G.pack_cards.cards == nil or G.pack_cards.cards == {} then return end
    if SMODS.OPENED_BOOSTER.config.center.kind == "Spectral" then
        local pack_hand = table.table_to_string(GetRunText:get_spectral_details(G.pack_cards.cards))
        Context.send(string.format("This is the hand of cards that are in this pack: " .. pack_hand))
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" then
        local pack_hand = table.table_to_string(GetRunText:get_tarot_details(G.pack_cards.cards))
        Context.send(string.format("This is the hand of cards that are in this pack: " .. pack_hand))
    else -- modded packs that dont contain contain a default set or if there is something I forgot
        local pack_hand = table.table_to_string(GetRunText:get_hand_details(G.pack_cards.cards))
        Context.send(string.format("This is the hand of cards that are in this pack: " .. pack_hand))
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