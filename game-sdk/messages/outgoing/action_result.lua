-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local OutgoingMessage = ModCache.load("game-sdk/messages/api/outgoing_message.lua")

local ActionResult = setmetatable({}, { __index = OutgoingMessage })
ActionResult.__index = ActionResult

function ActionResult:new(id, result)
    local obj = OutgoingMessage.new(self)
    obj._id = id
    obj._success = result.successful
    obj._message = result.message
    return obj
end

function ActionResult:_get_command()
    return "action/result"
end

function ActionResult:_get_data()
    return {
        id = self._id,
        success = self._success,
        message = self._message
    }
end

return ActionResult