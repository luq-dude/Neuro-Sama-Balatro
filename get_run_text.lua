local getRunText = {}

-- G.shop_booster might be related to how boosters in the bottom right of the shop ui are loaded

function getRunText:get_celestial_names(card_hand)
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

function getRunText:get_celestial_details(card_hand)
    local cards = {}

    -- sendDebugMessage(tprint(G.pack_cards.cards,1,5))

	sendDebugMessage("start get_planet_details") -- G.consumeables.highlighted
	for pos, card in ipairs(card_hand) do -- this might need to be changed from G.hand.cards
		sendDebugMessage("start for loop")
		local planet_desc = ""

		sendDebugMessage("Pos: " .. pos .. " Card: " .. card.ability.name)


        if card.ability.set == "Planet" then
            local key_override = nil
            for _, v in pairs(G.P_CENTER_POOLS.Planet) do -- card.ability.effect card.ability.name
                local loc_args,loc_nodes = {}, {}
                local name = card.ability.name

                if v.key ~= card.config.center_key then goto continue end
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars() or {}
                    loc_args = res.vars or {}
                    loc_args = {  -- not tested
                    SMODS.PokerHand.obj_table[v.config.hand_type].level,localize(v.config.hand_type, 'poker_hands'), SMODS.PokerHand.obj_table[v.config.hand_type].l_mult, SMODS.PokerHand.obj_table[v.config.hand_type].l_chips,
                    colours = {(SMODS.PokerHand.obj_table[v.config.hand_type].level==1 and G.C.UI.TEXT_DARK or G.C.HAND_LEVELS[math.min(7, SMODS.PokerHand.obj_table[v.config.hand_type].level)])} -- G.C.HANDLEVELS will probably need to be replaced with an smods var
                    }
                    key_override = v.key
                    name = v.loc_txt.name
				else
                    loc_args = {
                    G.GAME.hands[v.config.hand_type].level,localize(v.config.hand_type, 'poker_hands'), G.GAME.hands[v.config.hand_type].l_mult, G.GAME.hands[v.config.hand_type].l_chips,
                    colours = {(G.GAME.hands[v.config.hand_type].level==1 and G.C.UI.TEXT_DARK or G.C.HAND_LEVELS[math.min(7, G.GAME.hands[v.config.hand_type].level)])}
                    }
                end

                localize{type = 'descriptions', key = v.key, set = v.set, nodes = loc_nodes, vars = loc_args}

                local description = "\n" .. name .. ": "
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

                planet_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = planet_desc
    end
    return cards
end

function getRunText:get_joker_names(card_hand)
    local cards = {}
	for pos, card in ipairs(card_hand) do
        for _, v in pairs(G.P_CENTER_POOLS.Joker) do
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

function getRunText:get_joker_details(card_hand)
    local cards = {}

	for pos, card in ipairs(card_hand) do
		local joker_desc = ""

        if card.ability.set == 'Joker' then
            local key_override = nil
            for _, v in pairs(G.P_CENTER_POOLS.Joker) do
                local loc_args,loc_nodes = {}, {}
                local name = card.ability.name

                if v.key ~= card.config.center_key then goto continue end
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars({},card) or {} -- need to pass these to get vars (atleast in neurocards mod)
                    loc_args = res.vars or {}
                    key_override = v.key
                    name = v.loc_txt.name -- get name that shows on hover
				else
                    LOC_ARGS = {}
                    card:generate_UIBox_ability_table()
                    loc_args = LOC_ARGS -- this is defined in lovely patch
                    key_override = card.config.center_key
                end

                localize{type = 'descriptions', key = v.key, set = v.set, nodes = loc_nodes, vars = loc_args}

                sendDebugMessage("joker card: " .. tprint(card,1,2))

                local description = "\n" .. name .. ": "
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

                joker_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = joker_desc
    end
    return cards
end

function getRunText:get_spectral_names(card_hand)
    local cards = {}

	for pos, card in ipairs(card_hand) do
        for _, v in pairs(G.P_CENTER_POOLS.Spectral) do
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

function getRunText:get_spectral_details(card_hand)
    local cards = {}

	for pos, card in ipairs(card_hand) do
		local spectral_desc = ""

        sendDebugMessage("Card " .. card.ability.name .. ": " .. tprint(card,1,2))

        if card.ability.set == 'Spectral' then
            local key_override = nil
            for card_id, g_card in pairs(G.P_CENTERS) do
                if g_card.name ~= card.ability.name then goto continue end
                sendDebugMessage("G.P_CENTER_POOLS table: " .. tprint(G.P_CENTER_POOLS.Spectral,1,2))
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
                else
                    sendErrorMessage("Could not find localize for card" .. g_card.key)
                end

                localize{type = 'descriptions', key = g_card.key or key_override, set = g_card.set, nodes = loc_nodes, vars = loc_args}

                local description = "\n" .. name .. ": "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        sendDebugMessage("Word: " .. tprint(word,1,2))
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

                spectral_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = spectral_desc
    end
    return cards
