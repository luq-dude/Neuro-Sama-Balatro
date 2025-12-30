local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local PlayBlind = NEURO.MOD_CACHE.load("custom-actions/play_blind.lua")
local ActionWindow = NEURO.MOD_CACHE.load("game-sdk/actions/action_window.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

local RerollBlind = setmetatable({}, { __index = NeuroAction })
RerollBlind.__index = RerollBlind

function RerollBlind:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function RerollBlind:_get_name()
    return "reroll_blind"
end

function RerollBlind:_get_description()
    return "Reroll the current boss blind"
end

function RerollBlind:_get_schema()
    return JsonUtils.wrap_schema({})
end

function RerollBlind:_validate_action()
    return ExecutionResult.success("Rerolling the " .. G.GAME.blind_on_deck .. " Blind.")
end

function RerollBlind:_execute_action(state)
    local e = {
        UIBox = G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]
    }
    G.FUNCS.reroll_boss(e)
    NEURO.DEC_STATE()
    return true
end

return RerollBlind
