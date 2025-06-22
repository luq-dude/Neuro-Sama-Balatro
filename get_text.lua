require "functions/misc_functions"

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

function getText:get_hand_names()
    local cards = {}
    for pos, card in ipairs(G.hand.cards) do


        local name = card.base.name

		cards[#cards+1] = name
	end
	return cards
end


local function get_edition_args(name,card_config)
    local loc_args = {}
    if name == "foil" then loc_args = {card_config.config.extra}
    elseif name == "holo" then loc_args = {card_config.config.extra}
    elseif name == "polychrome" then loc_args = {card_config.config.extra} end
    return loc_args
end

function getText:get_hand_editions()
	local cards = {}
	for _, card in ipairs(G.hand.cards) do

        local edition_desc = ""

        if card.edition then
            local key_override
            for _, v in pairs(G.P_CENTER_POOLS.Edition) do
                local loc_args,loc_nodes = get_edition_args(card.edition.type,G.P_CENTERS[v.key]), {}
                if v.key ~= card.edition.key then goto continue end -- go next loop if not the same as card
                if v.loc_vars and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars() or {}
                    loc_args = res.vars or loc_args
                end
                key_override = v.key

                localize{type = "descriptions", set = 'Edition',key= key_override or card.key, nodes = loc_nodes, vars = loc_args}

                local description = " Cards edition: "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if word.nodes ~= nil then
                            description = description .. word.nodes[1].config.text
                        else
                            description = description .. word.config.text
                        end
                        description = description .. " "
                    end
                end

                edition_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = edition_desc
    end
    return cards
end

local function get_enhancements_args(name,card_config)
    local loc_args = {}
    if name == "Bonus Card" then loc_args = {card_config.config.bonus}
    elseif name == "Mult Card" then loc_args = {card_config.config.mult}
    elseif name == "Wild Card" then loc_args = {card_config.config.extra} --  localize
    elseif name == "Glass Card" then loc_args = {card_config.config.Xmult, card_config.config.extra} -- 2x 1 in 4 chance to break (this is sent as 4)
    elseif name == "Steel Card" then loc_args = {card_config.config.h_x_mult} -- 1.5 while in hand
    elseif name == "Stone Card" then loc_args = {card_config.config.bonus} -- is always 50
    elseif name == "Gold Card" then loc_args = {card_config.config.h_dollars} -- three in hand
    elseif name == "Lucky Card" then loc_args = {card_config.config.p_dollars,card_config.config.mult} end -- 1 in 5 chance for +20 mult and 1 in 15 for $20 (these are both sent as 20)
    return loc_args
end

function getText:get_hand_enhancements()
    local cards = {}
	for pos, card in ipairs(G.hand.cards) do

        local enhancement_desc = ""

        if not card.ability.effect then
            local key_override
            for _, v in pairs(G.P_CENTER_POOLS.Enhanced) do
                local loc_args,loc_nodes = get_enhancements_args(card.ability.effect,G.P_CENTERS[v.key]), {}
                if v.key ~= card.config.center.name then goto continue end -- go next loop if not the same as card
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars(nil,card) or {} -- makes twins card work and glorp still works so I think its fine
                    loc_args = res.vars or {}
                end
                key_override = v.key

                localize{type = "descriptions", set = 'Enhanced',key= key_override or card.config.original_key, nodes = loc_nodes, vars = loc_args}  -- TODO: doesnt get + in mult card idk why

                local description = " Cards enhancement: "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if not word.config.text then break end -- removes table that contains stuff for setting up UI
                        sendDebugMessage("word: " .. tostring(word))
                        description = description .. word.config.text
                    end
                end

                enhancement_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = enhancement_desc
    end
    return cards
end

local function get_seals_args(name)
    local loc_args = {}
    if name == "Gold" then loc_args = {"gold_seal"}
    elseif name == "Red" then loc_args = {"red_seal"}
    elseif name == "Blue" then loc_args = {"blue_seal"}
    elseif name == "Purple" then loc_args = {"purple_seal"} end
    return loc_args
end

function getText:get_hand_seals()
    local cards = {}

    local seals = {"gold_seal","red_seal","blue_seal","purple_seal"} -- bad but I'm a bit too lazy to find another way and it works

	for pos, card in ipairs(G.hand.cards) do

        local seal_desc = ""

        if card.ability.seal then
            local key_override = nil
            for _, v in pairs(G.P_CENTER_POOLS.Seal) do
                local loc_args,loc_nodes = get_seals_args(card.seal), {}
                if v.key ~= card.seal then goto continue end
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars() or {}
                    loc_args = res.vars or {}
                    key_override = v.key .. '_seal' -- Smods does this however doesn't mention it in any documentation :)
                else -- vanilla seal
                    key_override = loc_args[1]
                    loc_args = {}
                end

                localize{type = 'descriptions', set = "Other" or v.set, key= key_override or v.key, nodes = loc_nodes, vars = loc_args}

                local description = " Cards seal: "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if word.nodes ~= nil then
                            description = description .. word.nodes[1].config.text
                        else
                            description = description .. word.config.text
                        end
                        description = description .. " "
                    end
                end

                seal_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = seal_desc
    end
    return cards
end


return getText