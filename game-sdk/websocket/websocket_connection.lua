-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local websocket =  ModCache.load("libs/websocket.lua")

local MessageQueue = ModCache.load("game-sdk/websocket/message_queue.lua")
local CommandHandler = ModCache.load("game-sdk/websocket/command_handler.lua")
local IncomingData = ModCache.load("game-sdk/messages/api/incoming_data.lua")
local Startup = ModCache.load("game-sdk/messages/outgoing/startup.lua")

local json = ModCache.load("libs/json.lua")

local WebsocketConnection = {}
WebsocketConnection.__index = WebsocketConnection

local RECONNECT_DELAY = NeuroConfig.RECONNECT_DELAY or 5
local WS_URL = NeuroConfig.NEURO_SDK_WS_URL

function WebsocketConnection:new()
    local self = setmetatable({}, WebsocketConnection)
    self._client = nil
    self._connected = false
    self._reconnect_timer = 0
    self._message_queue = MessageQueue:new()
    table.insert(self._message_queue._messages, Startup:new())
    self._command_handler = CommandHandler:new()
    self._command_handler.name = "Command Handler"

    --self._command_handler:register_all()
    return self
end

function WebsocketConnection:load()
    self:_connect()
end

function WebsocketConnection:_connect()
    if not WS_URL then
        print("sdk_WS_URL environment variable is not set")
        return
    end

    if not WS_URL:match("^wss?://") then
        WS_URL = "ws://" .. WS_URL
    end

    self._client = websocket.new(WS_URL)
    sendDebugMessage("Connecting to WebSocket: " .. WS_URL, "Neuro Integration")

    local conn = self
    function self._client:onopen()
        sendDebugMessage("Connected to Neuro-Sama", "Neuro Integration")
        conn._connected = true
    end

    function self._client:onclose(code, reason)
        sendDebugMessage(string.format("WebSocket closed (code=%s, reason=%s)", tostring(code), tostring(reason)),
            "Neuro Integration")
        conn._connected = false
        conn._client = nil
    end

    function self._client:onerror(err)
        sendErrorMessage("WebSocket error: " .. tostring(err), "Neuro Integration")
        conn._connected = false
        conn._client = nil
    end

    function self._client:onmessage(msg)
        sendDebugMessage("Received WebSocket message: " .. msg, "Neuro Integration")
        local success, parsed_data = pcall(json.decode, msg)
        if not success then
            sendErrorMessage("Failed to parse WebSocket message: " .. tostring(parsed_data), "Neuro Integration")
        elseif type(parsed_data) ~= "table" then
            sendErrorMessage("WebSocket message is not a table: " .. tostring(parsed_data), "Neuro Integration")
        else
            local message = IncomingData:new(parsed_data)
            local command = message:get_string("command")
            if not command then
                sendErrorMessage("WebSocket message missing command: " .. tostring(parsed_data), "Neuro Integration")
            else
                local data = message:get_object("data", {})
                conn._command_handler:handle(command, data)
            end
        end
    end
end

function WebsocketConnection:update(dt)
    if not self._client then
    end

    if self._client then
        self._client:update()
    end

    if not self._connected then
        self._reconnect_timer = self._reconnect_timer + dt
        if self._reconnect_timer >= RECONNECT_DELAY then
            sendDebugMessage("Attempting to reconnect to WebSocket...", "Neuro Integration")
            if not self._client or self._client.status == STATUS.CLOSED then
                self._reconnect_timer = 0
                self:_connect()
            end
        end
    else
        self:_flush_queue()
    end
end

function WebsocketConnection:_flush_queue()
    while self._message_queue:size() > 0 do
        local msg = self._message_queue:dequeue()
        print('dequeued ' .. json.encode(msg:get_ws_message():get_data()))
        self:_send_internal(msg:get_ws_message())
    end
end

function WebsocketConnection.send(message)
    if WebsocketConnection._instance then
        WebsocketConnection._instance._message_queue:enqueue(message)
    else
        print("WebSocket not initialized")
    end
end

function WebsocketConnection.send_immediate(message)
    if WebsocketConnection._instance and WebsocketConnection._instance._connected then
        WebsocketConnection._instance:_send_internal(message:get_ws_message())
    else
        print("Cannot send immediate message, socket not connected.")
    end
end

function WebsocketConnection:_send_internal(data)
    if self._client and self._connected then
        local json_str = json.encode(data:get_data())
        self._client:send(json_str)
    else
        print("Cannot send message, WebSocket is not connected.")
    end
end

WebsocketConnection._instance = WebsocketConnection:new()
WEBSOCKET = WebsocketConnection._instance -- This is used in restart_crash.toml
return WebsocketConnection._instance
