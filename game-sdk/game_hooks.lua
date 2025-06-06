-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local WebsocketConnection = ModCache.load("game-sdk/websocket/websocket_connection.lua")
local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")

local Action = ModCache.load("game-sdk/messages/incoming/action.lua")

local GameHooks = {}

ActionWindowsList = {}

local WebsocketConnectionInstance = WebsocketConnection
local NeuroActionHandlerInstance = nil

-- need to call this method in your 'game loop'/'update' method (e.g love.update)
GameHooks.update = function(delta)
    for _, ActionWindow in ipairs(ActionWindowsList)
    do
        if ActionWindow ~= nil then
            ActionWindow:update(delta)
        end
    end
    if WebsocketConnectionInstance ~= nil then
        WebsocketConnectionInstance:update(delta)
    end
end

-- need to call this method in your initialization code (e.g love.load)
GameHooks.load = function()
    print("load called")
    WebsocketConnectionInstance:load()
    NeuroActionHandlerInstance = NeuroActionHandler.getInstance()

    WebsocketConnectionInstance._command_handler:register(Action)
end

GameHooks.quit = function()
    print("quit called")
    NeuroActionHandler:quit()
end


return GameHooks
