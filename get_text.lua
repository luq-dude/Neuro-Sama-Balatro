require "functions/misc_functions"

local ALLOWED_DECKS = NeuroConfig.ALLOWED_DECKS
local ALLOWED_STAKES = NeuroConfig.ALLOWED_DECKS

local getText = {}

local function get_back_args(name, effect_config)
    local loc_args = {}
    if name == 'Blue Deck' then
        loc_args = { effect_config.hands }
    elseif name == 'Red Deck' then
        loc_args = { effect_config.discards }
    elseif name == 'Yellow Deck' then
        loc_args = { effect_config.dollars }
    elseif name == 'Green Deck' then
        loc_args = { effect_config.extra_hand_bonus, effect_config.extra_discard_bonus }
    elseif name == 'Black Deck' then
        loc_args = { effect_config.joker_slot, -effect_config.hands }
    elseif name == 'Magic Deck' then
        loc_args = { localize { type = 'name_text', key = 'v_crystal_ball', set = 'Voucher' }, localize { type = 'name_text', key = 'c_fool', set = 'Tarot' } }
    elseif name == 'Nebula Deck' then
        loc_args = { localize { type = 'name_text', key = 'v_telescope', set = 'Voucher' }, -1 }
    elseif name == 'Ghost Deck' then
    elseif name == 'Abandoned Deck' then
    elseif name == 'Checkered Deck' then
    elseif name == 'Zodiac Deck' then
        loc_args = {
            localize { type = 'name_text', key = 'v_tarot_merchant', set = 'Voucher' },
            localize { type = 'name_text', key = 'v_planet_merchant', set = 'Voucher' },
            localize { type = 'name_text', key = 'v_overstock_norm', set = 'Voucher' } }
    elseif name == 'Painted Deck' then
        loc_args = { effect_config.hand_size, effect_config.joker_slot }
    elseif name == 'Anaglyph Deck' then
        loc_args = { localize { type = 'name_text', key = 'tag_double', set = 'Tag' } }
    elseif name == 'Plasma Deck' then
        loc_args = { effect_config.ante_scaling }
    elseif name == 'Erratic Deck' then
    end

    return loc_args
end

function getText:get_back_descriptions()
    local backs = {}
    for _, back in pairs(G.P_CENTER_POOLS.Back) do
        local name
        if back.loc_txt then
            name = back.loc_txt.name
        else
            name = back.name
        end

        if back.unlocked and table.any(ALLOWED_DECKS, function(deck) return deck == name end) then
            local loc_args, loc_nodes = get_back_args(back.name, back.config), {}

            local key_override
            if back.loc_vars and type(back.loc_vars) == 'function' then
                local res = back:loc_vars() or {}
                loc_args = res.vars or {}
                key_override = res.key
            end

            sendDebugMessage("key_override: " .. tostring(key_override) .. " back.key: " .. tostring(back.key))
            localize { type = 'descriptions', key = key_override or back.key, set = 'Back', nodes = loc_nodes, vars = loc_args }

            local description = ""
            for _, line in ipairs(loc_nodes) do
                for _, v in ipairs(line) do
                    description = description .. v.config.text
                end
                description = description .. "   "
            end

            backs[name] = description
        end
    end
    return backs
end

function getText:get_back_names(keys, allDecks)
    local backs = {}
    for _, back in pairs(G.P_CENTER_POOLS.Back) do
        local name
        if back.loc_txt then
            name = back.loc_txt.name
        else
            name = back.name
        end

        if (back.unlocked and table.any(ALLOWED_DECKS, function(check) return check == name end)) or allDecks then
            if keys then
                backs[back.key] = name
            else
                backs[#backs + 1] = name
            end
        end
    end
    return backs
end

function getText:get_stake_names(keys, allStakes)
    local stakes = {}
    for _, stake in pairs(G.P_CENTER_POOLS.Stake) do
        local name = localize { type = 'name_text', key = stake.key, set = 'Stake' }

        if (stake.unlocked and table.any(ALLOWED_DECKS, function(check) return check == name end)) or allStakes then
            if keys then
                stakes[stake.key] = name
            else
                stakes[#stakes + 1] = name
            end
        end
    end
    return stakes
end

function getText:generate_blind_descriptions()
    local msg = ""
    local options = { "Small", "Big", "Boss" }

    for _, blind_type in ipairs(options) do
        local blind = G.P_BLINDS[G.GAME.round_resets.blind_choices[blind_type]]
        local status = G.GAME.round_resets.blind_states[blind_type]
        local chips = number_format(get_blind_amount(G.GAME.round_resets.blind_ante) * blind.mult *
            G.GAME.starting_params.ante_scaling)


        msg = msg .. string.format("%s Blind (%s):\n" ..
            "Required score to beat: %s\n",
            blind_type,
            status,
            chips
        )
        if blind_type ~= "Boss" then
            local tag_name = G.P_TAGS[G.GAME.round_resets.blind_tags[blind_type]].name
            local tag = Tag(G.GAME.round_resets.blind_tags[blind_type], nil, blind_type)
            tag:generate_UI()
            local uibox = tag:get_uibox_table()
            local tag_desc = ""
            for _, section in ipairs(uibox.ability_UIBox_table.main) do
                for _, text_section in ipairs(section) do
                    tag_desc = tag_desc .. text_section.config.text
                end
                tag_desc = tag_desc .. " "
            end

            msg = msg .. string.format("Skip Reward: %s (%s)\n", tag_name, tag_desc)
        else
            local boss_desc = localize { type = 'raw_descriptions', key = blind.key, set = 'Blind', vars = { localize(G.GAME.current_round.most_played_poker_hand, 'poker_hands') } }
            local boss_desc_str = ""
            for _, v in ipairs(boss_desc) do
                boss_desc_str = boss_desc_str .. v .. " "
            end

            msg = msg .. "Boss Blind effect: " .. boss_desc_str
        end
    end
    return msg
end

return getText
