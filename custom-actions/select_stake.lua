local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetText = ModCache.load("get_text.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")
require "stake"

local SelectDeck = setmetatable({}, { __index = NeuroAction })
SelectDeck.__index = SelectDeck

function tprint(tbl, indent, max_depth)
    indent = indent or 0
    max_depth = max_depth or 5
    if max_depth < 0 then
        return string.rep(" ", indent) .. "{...}"
    end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2, max_depth - 1) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end


function SelectDeck:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function SelectDeck:_get_name()
    return "select_deck"
end

function SelectDeck:_get_description()
    local description = "Select a stake (dificulty) to start the game with."

    for k, v in pairs(GetText:get_stake_descriptions()) do
        description = description .. "\n" .. k .. ": " .. v
    end

    return description
end

function SelectDeck:_get_schema()
    return JsonUtils.wrap_schema({
        stake = {
            enum = GetText:get_stake_names()
        }
    })
end

function SelectDeck:_validate_action(data, state)
    local stake = data:get_string("stake")
    if not stake then
        return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("stake"))
    end

    local stakes = GetText:get_stake_names()
    if not table.any(stakes, function(free_cell)
            return free_cell == stake
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("stake"))
    end
    state["stake"] = stake
    return ExecutionResult.success()
end

function SelectDeck:_execute_action(state)
    local selectedStakeName = state["stake"]

end

return SelectDeck