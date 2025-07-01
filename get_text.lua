require "functions/misc_functions"

local GetModifierArgs = ModCache.load("card_modifiers_args.lua")

local ALLOWED_DECKS = NeuroConfig.ALLOWED_DECKS
local ALLOWED_STAKES = NeuroConfig.ALLOWED_DECKS

local getText = {}

local function get_back_args(name, effect_config)
    local loc_args = {}
    if name == 'Blue Deck' then loc_args = {effect_config.hands}
    elseif name == 'Red Deck' then loc_args = {effect_config.discards}
    elseif name == 'Yellow Deck' then loc_args = {effect_config.dollars}
    elseif name == 'Green Deck' then loc_args = {effect_config.extra_hand_bonus, effect_config.extra_discard_bonus}
    elseif name == 'Black Deck' then loc_args = {effect_config.joker_slot, -effect_config.hands}
    elseif name == 'Magic Deck' then loc_args = {localize{type = 'name_text', key = 'v_crystal_ball', set = 'Voucher'}, localize{type = 'name_text', key = 'c_fool', set = 'Tarot'}}
    elseif name == 'Nebula Deck' then loc_args = {localize{type = 'name_text', key = 'v_telescope', set = 'Voucher'}, -1}
    elseif name == 'Ghost Deck' then
    elseif name == 'Abandoned Deck' then 
    elseif name == 'Checkered Deck' then
    elseif name == 'Zodiac Deck' then loc_args = {
                        localize{type = 'name_text', key = 'v_tarot_merchant', set = 'Voucher'}, 
                        localize{type = 'name_text', key = 'v_planet_merchant', set = 'Voucher'},
                        localize{type = 'name_text', key = 'v_overstock_norm', set = 'Voucher'}}
    elseif name == 'Painted Deck' then loc_args = {effect_config.hand_size,effect_config.joker_slot}
    elseif name == 'Anaglyph Deck' then loc_args = {localize{type = 'name_text', key = 'tag_double', set = 'Tag'}}
    elseif name == 'Plasma Deck' then loc_args = {effect_config.ante_scaling}
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
            localize{type = 'descriptions', key = key_override or back.key, set = 'Back', nodes = loc_nodes, vars = loc_args}
                        
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
                backs[#backs+1] = name
            end
        end
    end
    return backs
end

function getText:get_stake_names(keys, allStakes)
    local stakes = {}
    for _, stake in pairs(G.P_CENTER_POOLS.Stake) do        
        local name = localize{type = 'name_text', key = stake.key, set = 'Stake'}

        if (stake.unlocked and table.any(ALLOWED_DECKS, function(check) return check == name end)) or allStakes then
            if keys then
                stakes[stake.key] = name
            else
                stakes[#stakes+1] = name
            end
        end
    end
    return stakes
end

return getText