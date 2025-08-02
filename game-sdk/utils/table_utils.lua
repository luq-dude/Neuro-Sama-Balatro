-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

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