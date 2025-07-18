local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")

local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")

SkipPack = setmetatable({}, { __index = NeuroAction })
SkipPack.__index = SkipPack

function SkipPack:new(actionWindow, actions)
    local obj = NeuroAction.new(self, actionWindow)
	obj.actions = actions
	obj.hook = actions[3]
    return obj
end

function SkipPack:_get_name()
    return "skip_pack"
end

function SkipPack:_get_description()
    local description = "Skip this pack and take no more cards from it."

    return description
end

function SkipPack:_get_schema()
end

function SkipPack:_validate_action(data, state)
	return ExecutionResult.success() -- I dont think this needs any validation sorry if it does
end

function SkipPack:_execute_action(state)
	G.FUNCS.skip_booster(G.booster_pack)
	if SMODS.OPENED_BOOSTER.config.center.draw_hand then -- remove actions to pick cards from pack
		NeuroActionHandler.unregister_actions({self.actions[2]}) -- this is booster's with hand
	else
		NeuroActionHandler.unregister_actions({self.actions[1]})
	end

    self.hook.HookRan = false
	return true
end

return SkipPack