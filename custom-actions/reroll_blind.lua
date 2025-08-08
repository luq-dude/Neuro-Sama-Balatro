local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local PlayBlind = ModCache.load("custom-actions/play_blind.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")
local GetText = ModCache.load("get_text.lua")
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
    return JsonUtils.wrap_schema({},false)
end

function RerollBlind:_validate_action()
    return ExecutionResult.success("Rerolling the " .. G.GAME.blind_on_deck .. " Blind.")
end

function RerollBlind:_execute_action(state)
    local e = {
        UIBox = G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]
    }
    G.FUNCS.reroll_boss(e)

	local window = ActionWindow:new()
	window:set_force(0.0, "Choose to select or reroll the current blind.", GetText:generate_blind_descriptions())
	window:add_action(PlayBlind:new(window))
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.5 * G.SPEEDFACTOR,
        blocking = false,
        func = function()
        if (G.GAME.dollars-G.GAME.bankrupt_at) - 10 >= 0 then
            window:add_action(RerollBlind:new(window))
        end
        window:register()
        return true
    end}))
	return true
end

return RerollBlind