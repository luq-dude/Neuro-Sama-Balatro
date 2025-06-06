-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local OutgoingMessage = ModCache.load("game-sdk/messages/api/outgoing_message.lua")
local ActionsRegister = ModCache.load("game-sdk/messages/outgoing/actions_register.lua")

local ActionsUnregister = setmetatable({}, { __index = OutgoingMessage })
ActionsUnregister.__index = ActionsUnregister

function ActionsUnregister:new(actions)
    local obj = OutgoingMessage.new(self)
    obj._names = table.map(actions, function(action) return action.name end)
    return obj
end

function ActionsUnregister:_get_command()
    return "actions/unregister"
end

function ActionsUnregister:_get_data()
    return { action_names = self._names }
end

function ActionsUnregister:merge(other)
    if getmetatable(other) ~= ActionsRegister then
        return false
    end
    self._names = table.filter(self._names, function(my_name)
        return not table.any(other._names, function(other_name)
            return other_name == my_name
        end)
    end)

    for _, their_action in ipairs(other._actions) do
        table.insert(self._names, their_action)
    end

    return true
end


return ActionsUnregister