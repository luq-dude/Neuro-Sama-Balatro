local GetModifierArgs = ModCache.load("card_modifiers_args.lua")

local getRunText = {}

local function get_planet_args(name, effect_config)
    sendDebugMessage("effect_config" .. tprint(effect_config,1))
    local loc_args = {}
    if name == "Ceres" then loc_args = {effect_config.config}
    elseif name == "Earth" then loc_args = {effect_config.config}
    elseif name == "Eris" then loc_args = {effect_config.config}
    elseif name == "Jupiter" then loc_args = {effect_config.config}
	elseif name == "Mars" then loc_args = {effect_config.config}
	elseif name == "Mercury" then loc_args = {effect_config.config}
	elseif name == "Neptune" then loc_args = {effect_config.config}
	elseif name == "Planet X" then loc_args = {effect_config.config}
	elseif name == "Pluto" then loc_args = {effect_config.config}
	elseif name == "Saturn" then loc_args = {effect_config.config}
	elseif name == "Uranus" then loc_args = {effect_config.config}
	elseif name == "Venus" then loc_args = {effect_config.config}
	end

    return loc_args
end

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
                local loc_args,loc_nodes = get_planet_args(card.ability.name,v.config), {}
                local name = card.ability.name

                if v.key ~= card.config.center_key then goto continue end
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars() or {}
                    loc_args = res.vars or {}
                    key_override = v.key
                    name = v.loc_txt.name
				else
                    key_override = card.config.center_key
                end

                -- Idk what this does but it works with vanilla and modded so it's good enough for me
                loc_args = {
                    G.GAME.hands[v.config.hand_type].level,localize(v.config.hand_type, 'poker_hands'), G.GAME.hands[v.config.hand_type].l_mult, G.GAME.hands[v.config.hand_type].l_chips,
                    colours = {(G.GAME.hands[v.config.hand_type].level==1 and G.C.UI.TEXT_DARK or G.C.HAND_LEVELS[math.min(7, G.GAME.hands[v.config.hand_type].level)])}
                }

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

