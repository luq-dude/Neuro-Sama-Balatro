local GetRunText = ModCache.load("get_run_text.lua")

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
return RunContext