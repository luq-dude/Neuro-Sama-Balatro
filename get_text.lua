require "functions/misc_functions"

local ALLOWED_DECKS = SMODS.current_mod.config.ALLOWED_DECKS


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

    return loc_args -- TODO: add support for modded decks
end

function getText:get_allowed_backs()
    local backs = {}
    for k, v in pairs(G.P_CENTER_POOLS.Back) do
        if v.unlocked and table.any(ALLOWED_DECKS, function(deck) return deck == v.name end) then
            
            local loc_nodes = {}
            local loc_args = get_back_args(v.name, v.config)
            localize{type = 'descriptions', key = v.key, set = 'Back', nodes = loc_nodes, vars = loc_args}
                        
            local description = ""
            for _, line in ipairs(loc_nodes) do
                for _, v in ipairs(line) do
                    description = description .. v.config.text
                end
                description = description .. "     "
            end
            backs[v.name] = description
        end
    end
    --sendDebugMessage("Allowed backs: \n" .. inspectDepth(backs))
    return backs
end

return getText