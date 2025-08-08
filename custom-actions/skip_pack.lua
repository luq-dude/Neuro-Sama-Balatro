local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")

local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")

SkipPack = setmetatable({}, { __index = NeuroAction })
SkipPack.__index = SkipPack

function SkipPack:new(actionWindow, actions)
    local obj = NeuroAction.new(self, actionWindow)
	obj.actions = actions
	obj.hook = actions[1]
    return obj
end

function SkipPack:_get_name()
    return "skip_pack"
end

function SkipPack:_get_description()
    local description = "Close the pack early and take no additional cards from it."

    return description
end

function SkipPack:_get_schema()
end

function SkipPack:_validate_action(data, state)
	return ExecutionResult.success("Skipping this " .. SMODS.OPENED_BOOSTER.config.center.name)
end

function SkipPack:_execute_action(state)
	G.FUNCS.skip_booster(G.booster_pack)

    self.hook.HookRan = false
	return true
end

return SkipPack