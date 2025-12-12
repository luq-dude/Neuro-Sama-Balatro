local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

local RunContext = {}

function RunContext.booster()
    local hand_str = ""
    if G.hand.cards and #G.hand.cards > 0 then
        local hand = table.table_to_string(GetRunText.get_hand_details(G.hand.cards, true))

        hand_str = string.format("These are the playing cards in your hand: %s\n", hand)
    end

    if G.pack_cards == nil or G.pack_cards.cards == nil or G.pack_cards.cards == {} then return end
    local set = G.pack_cards.cards[1].ability.set
    local type = "cards"
    if set == "Joker" then type = "jokers"
    elseif set == "Celestial" then type = "planet cards"
    elseif set == "Base" then type = "playing cards"
    elseif set == "Spectral" then type = "spectral cards"
    elseif set == "Tarot" then type = "tarot cards" end

    local pack_str = table.table_to_string(GetRunText.get_hand_details(G.pack_cards.cards, true, false, nil, true))
    return string.format("%sThese are the %s in this pack: %s", hand_str, type, pack_str)
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

function RunContext.get_all_modifier_desc()
    local edi,enh,seal = GetRunText.get_all_modifiers()
    local ret = "These are all the playing card and joker modifiers in the game. " ..
        "A playing card can only have one edition, enhancement and seal at a time, while jokers can only have one edition. " ..
        "You should remember these: " ..
        "\n- Editions:" .. table.table_to_string(edi) ..
        "\n- Enhancements:" .. table.table_to_string(enh) ..
        "\n- Seals:" .. table.table_to_string(seal)

    return ret
end

function RunContext.get_boot_text()
    return "Welcome to Balatro! Balatro is a roguelike deck builder based around poker. " ..
        "In each round, or blind, you can play or discard a limited number of hands consisting of up to 5 cards. " ..
        "Each blind has a score requirement you have to reach, otherwise you will game over. " ..
        "Each poker hand has a base chips and multiplier that determines how much the hand will score. " ..
        "Then, every card played has it's value added to the chips (11 for Aces, 10 for King/Queen/Jack, then 10-2 for the rest). " ..
        "Only cards that directly count to the poker hand are counted. For example, if you play a two pair with an extra 5th card, " ..
        "the 5th card will not be counted. You may also get cards with modifiers like granting extra chips or mult when scored. " ..
        "The main component of Balatro deckbuilding are jokers. Jokers grant a variety of effects, from extra chips or mult to money or even consumables. " ..
        "The order in which you play cards and sort your jokers matter, as effects activate from left to right. " ..
        "For example, any effect that multiplies your total mult should be after any effects that increase your total mult by a flat amount. " ..
        "With the right setup of jokers, even a single high card can score more than a straight royal flush. Good luck!"
end
return RunContext