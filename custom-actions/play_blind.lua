local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PlayBlind = setmetatable({}, { __index = NeuroAction })
PlayBlind.__index = PlayBlind

function PlayBlind:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function PlayBlind:_get_name()
    return "play_blind"
end

function PlayBlind:_get_description()
    return "Start the selected blind."
end

function PlayBlind:_get_schema()
    return JsonUtils.wrap_schema({},false)
end

function PlayBlind:_validate_action()
    return ExecutionResult.success("Opening the " .. G.GAME.blind_on_deck .. " Blind.")
end

function PlayBlind:_execute_action(state)
    local e = {
        config = { ref_table = G.P_BLINDS[G.GAME.round_resets.blind_choices[G.GAME.blind_on_deck]] },
        UIBox = G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]
    }
    G.FUNCS.select_blind(e)
end

return PlayBlind