local GetRunText = {}

local function add_card_buy_cost(description,card)
    if not card.cost then return end

    description = description .. ". Buy cost: " .. card.cost
    return description
end

local function add_consumeable_edition(desc, card)
    if not card.edition then return desc end
    desc = desc .. ". Edition: "
    for _, v in ipairs(G.P_CENTER_POOLS.Edition) do
        if v.key == card.edition.key and v.loc_txt then
            desc = desc .. v.loc_txt.name
        elseif v.key == card.edition.key then
            desc = desc .. v.name
        end
    end
    return desc
end

function GetRunText:get_celestial_names(card_hand)
    local cards = {}

	for pos, card in ipairs(card_hand) do
        for _, v in pairs(G.P_CENTER_POOLS.Planet) do
            local name = card.ability.name

            if v.key ~= card.config.center_key then goto continue end
            if v.loc_txt and type(v.loc_vars) == 'function' then
                name = v.loc_txt.name -- get name that shows on hover
            end
            sendDebugMessage("card name: " .. name)
            cards[#cards + 1] = name
            ::continue::
        end
        sendDebugMessage("past continue")
    end
    return cards
end

function GetRunText:get_celestial_details(card_hand,add_cost,count)
    add_cost = add_cost or false
    count = count or false
    local cards = {}

	for pos, card in ipairs(card_hand) do
		sendDebugMessage("start for loop")
		local planet_desc = ""
        if card.ability.name == "Black Hole" then
            planet_desc = "\n" .. (count and ("- " .. #cards + 1 .. ": ") or "") .. "Black Hole: Upgrades all poker hands by 1 level"
        elseif card.ability.set == "Planet" then
            for _, v in pairs(G.P_CENTER_POOLS.Planet) do
                local loc_args,loc_nodes = {}, {}
                local name = card.ability.name

                if v.key ~= card.config.center_key then goto continue end
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars() or {}
                    name = v.loc_txt.name
                end
                loc_args = {  -- SMODS.PokerHand contains both smods added hands and vanilla (haven't tested modded cards, so it could still break, sorry if so.)
                    SMODS.PokerHand.obj_table[v.config.hand_type].level,localize(v.config.hand_type, 'poker_hands'), SMODS.PokerHand.obj_table[v.config.hand_type].l_mult, SMODS.PokerHand.obj_table[v.config.hand_type].l_chips,
                    colours = {(SMODS.PokerHand.obj_table[v.config.hand_type].level==1 and G.C.UI.TEXT_DARK or G.C.HAND_LEVELS[math.min(7, SMODS.PokerHand.obj_table[v.config.hand_type].level)])}
                    }
                localize{type = 'descriptions', key = v.key, set = v.set, nodes = loc_nodes, vars = loc_args, AUT = card.ability_UIBox_table}
                local description = "\n" .. (count and ("- " .. #cards + 1 .. ": ") or "") .. name .. ": "
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

                if add_cost then description = add_card_buy_cost(description,card) end
                description = add_consumeable_edition(description, card)
                planet_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = planet_desc
    end
    return cards
end

function GetRunText:get_joker_names(card_hand)
    local cards = {}
	for pos, card in ipairs(card_hand) do
        for _, v in pairs(G.P_CENTER_POOLS.Joker) do
            local name = card.ability.name

            if v.key ~= card.config.center_key then goto continue end
            if v.loc_txt and type(v.loc_vars) == 'function' then
                name = v.loc_txt.name
            end
            sendDebugMessage("card name: " .. name)
            cards[#cards + 1] = name
            ::continue::
        end
        sendDebugMessage("past continue")
    end
    return cards
end

function GetRunText:get_joker_details(card_hand,add_cost,count)
    add_cost = add_cost or false
    count = count or false
    local cards = {}
    local add_blueprint = false
    for _, v in ipairs(G.jokers.cards) do
        if v.ability.name == "Blueprint" or v.ability.name == "Brainstorm" then
            add_blueprint = true
        end
    end

	for pos, card in ipairs(card_hand) do
		local joker_desc = ""

        if card.ability.set == 'Joker' then
            local key_override = nil
            for _, v in pairs(G.P_CENTER_POOLS.Joker) do
                local loc_args,loc_nodes = {}, {}
                local name = card.ability.name

                if v.key ~= card.config.center_key then goto continue end
                if v.loc_txt and v.mod then
                    if v.loc_vars then
                        local res = v:loc_vars({},card) or {} -- need to pass these to get vars (atleast in neurocards mod)
                        loc_args = res.vars or {}
                    end
                    key_override = v.key
                    name = card.config.center.loc_txt.name_parsed[1][1].strings[1]
				else
                    LOC_ARGS = {}
                    card:generate_UIBox_ability_table()
                    loc_args = LOC_ARGS
                    key_override = card.config.center_key
                end

                localize{type = 'descriptions', key = v.key, set = v.set, nodes = loc_nodes, vars = loc_args, AUT = card.ability_UIBox_table}

                local description = "\n" .. (count and ("- " .. #cards + 1 .. ": ") or "") .. name .. ": "
                if name == "Misprint" then
                    description = description .. "Gives a random amount of mult from +0 to +23 (inclusive)"
                end
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if word.nodes ~= nil then
                            if word.nodes[1].config.text ~= nil then
                                description = description .. word.nodes[1].config.text
                            elseif word.nodes[1].config.object ~= nil then -- get modded vars
                                description = description .. word.nodes[1].config.object.config.string[1]
                            end
                        else
                            description = description .. word.config.text
                        end
                        description = description .. " "
                    end
                end

                if add_cost then description = add_card_buy_cost(description,card) end
                if add_blueprint then description = description .. ". Blueprint/Brainstorm compatible: " .. tostring(card.config.center.blueprint_compat) end
                joker_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = joker_desc
    end
    return cards
end

function GetRunText:get_spectral_names(card_hand)
    local cards = {}

	for pos, card in ipairs(card_hand) do
        for _, v in pairs(G.P_CENTER_POOLS.Spectral) do
            local name = card.ability.name

            if v.key ~= card.config.center_key then goto continue end
            if v.loc_txt and type(v.loc_vars) == 'function' then
                name = v.loc_txt.name
            end
            cards[#cards + 1] = name
            ::continue::
        end
    end
    return cards
end

function GetRunText:get_spectral_details(card_hand,add_cost,count)
    add_cost = add_cost or false
    count = count or false
    local cards = {}

	for pos, card in ipairs(card_hand) do
		local spectral_desc = ""

        if card.ability.set == 'Spectral' then
            local key_override = nil
            for card_id, g_card in pairs(G.P_CENTERS) do
                if g_card.name ~= card.ability.name then goto continue end
                local loc_lookup = Spectral_Loc[card_id]
                local loc_args = {}
                local loc_nodes = {}
                local name = card.ability.name
                if type(loc_lookup) == "table" then
                    for _, v in ipairs(loc_lookup) do
                        table.insert(loc_args,g_card.config[v])
                    end
                elseif type(loc_lookup) == "function" then
                    loc_args = loc_lookup(g_card)
                elseif g_card.mod then
                    name = g_card.loc_txt.name
                    if type(g_card.loc_vars) == "function" then 
                        local res = g_card:loc_vars({}, card) or {}
                        loc_args = res.vars
                    end 
                else
                    sendErrorMessage("Could not find localize for card" .. g_card.key)
                end

                localize{type = 'descriptions', key = g_card.key or key_override, set = g_card.set, nodes = loc_nodes, vars = loc_args, AUT = card.ability_UIBox_table}

                local description = "\n" .. (count and ("- " .. #cards + 1 .. ": ") or "") .. name .. ": "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if word.nodes ~= nil then
                            if word.nodes[1].config.text ~= nil then
                                description = description .. word.nodes[1].config.text
                            elseif word.nodes[1].config.object ~= nil then
                                description = description .. word.nodes[1].config.object.config.string[1]
                            end
                        else
                            description = description .. word.config.text
                        end
                        description = description .. " "
                    end
                end

                if add_cost then description = add_card_buy_cost(description,card) end
                description = add_consumeable_edition(description, card)
                spectral_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = spectral_desc
    end
    return cards
end

function GetRunText:get_tarot_names(card_hand)
    local cards = {}

	for pos, card in ipairs(card_hand) do
        for _, v in pairs(G.P_CENTER_POOLS.Tarot) do
            local name = card.ability.name

            if v.key ~= card.config.center_key then goto continue end
            if v.loc_txt and type(v.loc_vars) == 'function' then
                name = v.loc_txt.namer
            end
            cards[#cards + 1] = name
            ::continue::
        end
    end
    return cards
end

function GetRunText:get_tarot_details(card_hand,add_cost,count)
    add_cost = add_cost or false
    count = count or false
    local cards = {}

	for pos, card in ipairs(card_hand) do
		local tarot_desc = ""

        if card.ability.set == 'Tarot' or card.ability.name == "The Soul" then
            local key_override = nil
            for card_id, g_card in pairs(G.P_CENTERS) do
                if g_card.name ~= card.ability.name then goto continue end
                local loc_lookup = Tarot_Loc[card_id] or Spectral_Loc[card_id]
                local loc_args = {}
                local loc_nodes = {}
                local name = card.ability.name
                if type(loc_lookup) == "table" then
                    for _, v in ipairs(loc_lookup) do
                        table.insert(loc_args,g_card.config[v])
                    end
                elseif type(loc_lookup) == "function" then
                    loc_args = loc_lookup(card)
                elseif g_card.mod then
                    name = g_card.loc_txt.name
                    if type(g_card.loc_vars) == "function" then 
                        local res = g_card:loc_vars({}, card) or {}
                        loc_args = res.vars
                    end 
                else
                    sendErrorMessage("Could not find localize for card" .. g_card.key)
                end

                localize{type = 'descriptions', key = g_card.key or key_override, set = g_card.set or card.ability.set, nodes = loc_nodes, vars = loc_args, AUT = card.ability_UIBox_table}

                local description = "\n" .. (count and ("- " .. #cards + 1 .. ": ") or "") .. name .. ": "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if word.nodes ~= nil then
                            if word.nodes[1].config.text ~= nil then
                                description = description .. word.nodes[1].config.text
                            elseif word.nodes[1].config.object ~= nil then
                                description = description .. word.nodes[1].config.object.config.string[1]
                            end
                        else
                            description = description .. word.config.text
                        end
                        description = description .. " "
                    end
                end

                if add_cost then description = add_card_buy_cost(description,card) end
                description = add_consumeable_edition(description, card)
                tarot_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = tarot_desc
    end
    return cards
end

function GetRunText:get_booster_details(boosters,add_cost,count)
    add_cost = add_cost or false
    count = count or false
    local shop_boosters = {}

	for pos, booster in ipairs(boosters) do
		local booster_desc = ""

        if booster.ability.set == 'Booster' then
            local key_override = nil
            for card_id, g_card in pairs(G.P_CENTER_POOLS.Booster) do
                local loc_args = {}
                local loc_nodes = {}
                local name = booster.ability.name
                if g_card.key ~= booster.config.center_key then goto continue end
                if g_card.mod then
                    local res = g_card:loc_vars(nil,booster) or {}
                    name = g_card.loc_txt.name
                    loc_args = res.vars
                    key_override = g_card.key
                else
                    name = booster.ability.name
                    local key = "" .. string.sub(booster.config.center_key,1,#booster.config.center_key - 2) -- need to remove the booster's number from the key to use in localize
                    key_override = key
                    loc_args = {booster.config.center.config.choose,booster.config.center.config.extra}
                end

                localize{type = 'descriptions', key = key_override, set = "Other" or booster.ability.set, nodes = loc_nodes, vars = loc_args, AUT = booster.ability_UIBox_table}

                local description = "\n" .. (count and ("- " .. #shop_boosters + 1 .. ": ") or "") .. name .. ": "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if word.nodes ~= nil then
                            if word.nodes[1].config.text ~= nil then
                                description = description .. word.nodes[1].config.text
                            elseif word.nodes[1].config.object ~= nil then
                                description = description .. word.nodes[1].config.object.config.string[1]
                            end
                        else
                            description = description .. word.config.text
                        end
                        description = description .. " "
                    end
                end

                if add_cost then description = add_card_buy_cost(description,booster) end
                booster_desc = description
            ::continue::
            end
        end
		shop_boosters[#shop_boosters+1] = booster_desc
    end
    return shop_boosters
end

function GetRunText:get_voucher_details(voucher_table,add_cost,count)
    add_cost = add_cost or false
    count = count or false
    local vouchers = {}

	for pos, voucher in ipairs(voucher_table) do
		local voucher_desc = ""

        if voucher.ability.set == 'Voucher' then
            local key_override = nil
            for card_id, g_card in pairs(G.P_CENTER_POOLS.Voucher) do
                local loc_lookup = Voucher_Loc[g_card.key]
                local loc_args = {}
                local loc_nodes = {}
                local name = voucher.ability.name
                if g_card.key ~= voucher.config.center_key then goto continue end
                if type(loc_lookup) == "table" then
                    for _, v in ipairs(loc_lookup) do
                        table.insert(loc_args,g_card.config[v])
                    end
                elseif type(loc_lookup) == "function" then
                    loc_args = loc_lookup(g_card)
                else
                    sendErrorMessage("Could not find localize for card" .. g_card.key)
                end

                localize{type = 'descriptions', key = g_card.key, set = g_card.set, nodes = loc_nodes, vars = loc_args, AUT = voucher.ability_UIBox_table}

                local description = "\n" .. (count and ("- " .. #vouchers + 1 .. ": ") or "") .. name .. ": "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if word.nodes ~= nil then
                            if word.nodes[1].config.text ~= nil then
                                description = description .. word.nodes[1].config.text
                            elseif word.nodes[1].config.object ~= nil then
                                description = description .. word.nodes[1].config.object.config.string[1]
                            end
                        else
                            description = description .. word.config.text
                        end
                        description = description .. " "
                    end
                end

                if add_cost then description = add_card_buy_cost(description,voucher) end
                voucher_desc = description
            ::continue::
            end
        end
		vouchers[#vouchers+1] = voucher_desc
    end
    return vouchers
end

function GetRunText:get_shop_text(card_table,add_cost,count)
    add_cost = add_cost or false
    count = count or false
    local card = card_table[1]

    if card.ability.set == "Booster" then
        return GetRunText:get_booster_details(card_table,add_cost,count)
    elseif card.ability.set == "Voucher" then
        return GetRunText:get_voucher_details(card_table,add_cost,count)
    elseif card.ability.set == "Joker" then
        return GetRunText:get_card_modifiers(card_table,false,false,add_cost,count)
    end
end

function GetRunText:get_consumeables_text(cards,add_cost,count)
    add_cost = add_cost or false
    count = count or false
    local cards_details = {}

    for index, card in ipairs(cards) do
        if card.ability.set == "Planet" then
            cards_details[#cards_details+1] = (count and ("\n" .. "- " .. #cards_details + 1 .. ": ") or "") .. string.sub(GetRunText:get_celestial_details({card},add_cost)[1], 2) 
        elseif card.ability.set == "Tarot" then
            cards_details[#cards_details+1] = (count and ("\n" .. "- " .. #cards_details + 1 .. ": ") or "") .. string.sub(GetRunText:get_tarot_details({card},add_cost)[1], 2)
        elseif card.ability.set == "Spectral" then
            cards_details[#cards_details+1] = (count and ("\n" .. "- " .. #cards_details + 1 .. ": ") or "") .. string.sub(GetRunText:get_spectral_details({card},add_cost)[1], 2)
        elseif card.ability.set == "Joker" then
            cards_details[#cards_details+1] = (count and ("\n" .. "- " .. #cards_details + 1 .. ": ") or "") .. string.sub(GetRunText:get_card_modifiers({card},false,false,add_cost)[1], 2)
        elseif card.config.card ~= nil then -- this handles playing cards for magic trick
            cards_details[#cards_details+1] = (count and ("\n" .. "- " .. #cards_details + 1 .. ": ") or "") .. string.sub(GetRunText:get_card_modifiers({card})[1], 7)
        end
    end

    return cards_details
end

-- playing card stuff
function GetRunText:get_card_modifiers(card_hand,add_debuff_state,add_forced_state,add_cost,count)
    add_debuff_state = add_debuff_state or false
    add_forced_state = add_forced_state or false
    add_cost = add_cost or false
    count = count or false
    local cards = {}

	for pos, card in ipairs(card_hand) do
        local card_desc = ""
        if card.ability.set == "Joker" then
            card_desc = GetRunText:get_joker_details({card},add_cost,count)[1]
        else
            card_desc = "\n" .. "- " .. pos .. ": " .. card.base.name
        end

        if card.edition then
            for _, v in ipairs(G.P_CENTER_POOLS.Edition) do
                local description = ""
                if v.key == card.edition.key and v.loc_txt then
                    description = ", Card Edition: " .. v.loc_txt.name
                elseif v.key ~= card.edition.key then
                    goto continue
                else
                    description = ", Card Edition: " .. v.name
                end

                card_desc = card_desc .. description
                ::continue::
            end
        end

        if card.ability.effect ~= "Base" then
            for _, v in ipairs(G.P_CENTER_POOLS.Enhanced) do
                local description
                if v.key == card.config.center_key and v.loc_txt then
                    description = ", Card Enhancement: " .. v.loc_txt.name
                elseif v.key ~= card.config.center_key then
                    goto continue
                else
                    description = ", Card Enhancement: " .. card.ability.name
                end

                card_desc = card_desc .. description
                ::continue::
            end
        end

        if card.ability.seal then
            for _, v in ipairs(G.P_CENTER_POOLS.Seal) do
                local description
                if v.key == card.seal and v.loc_txt then
                    description = ", Card Seal: " .. v.loc_txt.name
                elseif v.key ~= card.seal then
                    goto continue
                else
                    description = ", Card Seal: " .. card.seal .. " Seal"
                end

                card_desc = card_desc .. description
                ::continue::
            end
        end

        if add_debuff_state then
            card_desc = card_desc .. ", Debuffed: " .. tostring(card.debuff) -- this is a boolean
        end

        if add_forced_state then
            if card.ability.forced_selection then
                card_desc = card_desc .. ", Force selected: " .. tostring(card.ability.forced_selection)
            end
        end

        cards[#cards+1] = card_desc
    end

    return cards
end

function GetRunText:get_hand_names(cards_table)
    local cards = {}
    for pos, card in ipairs(cards_table) do
        local name = card.base.name

        sendDebugMessage("name: " .. name)
		cards[#cards+1] = name
	end
	return cards
end

local function get_text(loc_nodes,current_description)
    local description = current_description
    if #loc_nodes > 0 then
        for _, line in ipairs(loc_nodes) do
            for _, word in ipairs(line) do
                if word.nodes ~= nil then
                    if word.nodes[1].config.object ~= nil then
                        description = description .. word.nodes[1].config.object.string
                    else
                        description = description .. word.nodes[1].config.text
                    end
                else
                    if not word.config.text then break end -- removes table that contains stuff for setting up UI
                    description = description .. word.config.text
                end
                description = description .. " "
            end
        end
    end

    return description
end

function GetRunText:get_hand_editions(cards_table)
	local cards = {}
	for _, card in ipairs(cards_table) do

        local edition_desc = ""

        if card.edition then
            local key_override
            for _, g_card in pairs(G.P_CENTER_POOLS.Edition) do
                if g_card.key ~= card.edition.key then goto continue end
                local loc_lookup, loc_args, loc_nodes = Edition_Loc[g_card.key], {}, {}
                local name = g_card.name
                if g_card.key == card.edition.key and g_card.loc_txt then
                    if g_card.loc_vars then
                        local res = g_card:loc_vars(nil,card) or {}
                        loc_args = res.vars or res.loc_txt.text
                    end
                    name = g_card.loc_txt.name
                elseif type(loc_lookup) == "table" then
                    for _, v in ipairs(loc_lookup) do
                        table.insert(loc_args,g_card.config[v])
                    end
                elseif type(loc_lookup) == "function" then
                    loc_args = loc_lookup(g_card)
                else
                    sendErrorMessage("Could not find localize for edition" .. g_card.key)
                end

                localize{type = 'descriptions', key = g_card.key or key_override, set = g_card.set or card.ability.set, nodes = loc_nodes, vars = loc_args, AUT = card.ability_UIBox_table}

                local description = "\n -- " .. name .. " : "
                description = get_text(loc_nodes,description)

                edition_desc = description
            ::continue::
            end
        end

        if table.any(cards, function(edition) return edition == edition_desc end) then edition_desc = "" end -- get rid of duplicates
		cards[#cards+1] = edition_desc
    end
    return cards
end

function GetRunText:get_hand_enhancements(cards_table)
    local cards = {}
	for pos, card in ipairs(cards_table) do

        local enhancement_desc = ""

        if card.ability.effect ~= "Base" then
            for _, g_card in pairs(G.P_CENTER_POOLS.Enhanced) do
                if g_card.key ~= card.config.center_key then goto continue end
                local loc_lookup, loc_args, loc_nodes = Enhancement_Loc[g_card.key], {}, {}
                local name = card.ability.name
                local key_override = g_card.key
                local set_override = g_card.set
                if g_card.key == card.config.center_key and g_card.loc_txt then
                    if g_card.loc_vars then
                        local res = g_card:loc_vars(nil,card) or {}
                        loc_args = res.vars or res.loc_txt.text
                    end
                    name = g_card.loc_txt.name
                elseif type(loc_lookup) == "table" then
                    for _, v in ipairs(loc_lookup) do
                        table.insert(loc_args,g_card.config[v])
                    end
                elseif type(loc_lookup) == "function" then
                    loc_args = loc_lookup(g_card)
                else
                    sendErrorMessage("Could not find localize for enhancement" .. g_card.key)
                end
                if g_card.key == "m_bonus" then
                    key_override = "card_extra_chips"
                    set_override = "Other"
                end

                localize{type = 'descriptions', key = key_override or g_card.key, set = set_override or g_card.set, nodes = loc_nodes, vars = loc_args, AUT = g_card.ability_UIBox_table} -- doesn't get character's like + idk why as others do, needs to be fixed before releasing though

                local description = "\n -- " .. name .. " : "
                description = get_text(loc_nodes,description)

                enhancement_desc = description
            ::continue::
            end
        end
        if table.any(cards, function(enhancement) return enhancement == enhancement_desc end) then enhancement_desc = "" end
		cards[#cards+1] = enhancement_desc
    end
    return cards
end

function GetRunText:get_hand_seals(cards_table)
    local cards = {}

	for pos, card in ipairs(cards_table) do

        local seal_desc = ""

        if card.ability.seal then
            local key_override = nil
            for _, g_card in pairs(G.P_CENTER_POOLS.Seal) do
                local loc_lookup,loc_nodes,loc_args = Seal_Loc[card.seal], {}, {}
                local name = ""
                if g_card.key ~= card.seal then goto continue end
                if g_card.key == card.seal and g_card.loc_txt then
                    if g_card.loc_vars then
                        local res = g_card:loc_vars(nil,card) or {} -- osu seal needs these or crash
                        loc_args = res.vars or res.loc_txt.text
                    end
                    name = g_card.loc_txt.name
                    key_override = g_card.key .. '_seal' -- Smods does this however doesn't mention it in any documentation :)
                elseif type(loc_lookup) == "table" then
                    key_override = loc_lookup[1]
                    name = card.seal
                elseif type(loc_lookup) == "function" then
                    key_override = loc_lookup[1]
                    loc_args = loc_lookup(g_card)
                    name = card.seal
                else
                    sendErrorMessage("Could not find localize for edition" .. g_card.key)
                end

                localize{type = 'descriptions', set = "Other" or g_card.set, key= key_override or g_card.key, nodes = loc_nodes, vars = loc_args}

                local description = "\n -- " .. name.. " Seal"  .. " : "
                description = get_text(loc_nodes,description)

                seal_desc = description
            ::continue::
            end
        end
        if table.any(cards, function(seal) return seal == seal_desc end) then seal_desc = "" end
		cards[#cards+1] = seal_desc
    end
    return cards
end


local function get_modifiers_vars(card_table,loc_lookup)
    local description,name,loc_args = "","",{}
    if card_table.loc_txt then
        loc_args = table.get_values(card_table.config)
        name = card_table.loc_txt.name
    elseif type(loc_lookup) == "table" then
        for _, v in ipairs(loc_lookup) do
            if card_table.config then
                table.insert(loc_args,card_table.config[v])
            else
                table.insert(loc_args,v) -- this is for the slightly jank seal loc implementation
            end
        end
    elseif type(loc_lookup) == "function" then
        loc_args = loc_lookup(card_table)
    else
        sendErrorMessage("Could not find localize for enhancement" .. card_table.key)
    end

    return description,name,loc_args
end

function GetRunText:get_all_modifiers()
    local edition_descriptions = {}
    local enhancement_descriptions = {}
    local seal_descriptions = {}

    for _, g_card in pairs(G.P_CENTER_POOLS.Edition) do
        local loc_lookup, loc_nodes = Edition_Loc[g_card.key], {}
        local name = g_card.name
        local description,func_name,loc_args = get_modifiers_vars(g_card,loc_lookup)
        if func_name ~= "" then name = func_name end

        localize{type = 'descriptions', key = g_card.key, set = g_card.set, nodes = loc_nodes, vars = loc_args, AUT = g_card.ability_UIBox_table}

        description = get_text(loc_nodes,description)
        -- is this hacky? yes. do i have a better idea? no
        if g_card.key == 'e_negative' then
            edition_descriptions[#edition_descriptions+1] = "\n -- Negative (on Jokers) : +1 Joker slot"
            edition_descriptions[#edition_descriptions+1] = "\n -- Negative (on Consumables) : +1 Consumables slot"
            edition_descriptions[#edition_descriptions+1] = "\n -- Negative (on Playing Cards) : +1 hand size"
        else
            edition_descriptions[#edition_descriptions+1] = "\n -- " .. name.. " : " .. description
        end
    end

    for _, g_card in pairs(G.P_CENTER_POOLS.Enhanced) do
        local loc_lookup, loc_nodes = Enhancement_Loc[g_card.key], {}
        local name = g_card.label
        local key_override,set_override = g_card.key, g_card.set
        local description,func_name,loc_args = get_modifiers_vars(g_card,loc_lookup)
        if func_name ~= "" then name = func_name end
        if g_card.key == "m_bonus" then
            key_override = "card_extra_chips"
            set_override = "Other"
        elseif g_card.key == "m_steel" then
            loc_args = {1.5}
        end

        localize{type = 'descriptions', key = key_override or g_card.key, set = set_override or g_card.set, nodes = loc_nodes, vars = loc_args, AUT = g_card.ability_UIBox_table} -- doesn't get character's like + idk why as others do, needs to be fixed before releasing though

        description = get_text(loc_nodes,description)

        enhancement_descriptions[#enhancement_descriptions+1] = "\n -- " .. name.. " : " .. description
    end

    for _, g_card in pairs(G.P_CENTER_POOLS.Seal) do
        local loc_lookup,loc_nodes = Seal_Loc[g_card.key], {}
        local name,key_override = g_card.key,""
        local description,func_name,loc_args = get_modifiers_vars(g_card,loc_lookup)
        if func_name ~= "" then name = func_name end
        if g_card.loc_txt then
            key_override = g_card.key .. '_seal' -- smods thing
        else
            name = name .. " seal"
            key_override = loc_args[1] -- seal loc gets key not args
        end

        localize{type = 'descriptions', set = "Other" or g_card.set, key= key_override or g_card.key, nodes = loc_nodes, vars = loc_args, AUT = g_card.ability_UIBox_table}

        description = get_text(loc_nodes,description)

        seal_descriptions[#seal_descriptions+1] = "\n -- " .. name.. ": " .. description
    end

    return edition_descriptions,enhancement_descriptions,seal_descriptions
end

-- just calls get_all_modifiers but puts them all in a single string
function GetRunText:get_all_modifier_desc()
    local edi,enh,seal = GetRunText:get_all_modifiers()
    local ret = "These are all the playing card and joker modifiers in the game. " ..
        "A playing card can only have one edition, enhancement and seal at a time, while jokers can only have one edition. " ..
        "You should remember these: " ..
        "\n- Editions:" .. table.table_to_string(edi) ..
        "\n- Enhancements:" .. table.table_to_string(enh) ..
        "\n- Seals:" .. table.table_to_string(seal)
    
    return ret
end

return GetRunText