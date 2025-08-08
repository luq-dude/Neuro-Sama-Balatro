local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local PlayBlind = ModCache.load("custom-actions/play_blind.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")
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
    return JsonUtils.wrap_schema({},false)
end

function SkipBlind:_validate_action()
    return ExecutionResult.success("Skipping the " .. G.GAME.blind_on_deck .. " Blind.")
end

function SkipBlind:_execute_action(state)
    local e = {
        UIBox = G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]
    }
    G.FUNCS.skip_blind(e)

    -- some tags open up another screen, like the ones that immediately open a free pack
    -- for those we have to wait until the screen closes before asking her about the next blind
    -- for others we can just immediately ask
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 2,
        blocking = false,
        func = function()
            -- after a brief delay check if were on the blind select screen or not
            -- if we are on the screen, then immediately ask again
            -- if were not, wait the delay before trying again
            if G.STATE ~= G.STATES.BLIND_SELECT then return false end
            local window = ActionWindow:new()
            window:set_force(0.0, "", "Choose to select or skip the currently selected blind")
            window:add_action(PlayBlind:new(window))
            if G.GAME.blind_on_deck ~= "Boss" then
                window:add_action(SkipBlind:new(window))
            end
            window:register()
            return true
        end
    }))
end

return SkipBlind
