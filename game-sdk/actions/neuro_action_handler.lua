-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude in 2025


local WebsocketConnection = ModCache.load("game-sdk/websocket/websocket_connection.lua")
local ActionsRegister = ModCache.load("game-sdk/messages/outgoing/actions_register.lua")
local ActionsUnregister = ModCache.load("game-sdk/messages/outgoing/action_unregister.lua")

local NeuroActionHandler = {}
NeuroActionHandler.__index = NeuroActionHandler

local _instance = nil

function NeuroActionHandler.getInstance()
    if not _instance then
        _instance = {
            _registered_actions = {},
            _dying_actions = {}
        }
        setmetatable(_instance, {__index = NeuroActionHandler})
        print("initalized neuro action handler _instance")
    end
    return _instance
end

function NeuroActionHandler:quit()
    local registered_ws_actions = table.map(self._registered_actions, function(action)
        return action:get_ws_action()
    end)
    WebsocketConnection.send_immediate(ActionsUnregister:new(registered_ws_actions))
end

function NeuroActionHandler.get_action(action_name)
    local actions = {}
    for _, registered_action in ipairs(_instance._registered_actions)
    do
        if registered_action:get_name() == action_name then
            table.insert(actions, registered_action)
        end
    end
    if #actions == 0 then
        return nil
    end

    return actions[1]
end

function NeuroActionHandler.is_recently_unregistered(action_name)
    return table.any(_instance._dying_actions, function(dying_action)
        return dying_action:get_name() == action_name
    end)
end

function NeuroActionHandler.register_actions(actions)
    if not _instance then
        print("now _instance is nil")
    end
    _instance._registered_actions = table.filter(_instance._registered_actions, function(old_action)
        return not table.any(actions, function(new_action)
            return old_action:get_name() == new_action:get_name()
        end)
    end)

    _instance._dying_actions = table.filter(_instance._dying_actions, function(old_action)
        return not table.any(actions, function(new_action)
            return old_action:get_name() == new_action:get_name()
        end)
    end)

    for _, new_action in ipairs(actions)
    do
        table.insert(_instance._registered_actions, new_action)
    end

    local ws_actions = table.map(actions, function(action) return action:get_ws_action() end)
    WebsocketConnection.send(ActionsRegister:new(ws_actions))
end

function NeuroActionHandler.unregister_actions(actions)
    local actions_to_remove = table.filter(_instance._registered_actions, function(old_action)
        return table.any(actions, function(new_action)
            return old_action:get_name() == new_action:get_name()
        end)
    end)
    _instance._registered_actions = table.filter(_instance._registered_actions, function(old_action)
        return not table.any(actions_to_remove, function(action_to_remove)
            return action_to_remove == old_action
        end)
    end)

    local unregister_actions = table.map(actions_to_remove, function(action)
        return action:get_ws_action()
    end)
    WebsocketConnection.send(ActionsUnregister:new(unregister_actions))
    _instance._dying_actions = table.filter(_instance._dying_actions, function(act)
        return table.any(actions_to_remove, function(act_to_remove)
            return act == act_to_remove
        end)
    end)
end

function NeuroActionHandler.resend_registered_actions()
    local actions = table.map(_instance._registered_actions, function(action)
        return action:get_ws_action()
    end)
    if #actions then
        WebsocketConnection.send(ActionsRegister:new(actions))
    end
end

return NeuroActionHandler
