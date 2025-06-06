-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local WsMessage = ModCache.load("game-sdk/messages/api/ws_message.lua")

local OutgoingMessage = {}
OutgoingMessage.__index = OutgoingMessage

function OutgoingMessage:new()
    local obj = setmetatable({}, self)
    return obj
end

function OutgoingMessage:_get_command()
    print("Error: OutgoingMessage._get_command() is not implemented.")
    return "invalid"
end

function OutgoingMessage:_get_data()
    return {}
end

function OutgoingMessage:merge(_other)
    return false
end

function OutgoingMessage:get_ws_message()
    return WsMessage:new(self:_get_command(), self:_get_data(), "Balatro")
end

return OutgoingMessage
