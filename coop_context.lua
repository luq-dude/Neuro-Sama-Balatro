local PreRunLoc = NEURO.MOD_CACHE.load("pre_run_loc.lua")

local CoopContext = {}

function CoopContext.get_boot_text()
    return "The game has booted up in co-op mode. In co-op mode, instead of playing the game " ..
           "on your own, you are instead assisting someone else play the game. Have fun!"
end

function CoopContext.get_man_deck_select()
    local back = G.GAME.selected_back_key
    local p_stake = G.P_CENTER_POOLS.Stake[G.GAME.stake]
    local parts = {}
    parts[#parts+1] = "The game has started."
    parts[#parts+1] = "Selected Deck: " .. back.name ..
                      " (" .. PreRunLoc.get_back_desc(back.key) .. ")"
    local level = p_stake.stake_level
    parts[#parts+1] = "Stakes (cumulative difficulty options) applied:"
    for _,v in ipairs(G.P_CENTER_POOLS.Stake) do
        if v.stake_level > level then break end
        parts[#parts+1] = "- " .. PreRunLoc.get_stake_desc(v.key)
    end
    return table.concat(parts, "\n")
end


function CoopContext.get_blind_win_text()
    local _,disp_text,_,_ = G.FUNCS.get_poker_hand_info(G.play.cards)
    local chip_total = hand_chips * mult
    return string.format(
                "Congratulations! Blind won with the hand type: %s. The winning hand scored " ..
                "%s, for a total of %s chips out of a required %s chips to win.",
                number_format(chip_total),
                disp_text,
                number_format(G.GAME.chips + chip_total),
                number_format(G.GAME.blind.chips))
end

function CoopContext.get_last_hand_text()
    local _,disp_text,_,_ = G.FUNCS.get_poker_hand_info(G.play.cards)
    local chip_total = hand_chips * mult
    return string.format(
            "This hand scored %s chips with the hand type %s. " ..
            "%s chips total are needed to win this blind.",
            number_format(chip_total),
            disp_text,
            number_format(G.GAME.blind.chips))
end
return CoopContext