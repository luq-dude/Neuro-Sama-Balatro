local Context = ModCache.load("game-sdk/messages/outgoing/Context.lua")
local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PlayCards = setmetatable({}, { __index = NeuroAction })
PlayCards.__index = PlayCards

loc_args = {}

function PlayCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function PlayCards:_get_name()
    return "play_cards"
end

function PlayCards:_get_description()
    local description = string.format("play a maximum of 5 cards with your current hand." ..
    "The cards will be ordered by the position they are located in your hand from left to right." ..
    "When defining the card's index the first card will be 1, you should send these in the same order as you send the cards")

    return description
end

local function get_cards_modifiers()
    local enhancements, editions, seals = GetRunText:get_current_hand_modifiers(G.hand.cards)

    Context.send(string.format("These are what the card's modifiers do," ..
    " there can only be one edition,enhancement and seal on each card: \n" ..
    enhancements .. "\n" ..
    editions .. "\n" ..
    seals),true)

    Context.send("These are the current cards in your hand and their modifiers: \n" .. table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards)),true)

    return GetRunText:get_hand_names(G.hand.cards)
end

function PlayCards:_get_schema()
    local hand_names = GetRunText:get_hand_names(G.hand.cards) -- get length of hand
    local hand_length = {}
    for i = 1, #hand_names do
        table.insert(hand_length, i)
    end

    return JsonUtils.wrap_schema({
        hand = {
			type = "array",
            items = {
				type = "string",
				enum = get_cards_modifiers()
			},
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
    local selected_index = data:get_object("cards_index")
    selected_hand = selected_hand._data
    selected_index = selected_index._data

    if not selected_hand then
        return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("hand"))
    end

    if #selected_hand == 0 then return ExecutionResult.failure("At least one card must be selected.") end

    if #selected_hand > 5 then return ExecutionResult.failure("Cannot play more than 5 cards.") end

    if #selected_index ~= #selected_hand then return ExecutionResult.failure("You have either given more card indexs or more selected cards.") end

	local hand = get_cards_modifiers()
    local selected_amount = {}
    local hand_amount = {}

    for pos, card in ipairs(selected_hand) do
        for ipos, index in ipairs(selected_index) do
            sendDebugMessage("card: " .. card .. " index: " .. index .. " card in hand at index: " .. hand[index])
            if hand[index] ~= card and pos == ipos then
                return ExecutionResult.failure("the card: " .. card .. " is not at the index " .. index .. " in the hand")
            else
                goto continue
            end
        end
        ::continue::
    end

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

    state["cards_index"] = selected_index
    state["hand"] = selected_hand
    return ExecutionResult.success()
end

-- id play card button: "play_button"
function PlayCards:_execute_action(state)
    local selected_hand = state["hand"]
    local selected_index = state["cards_index"]

    -- local play_button = G.buttons:get_UIE_by_ID('play_button') -- not used
    local hand_string = get_cards_modifiers()
    local hand = G.hand.cards
    local selected_amount = increment_card_table(selected_hand)

    local highlighted_cards = {}

    for _, card in pairs(selected_hand) do
        local card_id = card
        for _, index in ipairs(selected_index) do
            if hand_string[index] == card and (highlighted_cards[card_id] or 0) < selected_amount[card] then
                sendDebugMessage("hand card: " .. hand_string[index] .. " card: " .. card)
                G.hand:add_to_highlighted(hand[index])
                highlighted_cards[card_id] = (highlighted_cards[card_id] or 0) + 1
                goto continue
            end
        end
        ::continue::
    end

    -- shouldn't cause any issues with mods
    G.FUNCS.play_cards_from_highlighted()

    self.hook.HookRan = false
    -- couldn't get this to work and I hate ui so function call is good enough for now
    -- play_button:click() -- Maybe try to make this an event to see if it would work
    -- G.buttons:get_UIE_by_ID('play_button'):release()

	return true
end


return PlayCards