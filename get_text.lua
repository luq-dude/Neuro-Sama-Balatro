require "functions/misc_functions"

local ALLOWED_DECKS = NeuroConfig.ALLOWED_DECKS
local ALLOWED_STAKES = NeuroConfig.ALLOWED_STAKES

local GetText = {}
function GetText:get_back_descriptions()
    local backs = {}
    for _, back in pairs(G.P_CENTER_POOLS.Back) do
        local name = back.loc_txt and back.loc_txt.name or back.name
        if back.set ~= "Back" then goto continue end
        if not back.unlocked or not table.any(ALLOWED_DECKS, function(check) return check == name end) then goto continue end

        local lookup = Back_Loc[back.key]
        local args = {}
        local nodes = {}
        local desc = ""
        local key_override = nil
        if back.loc_vars and type(back.loc_vars) == "function" then
            local res = back:loc_vars() or {}
            args = res.vars or {}
            key_override = res.key
        elseif type(lookup) == "table" then
            for _, v in ipairs(lookup) do
                table.insert(args, back.config[v])
            end
        elseif type(lookup) == "function" then
            args = lookup(back)
        end

        localize { type = "descriptions", key = key_override or back.key, set = "Back", nodes = nodes, vars = args }
        for _, line in ipairs(nodes) do
            for _, v in ipairs(line) do
                desc = desc .. v.config.text
            end
            desc = desc .. "   "
        end

        backs[#backs+1] = name .. ": " .. desc
        ::continue::
    end
    return backs
end

function GetText:get_back_names(keys, allDecks)
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

function GetText:get_stake_descriptions()
    local stakes = {}
    sendDebugMessage(tprint(stakes,1))
    for _, stake in pairs(G.P_CENTER_POOLS.Stake) do
        local name = stake.loc_txt and stake.loc_txt.name or stake.name
        if stake.set ~= "Stake" then goto continue end
        if not table.any(ALLOWED_STAKES, function(check) return check == name end) then goto continue end

        local lookup = Stake_Loc[stake.key]
        local args = {}
        local nodes = {}
        local desc = ""
        local key_override = nil
        if stake.loc_vars and type(stake.loc_vars) == "function" then
            local res = stake:loc_vars() or {}
            args = res.vars or {}
            key_override = res.key
        elseif type(lookup) == "table" then
            for _, v in ipairs(lookup) do
                table.insert(args, stake.config[v])
            end
        elseif type(lookup) == "function" then
            args = lookup(stake)
        end

        localize { type = "descriptions", key = key_override or stake.key, set = "Stake", nodes = nodes, vars = args }
        for _, line in ipairs(nodes) do
            for _, v in ipairs(line) do
                desc = desc .. v.config.text
            end
            desc = desc .. " "
        end

        stakes[#stakes+1] = name ..": " .. desc
        ::continue::
    end
    return stakes
end

function GetText:get_stake_names(keys, allStakes)
    local stakes = {}
    for _, stake in pairs(G.P_CENTER_POOLS.Stake) do
        local name = localize { type = 'name_text', key = stake.key, set = 'Stake' }

        if (table.any(ALLOWED_STAKES, function(check) return check == name end)) or allStakes then
            if keys then
                stakes[stake.key] = name
            else
                stakes[#stakes + 1] = name
            end
        end
    end
    return stakes
end

function GetText:generate_blind_descriptions()
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

return GetText
