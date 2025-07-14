local Context = ModCache.load("game-sdk/messages/outgoing/Context.lua")
local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local UseHandCards = setmetatable({}, { __index = NeuroAction })
UseHandCards.__index = UseHandCards

function UseHandCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function UseHandCards:_get_name()
    return "use_hand_cards"
end

function UseHandCards:_get_description()
    local description = string.format("Either play or discard a maximum of ".. G.hand.config.highlighted_limit .. " cards with your current hand." ..
    "The cards will be ordered by the position they are located in your hand from left to right." ..
    "When defining the card's index the first card will be 1, you should send these in the same order as you send the cards")

    return description
end

local function get_cards_context()
    local enhancements, editions, seals = GetRunText:get_current_hand_modifiers(G.hand.cards)

    Context.send(string.format("These are what the card's modifiers do," ..
    " there can only be one edition,enhancement and seal on each card: \n" ..
    enhancements .. "\n" ..
    editions .. "\n" ..
    seals),true)

    Context.send("These are the current cards in your hand and their modifiers: \n" .. table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards)))
end

local function card_action_options()
	return {"Play","Discard"}
end

function UseHandCards:_get_schema()
    get_cards_context()
    local hand_length = RunHelper:get_hand_length(G.hand.cards)

    return JsonUtils.wrap_schema({
		card_action = {
			enum = card_action_options()
		},
        cards_index = {
            type = "array",
            items ={
                type = "integer",
                enum = hand_length
            }
        }
    })
end

function UseHandCards:_validate_action(data, state)
	local selected_action = data:get_string("card_action")
    local selected_index = data:get_object("cards_index")
    selected_index = selected_index._data

	if not selected_index then
		sendDebugMessage("issue in not: " .. tprint(selected_action,1,2))
		return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("card_action"))
	end

    local option = card_action_options()
    if not table.any(option, function(options)
            return options == selected_action
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("card_action"))
    end

    local valid_hand_indices = RunHelper:get_hand_length(G.hand.cards)
    for _, value in ipairs(selected_index) do
        if not RunHelper:value_in_table(valid_hand_indices, value) then
            return ExecutionResult.failure("Selected card index " .. tostring(value) .. " is not valid.")
        end
    end

    if RunHelper:check_for_duplicates(selected_index) == false then
        return ExecutionResult.failure("You cannot select the same card index more than once.")
    end

    if not selected_index then
        return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("cards_index"))
    end

    if #selected_index == 0 then return ExecutionResult.failure("At least one card must be selected.") end

    if #selected_index > G.hand.config.highlighted_limit then return ExecutionResult.failure("Cannot play more than " .. G.hand.config.highlighted_limit .. " cards.") end

    if G.GAME.current_round.discards_left <= 0 and selected_action == "Discard" then return ExecutionResult.failure("You have no discards left.") end

	local hand_length = RunHelper:get_hand_length(G.hand.cards)
    local selected_amount = {}
    local hand_amount = {}

    state["cards_index"] = selected_index
    state["card_action"] = selected_action
    return ExecutionResult.success()
end

function UseHandCards:_execute_action(state)
    local selected_index = state["cards_index"]
	local selected_action = state["card_action"]

    local hand = G.hand.cards
    local selected_amount = RunHelper:increment_card_table(selected_index)

    local highlighted_cards = {}

    for _, index in ipairs(selected_index) do
        local card_id = hand[index]
        G.hand:add_to_highlighted(hand[index])
        highlighted_cards[card_id] = (highlighted_cards[card_id] or 0) + 1
    end

	if selected_action == "Play" then
		G.FUNCS.play_cards_from_highlighted()
    elseif selected_action == "Discard" then
		G.FUNCS.discard_cards_from_highlighted()
    else
        sendErrorMessage("selected_action equals: " .. tostring(selected_action) .. " How did this get past validation?")
	end

    self.hook.HookRan = false
	return true
end


return UseHandCards