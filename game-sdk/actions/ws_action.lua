-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

local WsAction = {}
WsAction.__index = WsAction

function WsAction:new(name, description, schema)
    local obj = setmetatable({
        name = name or "",
        description = description or "",
        schema = schema or nil,
    }, self)
    return obj
end

function WsAction:to_dict()
    return {
        name = self.name,
        description = self.description,
        schema = self.schema
    }
end

return WsAction