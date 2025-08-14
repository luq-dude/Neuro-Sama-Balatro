local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local JokerInteraction = setmetatable({}, { __index = NeuroAction })
JokerInteraction.__index = JokerInteraction

function JokerInteraction:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    obj.actions = state[2]
    obj.consumable = state[3]
    return obj
end

function JokerInteraction:_get_name()
    return "interact_with_joker"
end

function JokerInteraction:_get_description()
    local description = "This allows you to either re-order your jokers, or sell any number of them. " ..
        "When selling, mention the index for every joker you want to sell. " ..
        "When re-ordering, specify where you want each joker to be based off their index. " ..
        "For example, [3,1,2] means put joker 3 first, joker 1 second, then joker 2 third. " ..
        "You have to specify all jokers in your hand."

    return description
end

local function joker_action_options()
    return { "Move", "Sell" }
end

function JokerInteraction:_get_schema()
    local hand_length = RunHelper:get_hand_length(G.jokers.cards)

    return JsonUtils.wrap_schema({
        joker_action = {
            enum = joker_action_options()
        },
        jokers_index = {
            type = "array",
            items = {
                type = "integer",
                enum = hand_length
            }
        }
    })
end

function JokerInteraction:_validate_action(data, state)
    local selected_action = data:get_string("joker_action")
    local selected_hand_index = data:get_object("jokers_index")
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

    if #selected_hand_index == 0 then return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter(
        "selected_hand_index")) end
    if selected_action == "Move" then
        if #G.jokers.cards == 1 then return ExecutionResult.failure(
            "You only have 1 joker, so re-ordering won't do anything.") end
        if #selected_hand_index ~= #G.jokers.cards then return ExecutionResult.failure(
            "You have to specify the positions for every joker in your hand.") end
    end
    if #selected_hand_index > #G.jokers.cards then return ExecutionResult.failure(
        "You have selected more cards then are in your hand.") end

    state["cards_index"] = selected_hand_index
    state["card_action"] = selected_action
    if selected_action == "Move" then
        return ExecutionResult.success("Re-ordered your jokers.")
    end
    return ExecutionResult.success("Selling the selected jokers.")
end

function JokerInteraction:_execute_action(state)
    local selected_hand_index = state["cards_index"]
    local selected_action = state["card_action"]

    RunHelper:reorder_card_area(G.jokers, selected_hand_index)
    if selected_action == "Sell" then
        for i = 1, #selected_hand_index do
            local event_delay = 0
            if G.SPEEDFACTOR > 1 then
                event_delay = i * G.SPEEDFACTOR
            else
                event_delay = i * 2 + G.SPEEDFACTOR + 1
            end
            if i == 1 then
                event_delay = 0.75 * G.SPEEDFACTOR
            end
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = event_delay,
                blocking = false,
                func = function()
                    G.jokers:add_to_highlighted(G.jokers.cards[1])
                    button = G.jokers.cards[1].children.use_button.UIRoot.children[1].children[1].children[1].children[1]
                    button:click()
                    return true
                end
            }))
        end
    end

    local event_delay = 0
    if selected_action == "Sell" then
        event_delay = #selected_hand_index * G.SPEEDFACTOR + 3
    else
        event_delay = 0.5
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = event_delay, -- we mutiply by length selected_hand_index for if Neuro sells mutiple cards.
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            for index, action in ipairs(self.actions) do
                window:add_action(action:new(window, { self.hook }))
            end
            if #G.jokers.cards > 0 then
                window:add_action(JokerInteraction:new(window, { self.hook, self.actions, self.consumable }))
            end

            if #G.consumeables.cards > 0 then
                window:add_action(self.consumable:new(window, { self.hook, self.actions, JokerInteraction }))
            end
            local cards = {}
            for index, value in ipairs(G.jokers.cards) do
                table.insert(cards, "\n" .. tostring(index) .. ": " .. value.config.center.name)
            end
            local query, state = RunHelper:get_query_string()
            window:set_force(0.0, query, state, true)
            window:register()
            return true
        end
    }))
    return true
end

return JokerInteraction
