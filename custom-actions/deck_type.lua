local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")
local DeckInfo = setmetatable({}, { __index = NeuroAction })
DeckInfo.__index = DeckInfo

function DeckInfo:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
	obj.hook = state[1]
    return obj
end

function DeckInfo:_get_name()
    return "deck_info"
end

function DeckInfo:_get_description()
    return "Get information about your deck, you can use this to plan your next moves."
end

local function schema_options()
	return {"suits","ranks"}
end

function DeckInfo:_get_schema()
    return JsonUtils.wrap_schema({
		information_action = {
            enum = schema_options()
        },
	})
end

function DeckInfo:_validate_action(data, state)
	local action = data:get_string("information_action")

	local option = schema_options()
    if not table.any(option, function(options)
            return options == action
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("information_action"))
    end

	if #G.deck.cards < 1 then
		return ExecutionResult.failure("The deck is empty.")
	end

	state["action"] = action
    return ExecutionResult.success()
end

function DeckInfo:_execute_action(state)
	local action = state["action"]
	local card_table = {}
	local context_string = ""
	local base_key = ""
	if action == "suits" then
		base_key = "suit"
		context_string = "These are the suits of the cards in your deck and the amount of them: \n"
	elseif action == "ranks" then
		base_key = "value"
		context_string = "These are the ranks of the cards in your deck and the amount of each: \n"
	end

	for index, card in ipairs(G.deck.cards) do
		local info = card.base[base_key]
		sendDebugMessage(tostring(info) .. tprint(card.base,1,2))
		if not card_table[info] then
			card_table[info] = 1
		else
			card_table[info] = card_table[info] + 1
		end
	end

	local type_strings = {}
	for type, value in pairs(card_table) do
		sendDebugMessage("type: " .. type .. "   value: " .. tostring(value))
		type_strings[#type_strings+1] = type .. ": " .. "amount: " ..tostring(value)
	end
	table.sort(type_strings)
	Context.send(context_string .. table.concat(type_strings,"\n"))

	self.hook:play_card(0,false)
end

return DeckInfo
