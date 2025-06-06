-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local OutgoingMessage = ModCache.load("game-sdk/messages/api/outgoing_message.lua")

local ActionsRegister = setmetatable({}, { __index = OutgoingMessage })
ActionsRegister.__index = ActionsRegister

function ActionsRegister:new(actions)
    local obj = OutgoingMessage.new(self)
    obj._actions = actions or {}
    return obj
end

function ActionsRegister:_get_command()
    return "actions/register"
end

function ActionsRegister:_get_data()
    return { actions = self._actions }
end

function ActionsRegister:merge(other)
    if getmetatable(other) ~= ActionsRegister then
        return false
    end
    self._actions = table.filter(self._actions, function(my_action)
        return not table.any(other._actions, function(their_action)
            return my_action.name == their_action.name
        end)
    end)

    for _, their_action in ipairs(other._actions) do
        table.insert(self._actions, their_action)
    end

    return true
end

return ActionsRegister