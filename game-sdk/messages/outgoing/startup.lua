-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local OutgoingMessage = ModCache.load("game-sdk/messages/api/outgoing_message.lua")

local Startup = setmetatable({}, { __index = OutgoingMessage })
Startup.__index = Startup

function Startup:_get_command()
    return "startup"
end

return Startup