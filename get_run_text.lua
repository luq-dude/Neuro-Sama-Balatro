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
-- This includes playing cards, jokers, consumables and vouchers
function GetRunText.get_card_description(card, include_debuff, add_cost, set_override, add_blueprint)
    local set = set_override or card.ability.set
    local loc_vars, main_start, main_end = card:generate_UIBox_ability_table(true)

    -- dont ask me how this works, it just does
    if not loc_vars or #loc_vars == 0 then
        loc_vars = generate_card_ui(card.config.center, nil, loc_vars, card.ability.set or "None", {}, false, main_start, main_end, card, true)
    end

    local p_card = G.P_CENTERS[card.config.center_key]
    local name = (p_card.loc_txt and p_card.loc_txt.name) or card.ability.name

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
            key = key_override or card.config.center.key,
            set = set,
            nodes = loc_nodes,
            vars = vars_override or loc_vars,
            AUT = card:generate_UIBox_ability_table()}
    end
    local modifiers = get_card_modifiers(card)
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
        {G.P_CENTER_POOLS.Edition, Edition_Loc, editions},
        {G.P_CENTER_POOLS.Enhanced, Enhancement_Loc, enhancements},
        {G.P_CENTER_POOLS.Seal, Seal_Loc, seals}
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


-- just calls get_all_modifiers but puts them all in a single string
function GetRunText.get_all_modifier_desc()
    local edi,enh,seal = GetRunText.get_all_modifiers()
    local ret = "These are all the playing card and joker modifiers in the game. " ..
        "A playing card can only have one edition, enhancement and seal at a time, while jokers can only have one edition. " ..
        "You should remember these: " ..
        "\n- Editions:" .. table.table_to_string(edi) ..
        "\n- Enhancements:" .. table.table_to_string(enh) ..
        "\n- Seals:" .. table.table_to_string(seal)

    return ret
end

return GetRunText