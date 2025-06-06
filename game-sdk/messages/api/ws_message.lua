-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

local WsMessage = {}
WsMessage.__index = WsMessage

function WsMessage:new(_command, _data, _game)
    local obj = setmetatable({
        command = _command,
        data = _data,
        game = _game
    }, self)
    return obj
end

function WsMessage:get_data()
    return {
        command = self.command,
        game = self.game,
        data = self.data
    }
end

return WsMessage
