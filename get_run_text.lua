local GetRunText = {}

local copy_jokers = {"j_blueprint", "j_brainstorm"} -- jokers that copy other jokers

local function add_card_buy_cost(description,card)
    if not card.cost then return end

    description = description .. ". Buy cost: " .. card.cost
    return description
end

local function description_from_loc_nodes(loc_nodes)
    local description = ""
    for _, line in ipairs(loc_nodes) do
        for _, word in ipairs(line) do
            if word.nodes ~= nil then
                if word.nodes[1].config.text ~= nil then
                    description = description .. word.nodes[1].config.text
                elseif word.nodes[1].config.object ~= nil then
                    description = description .. word.nodes[1].config.object.config.string[1]
                end
            else
                if not word.config.text then break end
                description = description .. word.config.text
            end
            description = description .. " "
        end
    end
    return description
end


local function get_card_modifiers(card)
    local modifiers = {
        edition=nil,
        enhancement=nil,
        seal=nil,
        debuffed = card.debuff,
        forced = card.ability.forced_selection,
        blueprint_compat = nil
    }

    if card.ability.set == "Joker" then
        modifiers.blueprint_compat = G.P_CENTERS[card.config.center_key].blueprint_compat
    end

    if card.edition then
        local proto = G.P_CENTERS[card.edition.key]
        modifiers.edition = (proto.loc_txt and proto.loc_txt.name) or proto.name
    end

    for k, v in pairs(SMODS.get_enhancements(card)) do
        local proto = G.P_CENTERS[k]
        modifiers.enhancement = (proto.loc_txt and proto.loc_txt.name) or proto.name
    end

    if card.seal then
        local proto = G.P_SEALS[card.seal]
        modifiers.seal = (proto.loc_txt and proto.loc_txt.name) or card.seal
    end
    return modifiers
end

