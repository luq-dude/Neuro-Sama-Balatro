local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

local DeckInfo = setmetatable({}, { __index = NeuroAction })
DeckInfo.__index = DeckInfo

function DeckInfo:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function DeckInfo:_get_name()
    return "query_deck"
end

function DeckInfo:_get_description()
    return "Get information about what cards are currently in your deck. If used " ..
			"while in a blind, this will only tell you about cards left in your deck. "
end


function DeckInfo:_get_schema()
    return JsonUtils.wrap_schema({})
end

function DeckInfo:_validate_action(data, state)
	local action = data:get_string("information_action")

	if #G.deck.cards < 1 then
		return ExecutionResult.failure("The deck is empty.")
	end

	state["action"] = action
    return ExecutionResult.success()
end

function DeckInfo:_execute_action(state)
	local action = state["action"]
	local suits = {}
	local ranks = {}
	local summary = {}

	local face_cards = 0
	local numbered_cards = 0
	local aces = 0
	local suits =  {["Spades"]  = 0, ["Hearts"] = 0, ["Clubs"] = 0, ["Diamonds"] = 0}
	local rank_counts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	local rank_map = {2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K', 'A'}
	G.deck:sort()
	for _, v in ipairs(G.deck.cards) do
		local id = v:get_id()
		if id > 1 and id < 11 then
			numbered_cards = numbered_cards + 1
		end
		if id == 14 then
			aces = aces + 1
		end
		if v:is_face() then
			face_cards = face_cards + 1
		end
		if v:is_suit("Spades") then suits["Spades"] = suits["Spades"] + 1 end
		if v:is_suit("Hearts") then suits["Hearts"] = suits["Hearts"] + 1 end
		if v:is_suit("Clubs") then suits["Clubs"] = suits["Clubs"] + 1 end
		if v:is_suit("Diamonds") then suits["Diamonds"] = suits["Diamonds"] + 1 end
		rank_counts[id - 1] = rank_counts[id - 1] + 1
	end
	summary[#summary+1] = string.format("There are %d/%d cards left in the deck. Out of those, " ..
										"%d are face cards, %d are numbered cards and %d are aces.",
										#G.deck.cards,
										G.deck.config.card_limit, 
										face_cards,
										numbered_cards,
										aces)
	summary[#summary+1] = " Here is how many of each suit you have:"
	for k, v in pairs(suits) do
		summary[#summary+1] = string.format("\n- %s: %d", k, v)
	end
	summary[#summary+1] = "\nHere is how many of each rank you have:"
	for i = 13, 1, -1 do
		summary[#summary+1] = string.format("\n- %s: %d", tostring(rank_map[i]), rank_counts[i])
	end
	Context.send(table.concat(summary))

	NEURO.DEC_STATE_IF_MODE("solo")
end

return DeckInfo
