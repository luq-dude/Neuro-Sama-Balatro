local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetText = ModCache.load("get_text.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local SelectStake = setmetatable({}, { __index = NeuroAction })
SelectStake.__index = SelectStake

function SelectStake:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function SelectStake:_get_name()
    return "select_deck"
end

function SelectStake:_get_description()
    local description = "Select a stake (dificulty) to start the game with."

    for k, v in pairs(GetText:get_stake_descriptions()) do
        description = description .. "\n" .. k .. ": " .. v
    end

    return description
end

function SelectStake:_get_schema()
    return JsonUtils.wrap_schema({
        stake = {
            enum = GetText:get_stake_names()
        }
    })
end

function SelectStake:_validate_action(data, state)
    local stake = data:get_string("stake")
    if not stake then
        return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("stake"))
    end

    local stakes = GetText:get_stake_names()
    if not table.any(stakes, function(possible_stake)
            return possible_stake == stake
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("stake"))
    end
    state["stake"] = stake
    return ExecutionResult.success()
end

function SelectStake:_execute_action(state)
    local selectedStakeName = state["stake"]
    local orderedStakeNames = {}
    for k, v in ipairs(G.P_CENTER_POOLS.Stake) do
        orderedStakeNames[#orderedStakeNames + 1] = v.name
    end

    for id, stake in pairs(GetText:get_stake_names()) do
        if stake == selectedStakeName then
            local args = { to_val = orderedStakeNames[id], to_key = id }
            G.FUNCS.change_stake(args)
        end
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 5,
        func = function()
            G.FUNCS.start_run()
            -- return false as otherwise crashes
            return false
        end,
    }))
end

return SelectStake