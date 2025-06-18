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

local function get_edition_args(name,card_config)
    local loc_args = {}
    if name == "foil" then loc_args = {card_config.config.extra} -- returns 50 as foil adds 50 chips
    elseif name == "holo" then loc_args = {card_config.config.extra}
    elseif name == "polychrome" then loc_args = {card_config.config.extra} end
    return loc_args
end

function getText:get_hand_editions() -- G.hand.cards  G.play.cards
	local cards = {}
	for pos, card in ipairs(G.hand.cards) do -- Can get editions with card.edition / enhancements with card.ability / seal with card.seal

        local name = card.base.name

        sendDebugMessage("card edition " .. tostring(card.config))

        if card.edition then
            local key_override
            for _, v in pairs(G.P_CENTER_POOLS.Edition) do
                local loc_args,loc_nodes = get_edition_args(card.edition.type,G.P_CENTERS[v.key]), {} -- idk why G.P_CENTERS contains the extra's details but it works
                sendDebugMessage("original_key: " .. tostring(v.original_key) .. " edition type: " .. tostring(card.edition.type))
                sendDebugMessage(tprint(v,1,2))
                sendDebugMessage("v: " .. tostring(v) .. " v type " .. type(v))
                if v.original_key ~= card.edition.type then goto continue end -- go next loop if not the same as card
                if v.loc_vars and type(v.loc_vars) == 'function' then
                    -- local res = v:loc_vars() or {} -- this causes crashes idk why, works without it though
                    loc_args = v.vars or loc_args
                    key_override = v.key

                    localize{type = "descriptions", set = 'Edition',key= key_override or card.key, nodes = loc_nodes, vars = loc_args}
                    sendDebugMessage("loc_vars " .. tostring(card.loc_vars) .. " type " .. type(card.loc_vars))

                    local description = ""
                    for _, line in ipairs(loc_nodes) do
                        for _, word in ipairs(line) do
                            sendDebugMessage("Text: " .. word.config.text)
                            description = description .. word.config.text
                        end
                    end

                    name = name .. description
                end
            ::continue::
            end
        end
		cards[#cards+1] = name -- this will give to neuro as "{value} of {suit}"
    end
    return cards
end

local function get_enhancements_args(name,card_config)
    sendDebugMessage("card config: " .. tprint(card_config,1,2))
    sendDebugMessage("card config config: " .. tprint(card_config.config,1,2))
    sendDebugMessage("card config mult: " .. tostring(card_config.config.mult) .. " name " .. name)
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

-- these are stuff like Bonus card and mult Card
function getText:get_hand_enhancements()
    local cards = {}
	for pos, card in ipairs(G.hand.cards) do

        local name = card.base.name

        sendDebugMessage("card config table: " .. tprint(card.config,1,2))

        if card.ability.effect then
            local key_override
            for _, v in pairs(G.P_CENTER_POOLS.Enhanced) do
                local loc_args,loc_nodes = get_enhancements_args(card.ability.effect,G.P_CENTERS[v.key]), {}
                if v.key ~= card.config.center_key then goto continue end -- go next loop if not the same as card
                    key_override = v.key or card.config.center_key

                    localize{type = "descriptions", set = 'Enhanced',key= key_override or card.config.center_key, nodes = loc_nodes, vars = loc_args}  -- TODO: doesnt get + in mult card idk why

                    local description = ""
                    for _, line in ipairs(loc_nodes) do
                        for _, word in ipairs(line) do
                            sendDebugMessage("Text: " .. word.config.text)
                            description = description .. word.config.text
                        end
                    end

                    name = name .. description
            ::continue::
            end
        end
		cards[#cards+1] = name -- this will give to neuro as "{value} of {suit}"
    end
    return cards
end


local function get_seals_args(name,card_config)
    sendDebugMessage("card config: " .. tprint(card_config,1,2))
    local loc_args = {}
    if name == "Gold Seal" then loc_args = {card_config.config.bonus}
    elseif name == "Red Seal" then loc_args = {card_config.config.mult}
    elseif name == "Blue Seal" then loc_args = {card_config.config.bonus}
    elseif name == "Purple Seal" then loc_args = {card_config} end
end

-- these are stuff like Bonus card and mult Card
function getText:get_hand_seals()
    local cards = {}

    -- for key, value in pairs(SMODS.Seal) do
    --     sendDebugMessage("center pools key: " .. tostring(key) .. " value: " .. tprint(value,1,2))
    -- end

    for key, value in pairs(G.P_CENTER_POOLS.Seal) do
        sendDebugMessage("center pools key: " .. tostring(key) .. " value: " .. tprint(value,1,2))
    end

	for pos, card in ipairs(G.hand.cards) do

        local name = card.base.name

        -- for key, value in pairs(G.P_CENTERS) do
        --     sendDebugMessage("key: " .. tostring(key) .. " value: " .. tprint(value,1,2))
        -- end


        if card.ability.seal then
            -- sendDebugMessage("seal: " .. SMODS.Seal.)

            sendDebugMessage("card abilities: " .. tprint(card.ability))
            sendDebugMessage("card config table: " .. tprint(card.ability.seal,1,2)) -- tprint(card.seal,1,2)
        end

        -- if card.seal then
        --     local key_override
        --     for _, v in pairs(G.P_CENTER_POOLS.Seal) do
        --         sendDebugMessage("Seals: " .. tprint(v,5,5))
        --         local loc_args,loc_nodes = get_seals_args(card.seal,G.P_CENTERS[v.key]), {}
        --         if v.key ~= card.config.center_key then goto continue end -- go next loop if not the same as card
        --             key_override = v.key or card.config.center_key

                    -- localize{type = "descriptions", set = 'Other',key= key_override or card.config.center_key, nodes = loc_nodes, vars = loc_args}  -- TODO: doesnt get + in mult card idk why

        --             local description = ""
        --             for _, line in ipairs(loc_nodes) do
        --                 for _, word in ipairs(line) do
        --                     sendDebugMessage("Text: " .. word.config.text)
        --                     description = description .. word.config.text
        --                 end
        --             end

        --             name = name .. description
        --     ::continue::
        --     end
        -- end
		-- cards[#cards+1] = name -- this will give to neuro as "{value} of {suit}"
    end
    return cards
end


return getText

--  _saved_d_u= "true",
--        original_key= "Gold",
--        registered= "true",
--        badge_colour= table: 0x03fb6688        {
--           [1] = 0.91764705882353,
--           [2] = 0.75294117647059,
--           [3] = 0.34509803921569,
--           [4] = 1,
--         },
--        _discovered_unlocked_overwritten= "true",
--        order= 3,
--        _d= "false",
--        set= "Seal",
--        taken_ownership= "true",
--        discovered= "false",
--        prefix_config= table: 0x0432d800        {
--         },
--        generate_ui= "function: 0x0319b368",
--        key= "Gold",
--        pos= table: 0x04c42998        {
--           y= 0,
--           x= 2,
--         },
--        atlas= "centers",
--        is_loc_modified= "true",