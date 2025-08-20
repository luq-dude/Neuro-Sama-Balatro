-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

EMPTY_REQUIRED_TABLE = {} -- this is also used in json.lua ,I know global vars are bad pls don't yell at me :'(

local JsonUtils = {}

function wrap_schema(schema, add_required)
    if add_required == nil then
        add_required = true
    end
    if add_required then
        local required = table.get_keys(schema)
        if #required== 0 then
            required = {EMPTY_REQUIRED_TABLE}
        end
        return {
            type = "object",
            properties = schema,
            required = required
        }
    else
        return {
            type = "object",
            properties = schema
        }
    end
end

JsonUtils.wrap_schema = wrap_schema

return JsonUtils
