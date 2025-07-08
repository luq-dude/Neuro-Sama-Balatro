local Context = ModCache.load("game-sdk/messages/outgoing/Context.lua")
local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PlayCards = setmetatable({}, { __index = NeuroAction })
PlayCards.__index = PlayCards

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

    Context.send("These are the current cards in your hand and their modifiers: \n" .. table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards)))

    return GetRunText:get_hand_names(G.hand.cards)
end

local function get_hand_length(card_table)
    local hand_names = GetRunText:get_hand_names(card_table) -- get length of hand
    local hand_length = {}
    for i = 1, #hand_names do
        table.insert(hand_length, i)
    end
    return hand_length
end

function PlayCards:_get_schema()
    get_cards_modifiers()
    local hand_length = get_hand_length(G.hand.cards)

    return JsonUtils.wrap_schema({
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
    local selected_index = data:get_object("cards_index")
    selected_index = selected_index._data

    if not selected_index then
        return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("cards_index"))
    end

    if #selected_index == 0 then return ExecutionResult.failure("At least one card must be selected.") end

    if #selected_index > 5 then return ExecutionResult.failure("Cannot play more than 5 cards.") end

	local hand_length = get_hand_length(G.hand.cards)
    local selected_amount = {}
    local hand_amount = {}

    -- add one for each card that is in the hand
    hand_amount = increment_card_table(hand_length)

    -- add one for each card that is in the selected hand
    selected_amount = increment_card_table(selected_index)

    -- get if trying to play more cards than in hand
    for _, card in pairs(selected_index) do
        if selected_amount[card] > hand_amount[card] then
            return ExecutionResult.failure("You can only use the cards given in the hand. You tried to play more " .. card .. "'s when those do not exist")
        else
            sendDebugMessage("lowering " .. card .. "by 1")
            selected_amount[card] = selected_amount[card] - 1
        end
    end

    state["cards_index"] = selected_index
    return ExecutionResult.success()
end

function PlayCards:_execute_action(state)
    local selected_index = state["cards_index"]

    local hand_string = get_cards_modifiers()
    local hand = G.hand.cards
    local selected_amount = increment_card_table(selected_index)

    local highlighted_cards = {}

    for _, index in ipairs(selected_index) do
        local card_id = hand[index]
        G.hand:add_to_highlighted(hand[index])
        highlighted_cards[card_id] = (highlighted_cards[card_id] or 0) + 1
    end

    -- for _, card in pairs(selected_hand) do
    --     local card_id = card
    --     for _, index in ipairs(selected_index) do
    --         if hand_string[index] == card and (highlighted_cards[card_id] or 0) < selected_amount[card] then
    --             sendDebugMessage("hand card: " .. hand_string[index] .. " card: " .. card)
    --             G.hand:add_to_highlighted(hand[index])
    --             highlighted_cards[card_id] = (highlighted_cards[card_id] or 0) + 1
    --             goto continue
    --         end
    --     end
    --     ::continue::
    -- end

    G.FUNCS.play_cards_from_highlighted()

    self.hook.HookRan = false
	return true
end


return PlayCards