end

function getRunText:get_tarot_names(card_hand)
    local cards = {}

	for pos, card in ipairs(card_hand) do
        for _, v in pairs(G.P_CENTER_POOLS.Tarot) do
            local name = card.ability.name

            sendDebugMessage("card key: " .. v.key .. " card.config: " .. card.config.center_key)
            if v.key ~= card.config.center_key then goto continue end
            if v.loc_txt and type(v.loc_vars) == 'function' then
                name = v.loc_txt.name -- get name that shows on hover
            end
            sendDebugMessage("card name: " .. name)
            cards[#cards + 1] = name
            ::continue::
        end
    end
    return cards
end

function getRunText:get_tarot_details(card_hand)
    local cards = {}

	for pos, card in ipairs(card_hand) do
		local tarot_desc = ""

        if card.ability.set == 'Tarot' then
            local key_override = nil
            for card_id, g_card in pairs(G.P_CENTERS) do
                if g_card.name ~= card.ability.name then goto continue end
                local loc_lookup = Tarot_Loc[card_id]
                local loc_args = {}
                local loc_nodes = {}
                local name = card.ability.name
                if type(loc_lookup) == "table" then
                    for _, v in ipairs(loc_lookup) do
                        table.insert(loc_args,g_card.config[v])
                    end
                elseif type(loc_lookup) == "function" then
                    loc_args = loc_lookup(g_card)
                else
                    sendErrorMessage("Could not find localize for card" .. g_card.key)
                end

                localize{type = 'descriptions', key = g_card.key or key_override, set = g_card.set or card.ability.set, nodes = loc_nodes, vars = loc_args}

                local description = "\n" .. card.ability.name .. ": "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        sendDebugMessage("Word: " .. tprint(word,1,2))
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

                tarot_desc = description
            ::continue::
            end
        end
		cards[#cards+1] = tarot_desc
    end
    return cards
end

-- playing card stuff
function getRunText:get_card_modifiers(card_hand) -- TODO: port this to other context stuff
    local cards = {}

	for pos, card in ipairs(card_hand) do
		local card_desc = pos .. ": " .. card.base.name

        if card.edition then
            for _, v in ipairs(G.P_CENTER_POOLS.Edition) do
                sendDebugMessage("card ability: " .. tprint(card.ability,1,2))
                local description
                if v.key == card.edition.key and v.loc_txt and type(v.loc_vars) == 'function' then
                    sendDebugMessage("running if: " .. v.loc_txt.name .. " loc_txt table: " .. tprint(v.loc_txt,1,2))
                    description = ", Card Edition: " .. v.loc_txt.name
                elseif v.key ~= card.edition.key then
                    goto continue
                else
                    sendDebugMessage("running else")
                    description = ", Card Edition: " .. card.ability.name
                end

                card_desc = card_desc .. description
                ::continue::
            end
        end

        if card.ability.effect ~= "Base" then
            for _, v in ipairs(G.P_CENTER_POOLS.Enhanced) do
                sendDebugMessage("card ability: " .. tprint(card.ability,1,2))
                local description
                if v.key == card.config.center_key and v.loc_txt and type(v.loc_vars) == 'function' then
                    sendDebugMessage("running if: " .. v.loc_txt.name .. " loc_txt table: " .. tprint(v.loc_txt,1,2))
                    description = ", Card Enhancement: " .. v.loc_txt.name
                elseif v.key ~= card.config.center_key then
                    goto continue
                else
                    sendDebugMessage("running else")
                    description = ", Card Enhancement: " .. card.ability.name
                end

                card_desc = card_desc .. description
                ::continue::
            end
        end

        if card.ability.seal then
            for _, v in ipairs(G.P_CENTER_POOLS.Seal) do
                sendDebugMessage("card ability: " .. tprint(card.ability,1,2))
                local description
                if v.key == card.seal and v.loc_txt and type(v.loc_vars) == 'function' then
                    sendDebugMessage("running if: " .. v.loc_txt.name .. " loc_txt table: " .. tprint(v.loc_txt,1,2))
                    description = ", Card Seal: " .. v.loc_txt.name
                elseif v.key ~= card.seal then
                    goto continue
                else
                    sendDebugMessage("running else")
                    description = ", Card Seal: " .. card.seal .. " Seal"
                end

                card_desc = card_desc .. description
                ::continue::
            end
        end

        cards[#cards+1] = "- " .. card_desc .. "\n"
    end


    return cards
end

function getRunText:get_hand_names(cards_table)
    local cards = {}
    for pos, card in ipairs(cards_table) do
        local name = card.base.name

		cards[#cards+1] = name
	end
	return cards
end

function getRunText:get_hand_editions(cards_table)
	local cards = {}
	for _, card in ipairs(cards_table) do

        local edition_desc = ""

        if card.edition then
            local key_override
            for _, g_card in pairs(G.P_CENTER_POOLS.Edition) do
                if g_card.key ~= card.edition.key then goto continue end
                local loc_lookup = Edition_Loc[g_card.key]
                local loc_args = {}
                local loc_nodes = {}
                local name = g_card.name
                if g_card.key == card.edition.key and g_card.loc_txt and type(g_card.loc_vars) == 'function' then
                    sendDebugMessage("g_card: " .. tprint(g_card,1,2))
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

                localize{type = 'descriptions', key = g_card.key or key_override, set = g_card.set or card.ability.set, nodes = loc_nodes, vars = loc_args}

                local description = "\n -- " .. name .. " : "
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

function getRunText:get_hand_enhancements(cards_table)
    local cards = {}
	for pos, card in ipairs(cards_table) do

        local enhancement_desc = ""

        if card.ability.effect ~= "Base" then
            local key_override
            for _, g_card in pairs(G.P_CENTER_POOLS.Enhanced) do
                if g_card.key ~= card.config.center_key then goto continue end
                local loc_lookup = Enhancement_Loc[g_card.key]
                local loc_args = {}
                local loc_nodes = {}
                local name = card.ability.name
                if g_card.key == card.config.center_key and g_card.loc_txt or type(g_card.loc_vars) == 'function' then
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

                localize{type = 'descriptions', key = g_card.key or key_override, set = g_card.set, nodes = loc_nodes, vars = loc_args} -- doesn't get character's like + idk why, needs to be fixed before shipping though

                local description = "\n -- " .. name .. " : "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if word.nodes ~= nil then
                            sendDebugMessage(word.nodes[1].config.object.string)
                            description = description .. word.nodes[1].config.object.string
                        else
                            if not word.config.text then break end -- removes table that contains stuff for setting up UI
                            description = description .. word.config.text
                        end
                        description = description .. " "
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

function getRunText:get_hand_seals(cards_table)
    local cards = {}

	for pos, card in ipairs(cards_table) do

        local seal_desc = ""

        if card.ability.seal then
            local key_override = nil
            for _, v in pairs(G.P_CENTER_POOLS.Seal) do
                local loc_args,loc_nodes = Seal_Loc[card.seal], {}
                if v.key ~= card.seal then goto continue end
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars() or {}
                    loc_args = res.vars or {}
                    key_override = v.key .. '_seal' -- Smods does this however doesn't mention it in any documentation :)
                else
                    key_override = loc_args[1]
                    loc_args = {}
                end

                localize{type = 'descriptions', set = "Other" or v.set, key= key_override or v.key, nodes = loc_nodes, vars = loc_args}

                local description = "\n -- " .. tostring(card.seal) .. " Seal"  .. " : "
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
        if table.any(cards, function(seal) return seal == seal_desc end) then seal_desc = "" end -- remove duplicates
		cards[#cards+1] = seal_desc
    end
    return cards
end

function getRunText:get_current_hand_modifiers(cards_table)
    local enhancements = table.table_to_string(self:get_hand_enhancements(cards_table))
    local editions = table.table_to_string(self:get_hand_editions(cards_table))
    local seals = table.table_to_string(self:get_hand_seals(cards_table))

    local enhancements_string = "- card enhancements: " .. enhancements
    local editions_string = "- card editions: " .. editions
    local seals_string = "- card seals: " .. seals

    sendDebugMessage("enhancement: " .. enhancements)
    sendDebugMessage("editions: " .. editions)
    sendDebugMessage("seals: " .. seals)

    -- figure out better way to do this because sometimes this doesn't work even if there are no modifiers
    if enhancements == "" or enhancements == nil then
        enhancements_string = "There are no enhancements on your cards"
    end
    if editions == "" or editions == nil then
        editions_string = "There are no editions on your cards"
    end
    if seals == "" or seals == nil then
        seals_string = "There are no seals on your cards"
    end

    return enhancements_string,editions_string,seals_string
end

return getRunText