local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")

local NeuroActionHandler = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action_handler.lua")

SkipPack = setmetatable({}, { __index = NeuroAction })
SkipPack.__index = SkipPack

function SkipPack:new(actionWindow)
    local obj = NeuroAction.new(self, actionWindow)
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
    return JsonUtils.wrap_schema({})
end

function SkipPack:_validate_action(data, state)
    local name = SMODS.OPENED_BOOSTER.config.center.name
    if SMODS.OPENED_BOOSTER.config.center.mod and SMODS.OPENED_BOOSTER.config.center.loc_txt then
        name = SMODS.OPENED_BOOSTER.config.center.loc_txt.name
    end
	return ExecutionResult.success("Skipping this " .. name)
end

function SkipPack:_execute_action(state)
	G.FUNCS.skip_booster(G.booster_pack)
    NEURO.INC_STATE()
	return true
end

return SkipPack