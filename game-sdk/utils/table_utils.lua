-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude and pandapanda135

function tprint(tbl, indent, max_depth)
    indent = indent or 0
    max_depth = max_depth or 5
    if max_depth < 0 then
        return string.rep(" ", indent) .. "{...}"
    end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2, max_depth - 1) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end

function table.filter(tbl, predicate)
    local result = {}
    for _, value in ipairs(tbl) do
        if predicate(value) then
            table.insert(result, value)
        end
    end
    return result
end

function table.any(tbl, predicate)
    for _, value in ipairs(tbl) do
        if predicate(value) then
            return true
        end
    end
    return false
end

function table.map(tbl, transform)
    local result = {}
    for i, value in ipairs(tbl) do
        result[i] = transform(value)
    end
    return result
end

function table.get_keys(t)
    local keys = {}
    for key, _ in pairs(t) do
        table.insert(keys, key)
    end
    return keys
end

function table.table_to_string(tbl)
    local s = ""
    for i, value in ipairs(tbl) do
        s = s .. tostring(value)
        -- if i < #tbl then s = s .. "," end
    end
    return s
end

function table.reverse(tbl)
    for i = 1, math.floor(#tbl/2), 1 do
        tbl[i], tbl[#tbl-i+1] = tbl[#tbl-i+1], tbl[i]
    end
    return tbl
end

function table.index_of(tbl,val)
    for index, value in ipairs(tbl) do
        if value == val then
            return index
        end
    end
    return nil
end

function table.contains(tbl,val)
    for _, value in pairs(tbl) do
        if value == val then
            return true
        end
    end
    return false
end

function table.contains_key(tbl,val)
    for key, _ in pairs(tbl) do
        if key == val then
            return true
        end
    end
    return false
end

function table.combine_tables(original_tbl,move_tbl)
    local replica_table = {}
    for _, value in ipairs(original_tbl) do
        replica_table[#replica_table+1] = value
    end
    for _, value in ipairs(move_tbl) do
        table.insert(replica_table,value)
    end

    return replica_table
end

-- Reorders a list according to the specified indicies, moving items to the new_indices while appending any unspecified
-- items to the end
-- Example: Given list = {"A", "B", "C", "D", "E", "F", "G", "H"} and new_indicies = {2, 1, 5, 3, 4}
-- It'll return {"B", "A", "E", "C", "D", "F", "G", H"}
function table.reorder_list(list, new_indicies)
    local reordered = {}
    local moved = {}
    local curr = 1

    for _, index in ipairs(new_indicies) do
        reordered[curr] = list[index]
        moved[index] = true
        curr = curr + 1
    end

    for i = 1, #list do
        if not moved[i] then
            reordered[curr] = list[i]
            curr = curr + 1
        end
    end

    return reordered
end