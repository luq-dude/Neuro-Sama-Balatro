require "functions/misc_functions"

local ALLOWED_DECKS = NEURO.CONFIG["ALLOWED_DECKS"]
local ALLOWED_STAKES = NEURO.CONFIG["ALLOWED_STAKES"]

local PreRunLoc = {}


local function get_lookup_tbl_description(obj, set, lookup_table)
    local lookup = lookup_table[obj.key]
    local args = {}
    local nodes = {}
    local desc = ""
    local key_override = nil
    if type(obj.loc_vars) == "function" then
        -- the object is a modded object with its own custom loc_vars function
        -- so call it to get the arguments and then call localize 
        local res = obj:loc_vars() or {}
        args = res.vars or {}
        key_override = res.key
    elseif type(lookup) == "table" then
        -- not a modded one, so lets get the args from the localization table
        -- in this case the localization table has a list of static strings as localization args
        for _, v in ipairs(lookup) do
            table.insert(args, obj.config[v])
        end
    elseif type(lookup) == "function" then
        -- in this case the localization table has a function that returns a string
        args = lookup(obj)
    end
    -- now just call localize
    localize { type = "descriptions", key = key_override or obj.key, set = set, nodes = nodes, vars = args }
    for _, line in ipairs(nodes) do
        for _, v in ipairs(line) do
            desc = desc .. v.config.text
        end
        desc = desc .. "   "
    end

    return desc
end


--- Returns the localized descriptions for objects in a center,
--- localized through the given localization table 
---@param center table The center of objects to get localized descriptions for
---@param set string The name of the set expected for objects in the center 
---@param whitelist table|nil Whitelist of names to get the descriptions for, or nil to get all
---@param lookup_table table The lookup localization table to use
---@return table The table of descriptions for the whitelisted objects in the given center, {1="name1: desc1", 2="name2: desc2", ...}
local function get_lookup_tbl_descriptions(center, set, whitelist, lookup_table)
    local objs = {}
    for _, obj in pairs(center) do
        local name = obj.loc_txt and obj.loc_txt.name or obj.name
        if obj.set == set and obj.unlocked and (type(whitelist) == "nil" or table.any(whitelist, function (check)
            return check == name
        end)) then
            objs[#objs+1] = name .. ": " .. get_lookup_tbl_description(obj, set, lookup_table)
        end
    end
    return objs
end

--- Returns a list of the names of objects from a center
--- @param center table The center of objects to get the name of
--- @param set string The expected set for objects in the center
--- @param key_indexed boolean true if the list should be indexed by object keys, false if it should be indexed by number
--- @param whitelist table|nil Whitelist of names to return, or nil for all
--- @return table The names of object in the center, indexed by key if key_indexed otherwise as a list
local function get_obj_names(center, set, key_indexed, whitelist)
    local objs = {}
    for _, obj in pairs(center) do
        local name
        if obj.set == set then
            if obj.loc_txt and obj.loc_txt.name then
                name = obj.loc_txt.name
            else
                name = obj.name
            end

            if (type(whitelist) == "nil" or table.any(whitelist, function (check)
                return check == name
            end)) then
                if key_indexed then
                    objs[obj.key] = name
                else
                    objs[#objs + 1] = name
                end
            end
        end
    end
    return objs
end

function PreRunLoc:get_back_descriptions()
    return get_lookup_tbl_descriptions(G.P_CENTER_POOLS.Back, "Back", ALLOWED_DECKS, NEURO.LOCS.BACK)
end

function PreRunLoc.get_back_desc(key)
    return get_lookup_tbl_description(G.P_CENTERS[key], "Back", NEURO.LOCS.BACK)
end

function PreRunLoc:get_back_names(keys, allDecks)
    local whitelist = ALLOWED_DECKS
    if allDecks then whitelist = nil end
    return get_obj_names(G.P_CENTER_POOLS.Back, "Back", keys, whitelist)
end

function PreRunLoc:get_stake_descriptions()
    return get_lookup_tbl_descriptions(G.P_CENTER_POOLS.Stake, "Stake", ALLOWED_STAKES, NEURO.LOCS.STAKE)
end

function PreRunLoc.get_stake_desc(key)
    return get_lookup_tbl_description(G.P_STAKES[key], "Stake", NEURO.LOCS.STAKE)
end

function PreRunLoc:get_stake_names(keys, allStakes)
    local whitelist = ALLOWED_STAKES
    if allStakes then whitelist = nil end
    return get_obj_names(G.P_CENTER_POOLS.Stake, "Stake", keys, whitelist)
end

return PreRunLoc
