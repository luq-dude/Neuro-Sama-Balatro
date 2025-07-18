local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local JokerInteraction = setmetatable({}, { __index = NeuroAction })
JokerInteraction.__index = JokerInteraction

function JokerInteraction:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function JokerInteraction:_get_name()
    return "interact_with_joker"
end

function JokerInteraction:_get_description()
    local description = "This allows you to either move your jokers in a different order to try and increase the score they give you." ..
    "Or to sell your jokers. You can only move two jokers at a time, however you can sell a variable amount of jokers from either 1 or your whole hand"


    return description
end

local function joker_action_options()
	return {"Move","Sell"}
end

function JokerInteraction:_get_schema()
	local hand_length = RunHelper:get_hand_length(G.jokers.cards)

    return JsonUtils.wrap_schema({
        card_action = {
            enum = joker_action_options()
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

function JokerInteraction:_validate_action(data, state)
    local selected_action = data:get_string("card_action")
    local selected_hand_index = data:get_object("cards_index")
    selected_hand_index = selected_hand_index._data

    if RunHelper:check_for_duplicates(selected_hand_index) == false then
        return ExecutionResult.failure("You cannot select the same card index more than once.")
    end

    local valid_hand_indices = RunHelper:get_hand_length(G.jokers.cards)
    for _, value in ipairs(selected_hand_index) do
        if not RunHelper:value_in_table(valid_hand_indices, value) then
            return ExecutionResult.failure("Selected card index " .. tostring(value) .. " is not valid.")
        end
    end

    local option = joker_action_options()
    if not table.any(option, function(options)
            return options == selected_action
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("card_action"))
    end

    if #selected_hand_index == 0 then return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("selected_hand_index")) end

    if selected_action == "Move" then
        if #selected_hand_index < 2 then return ExecutionResult.failure("You have not selected enough cards to move, you should only select two cards.") end

        if #selected_hand_index > 2 then return ExecutionResult.failure("You have selected more cards from your hand then you are allowed when you are moving cards.") end

        if not G.jokers.cards[selected_hand_index[1]].states.drag.can then
            return ExecutionResult.failure("You can not drag the card in the " .. selected_hand_index[1] .. " position.")
        end

        if not G.jokers.cards[selected_hand_index[2]].states.drag.can then
            return ExecutionResult.failure("You can not drag the card in the " .. selected_hand_index[2] .. " position.")
        end
    else
        if #selected_hand_index > #G.jokers.cards then return ExecutionResult.failure("You have selected more cards then are in your hand.") end
    end

    state["cards_index"] = selected_hand_index
    state["card_action"] = selected_action
    return ExecutionResult.success()
end

function JokerInteraction:_execute_action(state)
    local selected_hand_index = state["cards_index"]
    local selected_action = state["card_action"]

    local hand = G.jokers.cards
    local register_delay = 2
    if selected_action == "Move" then
        G.jokers.cards[selected_hand_index[1]].states.drag.is = true
        if selected_hand_index[1] > selected_hand_index[2] then-- The game interpolates between T and the shown position itself
            G.jokers.cards[selected_hand_index[1]].T.x = hand[selected_hand_index[2]].T.x - 0.1
        else
            G.jokers.cards[selected_hand_index[1]].T.x = hand[selected_hand_index[2]].T.x + 0.1
        end
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 2,
            blocking = false,
            func = function ()
                G.jokers.cards[selected_hand_index[2]].states.drag.is = false
                return true
            end
            }))
    else
        G.jokers:add_to_highlighted(hand[selected_hand_index[1]])
        local use_button_child = hand[selected_hand_index[1]].children.use_button.UIRoot.children[1].children[1].children[1].children[1]
        local button = nil
        button = use_button_child
        button:click()
        table.remove(selected_hand_index,1)
        for pos, index in ipairs(selected_hand_index) do -- we do this incase neuro adds multiple jokers to be sold
            sendDebugMessage("pos: " .. tostring(pos) .. "  index: " .. tostring(index))
            hand = G.jokers.cards
            local event_delay = 0
            if G.SPEEDFACTOR > 1 then -- as delay is reliant on game speed and I don't want to cause issues with long waits with lower delays
                event_delay = pos * 5 + G.SPEEDFACTOR * 5 -- this makes the first run take a while but it should be fine
                register_delay = register_delay + event_delay + G.SPEEDFACTOR
            else
                event_delay = pos * 2 + G.SPEEDFACTOR + 1
                register_delay = register_delay + event_delay + G.SPEEDFACTOR
            end
            G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = event_delay,
            blocking = false,
            func = function ()
                local event_hand = hand
                G.jokers:add_to_highlighted(hand[index - pos])
                button = hand[index - pos].children.use_button.UIRoot.children[1].children[1].children[1].children[1]
                button:click()
                return true
            end
            }))
        end
    end

    self.hook.HookRan = false
    self.hook:register_play_actions(register_delay,self.hook) -- TODO: probably better way to register actions, I can't think of another way that has less downsides then this though.
    return true
end -- should probably send context of where the jokers have been moved as Neuro may get confused with where the card replaced goes.

return JokerInteraction
