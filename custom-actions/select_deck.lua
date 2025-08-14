local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetText = ModCache.load("get_text.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local SelectStake = ModCache.load("custom-actions/select_stake.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local SelectDeck = setmetatable({}, { __index = NeuroAction })
SelectDeck.__index = SelectDeck

local function select_stake()
    local window = ActionWindow:new()
    window:add_action(SelectStake:new(window, nil))
    window:set_force(1.0, "Pick a stake", "Next you need to select a stake. Each of these have their own permanent effects." ..
    " You should pick this wisely", false)
    window:register()
    return true
end

function SelectDeck:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.state = state
    return obj
end

function SelectDeck:_get_name()
    return "select_deck"
end

function SelectDeck:_get_description()
    local description = "Select a deck to start the game with."

    for k, v in pairs(GetText:get_back_descriptions()) do
        description = description .. "\n" .. v
    end

    return description
end

function SelectDeck:_get_schema()
    return JsonUtils.wrap_schema({
        deck = {
            enum = GetText:get_back_names()
        }
    })
end

function SelectDeck:_validate_action(data, state)
    local back = data:get_string("deck")
    if not back then
        return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("deck"))
    end

    local backs = GetText:get_back_names()
    if not table.any(backs, function(possible_back)
            return possible_back == back
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("deck"))
    end
    state["deck"] = back
    return ExecutionResult.success(string.format("The game has started with the %s.", back))
end

function SelectDeck:_execute_action(state)
    local orderedDeckNames = {}
    for k, v in ipairs(G.P_CENTER_POOLS.Back) do
        orderedDeckNames[#orderedDeckNames + 1] = v.name
    end

    local selectedDeckName = state["deck"]

    for id, deck in pairs(GetText:get_back_names(false, true)) do
        if deck == selectedDeckName then
            local args = { to_val = orderedDeckNames[id], to_key = id }
            G.FUNCS.change_viewed_back(args)
        end
    end

    select_stake()
end

return SelectDeck