local function get_joker_args(name, card_ability,card)
    sendDebugMessage("effect_config" .. tprint(card_ability,1))
    local loc_args = {}

    -- this should be all jokers not 100% sure though
    if card_ability.name == 'Joker' then loc_args = {card_ability.mult}
    elseif card_ability.name == 'Jolly Joker' or card_ability.name == 'Zany Joker' or
        card_ability.name == 'Mad Joker' or card_ability.name == 'Crazy Joker'  or 
        card_ability.name == 'Droll Joker' then 
        loc_args = {card_ability.t_mult, localize(card_ability.type, 'poker_hands')}
    elseif card_ability.name == 'Sly Joker' or card_ability.name == 'Wily Joker' or
    card_ability.name == 'Clever Joker' or card_ability.name == 'Devious Joker'  or 
    card_ability.name == 'Crafty Joker' then 
        loc_args = {card_ability.t_chips, localize(card_ability.type, 'poker_hands')}
    elseif card_ability.name == 'Half Joker' then loc_args = {card_ability.extra.mult, card_ability.extra.size}
    elseif card_ability.name == 'Fortune Teller' then loc_args = {card_ability.extra, (G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot or 0)}
    elseif card_ability.name == 'Steel Joker' then loc_args = {card_ability.extra, 1 + card_ability.extra*(card_ability.steel_tally or 0)}
    elseif card_ability.name == 'Chaos the Clown' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Space Joker' then loc_args = {''..(G.GAME and G.GAME.probabilities.normal or 1), card_ability.extra}
    elseif card_ability.name == 'Stone Joker' then loc_args = {card_ability.extra, card_ability.extra*(card_ability.stone_tally or 0)}
    elseif card_ability.name == 'Drunkard' then loc_args = {card_ability.d_size}
    elseif card_ability.name == 'Green Joker' then loc_args = {card_ability.extra.hand_add, card_ability.extra.discard_sub, card_ability.mult}
    elseif card_ability.name == 'Credit Card' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Greedy Joker' or card_ability.name == 'Lusty Joker' or
        card_ability.name == 'Wrathful Joker' or card_ability.name == 'Gluttonous Joker' then loc_args = {card_ability.extra.s_mult, localize(card_ability.extra.suit, 'suits_singular')}
    elseif card_ability.name == 'Blue Joker' then loc_args = {card_ability.extra, card_ability.extra*((G.deck and G.deck.cards) and #G.deck.cards or 52)}
    elseif card_ability.name == 'Sixth Sense' then loc_args = {}
    elseif card_ability.name == 'Mime' then
    elseif card_ability.name == 'Hack' then loc_args = {card_ability.extra+1}
    elseif card_ability.name == 'Pareidolia' then 
    elseif card_ability.name == 'Faceless Joker' then loc_args = {card_ability.extra.dollars, card_ability.extra.faces}
    elseif card_ability.name == 'Oops! All 6s' then
    elseif card_ability.name == 'Juggler' then loc_args = {card_ability.h_size}
    elseif card_ability.name == 'Golden Joker' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Joker Stencil' then loc_args = {card_ability.x_mult}
    elseif card_ability.name == 'Four Fingers' then
    elseif card_ability.name == 'Ceremonial Dagger' then loc_args = {card_ability.mult}
    elseif card_ability.name == 'Banner' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Misprint' then
        local r_mults = {}
        for i = card_ability.extra.min, card_ability.extra.max do
            r_mults[#r_mults+1] = tostring(i)
        end
        local loc_mult = ' '..(localize('k_mult'))..' '
        card.main_start = {
            {n=G.UIT.T, config={text = '  +',colour = G.C.MULT, scale = 0.32}},
            {n=G.UIT.O, config={object = DynaText({string = r_mults, colours = {G.C.RED},pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.5, scale = 0.32, min_cycle_time = 0})}},
            {n=G.UIT.O, config={object = DynaText({string = {
                {string = 'rand()', colour = G.C.JOKER_GREY},{string = "#@"..(G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.id or 11)..(G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.suit:sub(1,1) or 'D'), colour = G.C.RED},
                loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult},
            colours = {G.C.UI.TEXT_DARK},pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.2011, scale = 0.32, min_cycle_time = 0})}},
        }
    elseif card_ability.name == 'Mystic Summit' then loc_args = {card_ability.extra.mult, card_ability.extra.d_remaining}
    elseif card_ability.name == 'Marble Joker' then
    elseif card_ability.name == 'Loyalty Card' then loc_args = {card_ability.extra.Xmult, card_ability.extra.every + 1, localize{type = 'variable', key = (card_ability.loyalty_remaining == 0 and 'loyalty_active' or 'loyalty_inactive'), vars = {card_ability.loyalty_remaining}}}
    elseif card_ability.name == '8 Ball' then loc_args = {''..(G.GAME and G.GAME.probabilities.normal or 1),card_ability.extra}
    elseif card_ability.name == 'Dusk' then loc_args = {card_ability.extra+1}
    elseif card_ability.name == 'Raised Fist' then
    elseif card_ability.name == 'Fibonacci' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Scary Face' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Abstract Joker' then loc_args = {card_ability.extra, (G.jokers and G.jokers.cards and #G.jokers.cards or 0)*card_ability.extra}
    elseif card_ability.name == 'Delayed Gratification' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Gros Michel' then loc_args = {card_ability.extra.mult, ''..(G.GAME and G.GAME.probabilities.normal or 1), card_ability.extra.odds}
    elseif card_ability.name == 'Even Steven' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Odd Todd' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Scholar' then loc_args = {card_ability.extra.mult, card_ability.extra.chips}
    elseif card_ability.name == 'Business Card' then loc_args = {''..(G.GAME and G.GAME.probabilities.normal or 1), card_ability.extra}
    elseif card_ability.name == 'Supernova' then
    elseif card_ability.name == 'Spare Trousers' then loc_args = {card_ability.extra, localize('Two Pair', 'poker_hands'), card_ability.mult}
    elseif card_ability.name == 'Superposition' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Ride the Bus' then loc_args = {card_ability.extra, card_ability.mult}
    elseif card_ability.name == 'Egg' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Burglar' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Blackboard' then loc_args = {card_ability.extra, localize('Spades', 'suits_plural'), localize('Clubs', 'suits_plural')}
    elseif card_ability.name == 'Runner' then loc_args = {card_ability.extra.chips, card_ability.extra.chip_mod}
    elseif card_ability.name == 'Ice Cream' then loc_args = {card_ability.extra.chips, card_ability.extra.chip_mod}
    elseif card_ability.name == 'DNA' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Splash' then
    elseif card_ability.name == 'Constellation' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'Hiker' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'To Do List' then loc_args = {card_ability.extra.dollars, localize(card_ability.to_do_poker_hand, 'poker_hands')}
    elseif card_ability.name == 'Smeared Joker' then
    elseif card_ability.name == 'Blueprint' then
        card_ability.blueprint_compat_ui = card_ability.blueprint_compat_ui or ''; card_ability.blueprint_compat_check = nil
        card.main_end = (card.area and card.area == G.jokers) and {
            {n=G.UIT.C, config={align = "bm", minh = 0.4}, nodes={
                {n=G.UIT.C, config={ref_table = card, align = "m", colour = G.C.JOKER_GREY, r = 0.05, padding = 0.06, func = 'blueprint_compat'}, nodes={
                    {n=G.UIT.T, config={ref_table = card_ability, ref_value = 'blueprint_compat_ui',colour = G.C.UI.TEXT_LIGHT, scale = 0.32*0.8}},
                }}
            }}
        } or nil
    elseif card_ability.name == 'Cartomancer' then
    elseif card_ability.name == 'Astronomer' then loc_args = {card_ability.extra}
    
    elseif card_ability.name == 'Golden Ticket' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Mr. Bones' then
    elseif card_ability.name == 'Acrobat' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Sock and Buskin' then loc_args = {card_ability.extra+1}
    elseif card_ability.name == 'Swashbuckler' then loc_args = {card_ability.mult}
    elseif card_ability.name == 'Troubadour' then loc_args = {card_ability.extra.h_size, -card_ability.extra.h_plays}
    elseif card_ability.name == 'Certificate' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Throwback' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'Hanging Chad' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Rough Gem' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Bloodstone' then loc_args = {''..(G.GAME and G.GAME.probabilities.normal or 1), card_ability.extra.odds, card_ability.extra.Xmult}
    elseif card_ability.name == 'Arrowhead' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Onyx Agate' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Glass Joker' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'Showman' then
    elseif card_ability.name == 'Flower Pot' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Wee Joker' then loc_args = {card_ability.extra.chips, card_ability.extra.chip_mod}
    elseif card_ability.name == 'Merry Andy' then loc_args = {card_ability.d_size, card_ability.h_size}
    elseif card_ability.name == 'The Idol' then loc_args = {card_ability.extra, localize(G.GAME.current_round.idol_card.rank, 'ranks'), localize(G.GAME.current_round.idol_card.suit, 'suits_plural'), colours = {G.C.SUITS[G.GAME.current_round.idol_card.suit]}}
    elseif card_ability.name == 'Seeing Double' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Matador' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Hit the Road' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'The Duo' or card_ability.name == 'The Trio'
        or card_ability.name == 'The Family' or card_ability.name == 'The Order' or card_ability.name == 'The Tribe' then loc_args = {card_ability.x_mult, localize(card_ability.type, 'poker_hands')}
    
    elseif card_ability.name == 'Cavendish' then loc_args = {card_ability.extra.Xmult, ''..(G.GAME and G.GAME.probabilities.normal or 1), card_ability.extra.odds}
    elseif card_ability.name == 'Card Sharp' then loc_args = {card_ability.extra.Xmult}
    elseif card_ability.name == 'Red Card' then loc_args = {card_ability.extra, card_ability.mult}
    elseif card_ability.name == 'Madness' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'Square Joker' then loc_args = {card_ability.extra.chips, card_ability.extra.chip_mod}
    elseif card_ability.name == 'Seance' then loc_args = {localize(card_ability.extra.poker_hand, 'poker_hands')}
    elseif card_ability.name == 'Riff-raff' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Vampire' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'Shortcut' then
    elseif card_ability.name == 'Hologram' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'Vagabond' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Baron' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Cloud 9' then loc_args = {card_ability.extra, card_ability.extra*(card_ability.nine_tally or 0)}
    elseif card_ability.name == 'Rocket' then loc_args = {card_ability.extra.dollars, card_ability.extra.increase}
    elseif card_ability.name == 'Obelisk' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'Midas Mask' then
    elseif card_ability.name == 'Luchador' then
        local has_message= (G.GAME and card.area and (card.area == G.jokers)) -- TODO: self should equal the card class I think so add that to this
        if has_message then
            local disableable = G.GAME.blind and ((not G.GAME.blind.disabled) and (G.GAME.blind:get_type() == 'Boss'))
            card.main_end = {
                {n=G.UIT.C, config={align = "bm", minh = 0.4}, nodes={
                    {n=G.UIT.C, config={ref_table = card, align = "m", colour = disableable and G.C.GREEN or G.C.RED, r = 0.05, padding = 0.06}, nodes={
                        {n=G.UIT.T, config={text = ' '..localize(disableable and 'k_active' or 'ph_no_boss_active')..' ',colour = G.C.UI.TEXT_LIGHT, scale = 0.32*0.9}},
                    }}
                }}
            }
        end
    elseif card_ability.name == 'Photograph' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Gift Card' then  loc_args = {card_ability.extra}
    elseif card_ability.name == 'Turtle Bean' then loc_args = {card_ability.extra.h_size, card_ability.extra.h_mod}
    elseif card_ability.name == 'Erosion' then loc_args = {card_ability.extra, math.max(0,card_ability.extra*(G.playing_cards and (G.GAME.starting_deck_size - #G.playing_cards) or 0)), G.GAME.starting_deck_size}
    elseif card_ability.name == 'Reserved Parking' then loc_args = {card_ability.extra.dollars, ''..(G.GAME and G.GAME.probabilities.normal or 1), card_ability.extra.odds}
    elseif card_ability.name == 'Mail-In Rebate' then loc_args = {card_ability.extra, localize(G.GAME.current_round.mail_card.rank, 'ranks')}
    elseif card_ability.name == 'To the Moon' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Hallucination' then loc_args = {G.GAME.probabilities.normal, card_ability.extra}
    elseif card_ability.name == 'Lucky Cat' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'Baseball Card' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Bull' then loc_args = {card_ability.extra, card_ability.extra.math.max(0,G.GAME.dollars) or 0}
    elseif card_ability.name == 'Diet Cola' then loc_args = {localize{type = 'name_text', set = 'Tag', key = 'tag_double', nodes = {}}}
    elseif card_ability.name == 'Trading Card' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Flash Card' then loc_args = {card_ability.extra, card_ability.mult}
    elseif card_ability.name == 'Popcorn' then loc_args = {card_ability.mult, card_ability.extra}
    elseif card_ability.name == 'Ramen' then loc_args = {card_ability.x_mult, card_ability.extra}
    elseif card_ability.name == 'Ancient Joker' then loc_args = {card_ability.extra, localize(G.GAME.current_round.ancient_card.suit, 'suits_singular'), colours = {G.C.SUITS[G.GAME.current_round.ancient_card.suit]}}
    elseif card_ability.name == 'Walkie Talkie' then loc_args = {card_ability.extra.chips, card_ability.extra.mult}
    elseif card_ability.name == 'Seltzer' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Castle' then loc_args = {card_ability.extra.chip_mod, localize(G.GAME.current_round.castle_card.suit, 'suits_singular'), card_ability.extra.chips, colours = {G.C.SUITS[G.GAME.current_round.castle_card.suit]}}
    elseif card_ability.name == 'Smiley Face' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Campfire' then loc_args = {card_ability.extra, card_ability.x_mult}
    elseif card_ability.name == 'Stuntman' then loc_args = {card_ability.extra.chip_mod, card_ability.extra.h_size}
    elseif card_ability.name == 'Invisible Joker' then loc_args = {card_ability.extra, card_ability.invis_rounds}
    elseif card_ability.name == 'Brainstorm' then
        card_ability.blueprint_compat_ui = card_ability.blueprint_compat_ui or ''; card_ability.blueprint_compat_check = nil
        card.main_end = (card.area and card.area == G.jokers) and {
            {n=G.UIT.C, config={align = "bm", minh = 0.4}, nodes={
                {n=G.UIT.C, config={ref_table = card, align = "m", colour = G.C.JOKER_GREY, r = 0.05, padding = 0.06, func = 'blueprint_compat'}, nodes={
                    {n=G.UIT.T, config={ref_table = card_ability, ref_value = 'blueprint_compat_ui',colour = G.C.UI.TEXT_LIGHT, scale = 0.32*0.8}},
                }}
            }}
        } or nil
    elseif card_ability.name == 'Satellite' then
        local planets_used = 0
        for k, v in pairs(G.GAME.consumeable_usage) do if v.set == 'Planet' then planets_used = planets_used + 1 end end
        loc_args = {card_ability.extra, planets_used*card_ability.extra}
    elseif card_ability.name == 'Shoot the Moon' then loc_args = {card_ability.extra}
    elseif card_ability.name == "Driver's License" then loc_args = {card_ability.extra, card_ability.driver_tally or '0'}
    elseif card_ability.name == 'Burnt Joker' then
    elseif card_ability.name == 'Bootstraps' then loc_args = {card_ability.extra.mult, card_ability.extra.dollars, card_ability.extra.mult*math.floor((G.GAME.dollars + (G.GAME.dollar_buffer or 0))/card_ability.extra.dollars)}
    elseif card_ability.name == 'Caino' then loc_args = {card_ability.extra, card_ability.caino_xmult}
    elseif card_ability.name == 'Triboulet' then loc_args = {card_ability.extra}
    elseif card_ability.name == 'Yorick' then loc_args = {card_ability.extra.xmult, card_ability.extra.discards, card_ability.yorick_discards, card_ability.x_mult}
    elseif card_ability.name == 'Chicot' then
    elseif card_ability.name == 'Perkeo' then loc_args = {card_ability.extra}
    end

    return loc_args
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
                local loc_args,loc_nodes = get_joker_args(card.ability.name,card.ability,card), {}
                local name = card.ability.name

                if v.key ~= card.config.center_key then goto continue end
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars({},card) or {} -- need to pass these to get vars (atleast in neurocards mod)
                    loc_args = res.vars or {}
                    key_override = v.key
                    name = v.loc_txt.name -- get name that shows on hover
				else
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

local function get_spectral_args(name, effect_config)
    sendDebugMessage("effect_config" .. tprint(effect_config,1))
    local loc_args = {}
    if name == "Familiar" then loc_args = {effect_config.extra}
    elseif name == "Grim" then loc_args = {effect_config.extra}
    elseif name == "Incantation" then loc_args = {effect_config.extra}
    elseif name == "Talisman" then loc_args = {key = 'gold_seal', set = 'Other'}
	elseif name == "Aura" then loc_args = {}
	elseif name == "Wraith" then loc_args = {}
	elseif name == "Sigil" then loc_args = {}
	elseif name == "Ouija" then loc_args = {}
	elseif name == "Ectoplasm" then loc_args = {G.GAME.ecto_minus or 1}
	elseif name == "Immolate" then loc_args = {effect_config.extra.destroy,effect_config.extra.dollars}
	elseif name == "Ankh" then loc_args = {G.P_CENTERS.e_negative}
	elseif name == "Deja Vu" then loc_args = {key = 'red_seal', set = 'Other'}
    elseif name == "Hex" then loc_args = {G.P_CENTERS.e_polychrome}
    elseif name == "Trance" then loc_args = {key = 'blue_seal', set = 'Other'}
    elseif name == "Medium" then loc_args = {key = 'purple_seal', set = 'Other'}
    elseif name == "Cryptid" then loc_args = {effect_config.extra}
    elseif name == "The Soul" then loc_args = {}
    elseif name == "Black Hole" then loc_args = {}
	end

    return loc_args
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
            for _, v in pairs(G.P_CENTER_POOLS.Spectral) do
                local loc_args,loc_nodes = get_spectral_args(card.ability.name,card.ability), {}
                local name = card.ability.name

                if v.key ~= card.config.center_key then goto continue end
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars({},card) or {} -- need to pass these to get vars (atleast in neurocards mod)
                    loc_args = res.vars or {}
                    key_override = v.key
                    name = v.loc_txt.name
				else
                    key_override = card.config.center_key
                end -- 100835

                localize{type = 'descriptions', key = v.key or key_override, set = v.set, nodes = loc_nodes, vars = loc_args}

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

local function get_tarot_args(name, effect_config)
    sendDebugMessage("effect_config" .. tprint(effect_config,1) .. " name: " .. name)
    local loc_args = {}
    if name == "The Fool" then loc_args = {}
    elseif name == "The Magician" then loc_args = {effect_config.max_highlighted,localize{type = 'name_text', set = 'Enhanced', key = effect_config.mod_conv}}
    elseif name == "The High Priestess" then loc_args = {effect_config.planets}
    elseif name == "The Empress" then loc_args = {effect_config.max_highlighted,localize{type = 'name_text', set = 'Enhanced', key = effect_config.mod_conv}}
	elseif name == "The Emperor" then loc_args = {effect_config.tarots}
	elseif name == "The Hierophant" then loc_args = {effect_config.max_highlighted,localize{type = 'name_text', set = 'Enhanced', key = effect_config.mod_conv}}
	elseif name == "The Lovers" then loc_args = {effect_config.max_highlighted,localize{type = 'name_text', set = 'Enhanced', key = effect_config.mod_conv}}
	elseif name == "The Chariot" then loc_args = {effect_config.max_highlighted,localize{type = 'name_text', set = 'Enhanced', key = effect_config.mod_conv}}
	elseif name == "Justice" then loc_args = {effect_config.max_highlighted,localize{type = 'name_text', set = 'Enhanced', key = effect_config.mod_conv}}
	elseif name == "The Hermit" then loc_args = {effect_config.extra}
	elseif name == "The Wheel of Fortune" then loc_args = {G.GAME.probabilities.normal,effect_config.extra}
	elseif name == "Strength" then loc_args = {effect_config.max_highlighted}
    elseif name == "The Hanged Man" then loc_args = {effect_config.max_highlighted}
    elseif name == "Death" then loc_args = {effect_config.max_highlighted}
    elseif name == "Temperance" then loc_args = {effect_config.extra,effect_config.money}
    elseif name == "The Devil" then loc_args = {effect_config.max_highlighted,localize{type = 'name_text', set = 'Enhanced', key = effect_config.mod_conv}}
    elseif name == "The Tower" then loc_args = {effect_config.max_highlighted,localize{type = 'name_text', set = 'Enhanced', key = effect_config.mod_conv}}
    elseif name == "The Star" then loc_args = {effect_config.max_highlighted,localize(effect_config.suit_conv, 'suits_plural'),colours = {G.C.SUITS[effect_config.suit_conv]}}
    elseif name == "The Moon" then loc_args = {effect_config.max_highlighted,localize(effect_config.suit_conv, 'suits_plural'),colours = {G.C.SUITS[effect_config.suit_conv]}}
    elseif name == "The Sun" then loc_args = {effect_config.max_highlighted,localize(effect_config.suit_conv, 'suits_plural'),colours = {G.C.SUITS[effect_config.suit_conv]}}
    elseif name == "Judgement" then loc_args = {}
    elseif name == "The World" then loc_args = {effect_config.max_highlighted,localize(effect_config.suit_conv, 'suits_plural'),colours = {G.C.SUITS[effect_config.suit_conv]}}
	end

    return loc_args
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
            for _, v in pairs(G.P_CENTER_POOLS.Tarot) do
                local loc_args,loc_nodes = get_tarot_args(card.ability.name,card.ability), {}

                sendDebugMessage("This is tarot: " .. v.key .. " card.config: " .. card.config.center_key)
                if v.key ~= card.config.center_key then goto continue end
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars({},card) or {}
                    loc_args = res.vars or {}
                    key_override = v.key
				else
                    key_override = card.config.center_key
                end

                localize{type = 'descriptions', key = v.key or key_override, set = v.set or card.ability.set, nodes = loc_nodes, vars = loc_args}

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

	for _, card in ipairs(card_hand) do
		local card_desc = card.base.name or ""

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
            for _, v in pairs(G.P_CENTER_POOLS.Edition) do
                local loc_args,loc_nodes = GetModifierArgs.get_edition_args(card.edition.type,G.P_CENTERS[v.key]), {}
                if v.key ~= card.edition.key then goto continue end -- go next loop if not the same as card
                sendDebugMessage("card stuff: " .. card.edition.type .. "  card: " .. tprint(card,1,2))
                if v.loc_vars and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars() or {}
                    loc_args = res.vars or loc_args
                end
                key_override = v.key

                localize{type = "descriptions", set = 'Edition',key= key_override or card.key, nodes = loc_nodes, vars = loc_args}

                local description = "\n -- " .. tostring(card.edition.name) .. " : "
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
            for _, v in pairs(G.P_CENTER_POOLS.Enhanced) do
                local loc_args,loc_nodes = GetModifierArgs:get_enhancements_args(card.ability.name,G.P_CENTERS[v.key]), {}
                if v.key ~= card.config.center_key then goto continue end -- go next loop if not the same as card
                if v.loc_txt and type(v.loc_vars) == 'function' then
                    local res = v:loc_vars(nil,card) or {} -- makes twins card work and glorp still works so I think its fine
                    loc_args = res.vars or {}
                end
                key_override = v.key

                localize{type = "descriptions", set = 'Enhanced',key= key_override or card.config.original_key, nodes = loc_nodes, vars = loc_args}  -- TODO: doesnt get + in mult card idk why

                local description = "\n -- " .. tostring(card.ability.name) .. " : "
                for _, line in ipairs(loc_nodes) do
                    for _, word in ipairs(line) do
                        if not word.config.text then break end -- removes table that contains stuff for setting up UI
                        sendDebugMessage("word: " .. tostring(word))
                        description = description .. word.config.text .. " "
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

    local seals = {"gold_seal","red_seal","blue_seal","purple_seal"} -- bad but I'm a bit too lazy to find another way and it works

	for pos, card in ipairs(cards_table) do

        local seal_desc = ""

        if card.ability.seal then
            local key_override = nil
            for _, v in pairs(G.P_CENTER_POOLS.Seal) do
                local loc_args,loc_nodes = GetModifierArgs:get_seals_args(card.seal), {}
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