-- Gets the description for any card object
-- This includes playing cards, jokers, consumables and vouchers (and tags)
function GetRunText.get_card_description(card, include_debuff, add_cost, set_override, add_blueprint)
    local set = set_override or card.ability.set
    local key = card.config.center_key or card.key

    local tag = false
    local loc_vars, main_start, main_end
    if card.generate_UIBox_ability_table then
        loc_vars, main_start, main_end = card:generate_UIBox_ability_table(true)
    elseif card.get_uibox_table then -- to support tags
        loc_vars = card:get_uibox_table(nil, true)
        set = "Tag"
        tag = true
    else
        sendErrorMessage(string.format("get_card_description called on invalid card/tag"))
    end

    -- dont ask me how this works, it just does
    if not tag and (not loc_vars or #loc_vars == 0) then
        loc_vars = generate_card_ui(card.config.center, nil, loc_vars, card.ability.set or "None", {}, false, main_start, main_end, card, true)
    end

    local p_card = G.P_CENTERS[key] or G.P_TAGS[key]
    local name = (p_card.loc_txt and p_card.loc_txt.name) or card.ability.name or card.name

    local key_override, vars_override, name_override
    if (not loc_vars or #loc_vars == 0) and p_card.loc_txt and type(p_card.loc_vars) == 'function' then
        local res = p_card:loc_vars({}, card) or {}
        vars_override = res.vars or {}
        key_override = res.key
    end

    local loc_nodes = {}
    local playing_card = card.playing_card or card.ability.set == 'Default' or card.ability.set == 'Enhanced'
    if playing_card then
        name_override = card.base.name
    else
        localize{
            type = 'descriptions',
            key = key_override or key,
            set = set_override or set,
            nodes = loc_nodes,
            vars = vars_override or loc_vars,
            AUT = not tag and card:generate_UIBox_ability_table()}
    end
    local modifiers = not tag and get_card_modifiers(card) or {}
    if playing_card and modifiers.enhancement == "Stone Card" then
        name_override = "Stone Card (+50 chips, no rank or suit)"
    end
    local desc = (name_override or name) .. (not playing_card and ": " .. description_from_loc_nodes(loc_nodes) or "")

    if modifiers.edition or
        modifiers.enhancement or
        modifiers.seal or
        modifiers.debuffed or
        modifiers.forced or
        add_blueprint then

        local mod_str = ""
        if modifiers.edition then mod_str = mod_str .. ", Edition: " .. modifiers.edition end
        if modifiers.enhancement and modifiers.enhancement ~= "Stone Card" then mod_str = mod_str .. ", Enhancement: " .. modifiers.enhancement end
        if modifiers.seal then mod_str = mod_str .. ", Seal: " .. modifiers.seal end
        if modifiers.debuffed and include_debuff then mod_str = mod_str .. ", Debuffed: " .. tostring(modifiers.edition) end
        if modifiers.forced then mod_str = mod_str .. ", Forced: " .. tostring(modifiers.edition) end
        if add_blueprint and type(modifiers.blueprint_compat) == "boolean" then
             mod_str = mod_str .. ", Blueprint/Brainstorm Compatible: " .. tostring(modifiers.blueprint_compat)
        end
        mod_str = "[" .. string.sub(mod_str, 3) .. "]"
        desc = desc .. " " .. mod_str
    end

    if add_cost then desc = add_card_buy_cost(desc,card) end
    return desc
end

function GetRunText.get_hand_details(hand, count, add_cost, set_override, check_blueprint)
    local details = {}
    local blueprint = false
    if check_blueprint then
        for _, v in ipairs(G.jokers.cards) do
            if table.any(copy_jokers, function (check) return check == v.config.center_key end) then
                blueprint = true
                break
            end
        end
    end

    for _, card in ipairs(hand) do
         details[#details+1] = (count and ("\n" .. "- " .. #details + 1 .. ": ") or "") .. GetRunText.get_card_description(card, true, add_cost, set_override, blueprint)
    end
    return details
end

local function get_modifiers_vars(card_table,loc_lookup)
    local description,name,loc_args = "","",{}
    if card_table.loc_txt then
        name = card_table.loc_txt.name
    end
    if type(card_table.loc_vars) == 'function' then
        loc_args = card_table:loc_vars({}, card_table:create_fake_card()).vars or {}
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
        sendErrorMessage(string.format("Could not find loc_vars for %s, defaulting to {}", card_table.key))
    end
    return description,name,loc_args
end


local function add_modifier_desc(descs, name, desc)
    descs[#descs+1] = "\n -- " .. name .. " : " .. desc
end

function GetRunText.get_all_modifiers()
    local editions, enhancements, seals = {}, {}, {}
    local sets = {
        {G.P_CENTER_POOLS.Edition, NEURO.LOCS.EDITION, editions},
        {G.P_CENTER_POOLS.Enhanced, NEURO.LOCS.ENHANCEMENT, enhancements},
        {G.P_CENTER_POOLS.Seal, NEURO.LOCS.SEAL, seals}
    }

    for _, mod_set in ipairs(sets) do
        local pool, loc, res = mod_set[1], mod_set[2], mod_set[3]

        for _, p_mod in pairs(pool) do
            if pool == G.P_CENTER_POOLS.Edition and p_mod.key == "e_negative" then
                add_modifier_desc(res, "Negative (on Jokers)", "+1 Joker slot")
                add_modifier_desc(res, "Negative (on Consumables)", "+1 Consumable slot")
                add_modifier_desc(res, "Negative (on Playing Card)", "+1 Hand size")
            else
                local key, set = p_mod.key, p_mod.set
                local desc, fname, args = get_modifiers_vars(p_mod, loc[key])
                local name = fname ~= "" and fname or (p_mod.label or p_mod.name or p_mod.key)
                local nodes = {}

                if pool == G.P_CENTER_POOLS.Enhanced then
                    if key == "m_bonus" or key == "m_stone" or key == "m_mult" then args[1] = SMODS.signed(args[1]) end
                    if key == "m_gold" then args[1] = SMODS.signed_dollars(args[1]) end

                    if key == "m_bonus" then key, set = "card_extra_chips", "Other" end
                end

                if pool == G.P_CENTER_POOLS.Seal then
                    if p_mod.loc_txt then
                        key = key .. "_seal"
                    else
                        name = name .. " seal"
                        key = args[1]
                    end
                    set = "Other"
                end

                localize{type='descriptions', key=key, set=set, nodes=nodes, vars=args}
                add_modifier_desc(res, name, description_from_loc_nodes(nodes) .. (desc or ""))
            end
        end
    end
    return editions, enhancements, seals
end

function GetRunText.get_blind_descriptions()
    local descs = {}
    for _, blind in pairs({"Small", "Big", "Boss"}) do
        local p_blind = G.P_BLINDS[G.GAME.round_resets.blind_choices[blind]]
        local chips = number_format(get_blind_amount(G.GAME.round_resets.blind_ante) * p_blind.mult *
            G.GAME.starting_params.ante_scaling)
        local status = G.GAME.round_resets.blind_states[blind]

        local desc = string.format("%s Blind (%s):\nRequired score to beat: %s\n",
            blind,
            status,
            chips
        )

        if blind ~= "Boss" then
            local tag = Tag(G.GAME.round_resets.blind_tags[blind], nil, blind)
            desc = desc .. string.format("Skip Reward: %s\n", GetRunText.get_card_description(tag))
        else
            local boss_desc = localize{type = 'raw_descriptions',
                                        key = p_blind.key,
                                        set = 'Blind',
                                        vars = { localize(G.GAME.current_round.most_played_poker_hand, 'poker_hands') } }
            desc = desc .. string.format("Boss Blind effect: %s", table.table_to_string(boss_desc))
        end
        descs[#descs+1] = desc
    end
    return descs
end

return GetRunText