-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

local JsonUtils = {}

function wrap_schema(schema, add_required)
    if add_required == nil then
        add_required = true
    end
    if add_required then
        return {
            type = "object",
            properties = schema,
            required = table.get_keys(schema)
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
