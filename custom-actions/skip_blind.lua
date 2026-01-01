local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local SkipBlind = setmetatable({}, { __index = NeuroAction })
SkipBlind.__index = SkipBlind

function SkipBlind:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function SkipBlind:_get_name()
    return "skip_blind"
end

function SkipBlind:_get_description()
    return "Skips the selected blind, gaining a tag as a reward."
end

function SkipBlind:_get_schema()
    return JsonUtils.wrap_schema({})
end

function SkipBlind:_validate_action()
    return ExecutionResult.success("Skipping the " .. G.GAME.blind_on_deck .. " Blind.")
end

function SkipBlind:_execute_action(state)
    local e = {
        UIBox = G.blind_select_opts[string.lower(G.GAME.blind_on_deck)],
        neuro = true
    }
    G.FUNCS.skip_blind(e)
    NEURO.INC_STATE()
end

return SkipBlind
