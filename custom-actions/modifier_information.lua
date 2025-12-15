local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local ModifierInformation = setmetatable({}, { __index = NeuroAction })
ModifierInformation.__index = ModifierInformation

function ModifierInformation:new(actionWindow)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function ModifierInformation:_get_name()
    return "card_modifiers_information"
end

function ModifierInformation:_get_description()
    return "Get the description of all of the card modifiers, if you are ever not sure about a card modifier you should call this."
end

function ModifierInformation:_get_schema()
    return JsonUtils.wrap_schema({})
end

function ModifierInformation:_validate_action(data, state)
    return ExecutionResult.success()
end

function ModifierInformation:_execute_action(state)
    Context.send(RunContext.get_all_modifier_desc(), true)
    NEURO.DEC_STATE()
end

return ModifierInformation
