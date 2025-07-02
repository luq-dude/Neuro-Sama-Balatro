local Context = ModCache.load("game-sdk/messages/outgoing/Context.lua")
local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PlayCards = setmetatable({}, { __index = NeuroAction })
PlayCards.__index = PlayCards

function PlayCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function PlayCards:_get_name()
    return "play_cards"
end

function PlayCards:_get_description()
    local description = "play a maximum of 5 cards with your current hand. The cards will be ordered by the position they are located in your hand from left to right"

    return description
end

local function get_cards_modifiers()
    Context.send("This is the information on your cards current modifiers " .. table:table_to_string(GetRunText:get_current_hand_modifiers(G.hand.cards)))

    return GetRunText:get_hand_names(G.hand.cards)
end

function PlayCards:_get_schema()
    return JsonUtils.wrap_schema({
        hand = {
			type = "array",
            items = {
				type = "string",
				enum = get_cards_modifiers()
			},
		}
    })
end

local function increment_card_table(table)
    local selected_table = {}
    for _, card in pairs(table) do
        if selected_table[card] == nil then
            selected_table[card] = 1
        else
            selected_table[card] = selected_table[card] + 1 -- should increment for each type of card in hand
        end
    end
    return selected_table
end

function PlayCards:_validate_action(data, state)
    local selected_hand = data:get_object("hand")
    selected_hand = selected_hand._data

    if not selected_hand then
        return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("hand"))
    end

    if #selected_hand == 0 then return ExecutionResult.failure("At least one card must be selected.") end

    if #selected_hand > 5 then return ExecutionResult.failure("Cannot play more than 5 cards.") end

	local hand = get_cards_modifiers()
    local selected_amount = {}
    local hand_amount = {}

    -- check if card exist
	for _, selected_card in pairs(selected_hand) do
        if not table.any(hand, function(hand_card)
                return hand_card == selected_card
            end) then
            return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter(selected_card .. " is not in your hand."))
        end
    end

    -- add one for each card that is in the hand
    hand_amount = increment_card_table(hand)

    -- add one for each card that is in the selected hand
    selected_amount = increment_card_table(selected_hand)

    -- get if trying to play more cards than in hand
    for _, card in pairs(selected_hand) do
        if selected_amount[card] > hand_amount[card] then
            return ExecutionResult.failure("You can only use the cards given in the hand. You tried to play more " .. card .. "'s when those do not exist")
        else
            sendDebugMessage("lowering " .. card .. "by 1")
            selected_amount[card] = selected_amount[card] - 1
        end
    end

    state["hand"] = selected_hand
    return ExecutionResult.success()
end

-- id play card button: "play_button"
function PlayCards:_execute_action(state)
    local selected_hand = state["hand"]

    -- local play_button = G.buttons:get_UIE_by_ID('play_button') -- not used
    local hand_string = get_cards_modifiers()
    local hand = G.hand.cards
    local selected_amount = increment_card_table(selected_hand)

    local highlighted_cards = {}

    for _, card in pairs(selected_hand) do
        local card_id = card
        for index = 1, #hand_string, 1  do
            if card == hand_string[index] and (highlighted_cards[card_id] or 0) < selected_amount[card] then
                G.hand:add_to_highlighted(hand[index])
                highlighted_cards[card_id] = (highlighted_cards[card_id] or 0) + 1
            end
        end
    end

    -- shouldn't cause any issues with mods
    G.FUNCS.play_cards_from_highlighted()

    -- couldn't get this to work and I hate ui so function call is good enough for now
    -- play_button:click() -- Maybe try to make this an event to see if it would work
    -- G.buttons:get_UIE_by_ID('play_button'):release()

	return true
end


return PlayCards