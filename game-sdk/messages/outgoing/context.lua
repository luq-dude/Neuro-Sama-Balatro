-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local WebsocketConnection = ModCache.load("game-sdk/websocket/websocket_connection.lua")
local OutgoingMessage = ModCache.load("game-sdk/messages/api/outgoing_message.lua")

local Context = setmetatable({}, { __index = OutgoingMessage })
Context.__index = Context

function Context:new(message, silent)
    local obj = OutgoingMessage.new(self)
    obj._message = message
    obj._silent = silent
    return obj
end

function Context:_get_command()
    return "context"
end

function Context:_get_data()
    return {
        message = self._message,
        silent = self._silent
    }
end

function Context.send(message, silent)
    silent = silent or false
    WebsocketConnection.send(Context:new(message, silent))
end


return Context
