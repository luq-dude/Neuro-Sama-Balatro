-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude and pandapanda135
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