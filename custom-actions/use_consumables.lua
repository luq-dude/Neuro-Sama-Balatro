local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local UseConsumable = setmetatable({}, { __index = NeuroAction })
UseConsumable.__index = UseConsumable

function UseConsumable:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    obj.actions = state[2]
    obj.joker = state[3]
    return obj
end

function UseConsumable:_get_name()
    return "use_consumeable"
end

function UseConsumable:_get_description()
    local description = string.format(
        "Use or sell a consumable in your consumable hand. This will either be planet, spectral or tarot cards." ..
        " Each card has a unqiue effect that will alter your run and help you build your deck." ..
        " Some consumeables need to be used on cards in hand." ..
        " Specify the consumable to use with consumable_index and use cards_index to specify what cards in hand to use it on.")

    return description
end

local function get_card_actions()
    return { "Use", "Sell" }
end

function UseConsumable:_get_schema()
    local hand_length = RunHelper:get_hand_length(G.hand.cards)
    local pack_hand_length = RunHelper:get_hand_length(G.consumeables.cards)

    local schema = {
        card_action = {
            enum = get_card_actions()
        },
        consumable_index = {
            enum = pack_hand_length
        }
    }

    if #hand_length ~= 0 then     -- else will not work in shops
        schema["cards_index"] = { -- when adding context messages, make sure neuro knows to send an empty array if she wants to highlight no cards
            type = "array",
            items = {
                type = "integer",
                enum = hand_length
            }
        }
    end
    return JsonUtils.wrap_schema(schema)
end

function UseConsumable:_validate_action(data, state)
    local selected_action = data:get_string("card_action")
    local selected_consumable = data._data["consumable_index"]
    local selected_hand_index = data:get_object("cards_index")
    selected_hand_index = selected_hand_index._data

    local indexs = RunHelper:get_hand_length(G.consumeables.cards)
    if not table.any(indexs, function(options) -- check Neuro doesn't send a invalid index
            return options == selected_consumable
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("consumable_index"))
    end

    local card = G.consumeables.cards[tonumber(selected_consumable)]
    local card_config = card.config.center.config

    if not selected_consumable then
        return ExecutionResult.failure("issue with selected_consumable")
    end

    if not selected_action then
        return ExecutionResult.failure("issue with selected_consumable")
    end

    local option = get_card_actions()
    if not table.any(option, function(options)
            return options == selected_action
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("card_action"))
    end

    local valid_hand_indices = RunHelper:get_hand_length(G.hand.cards)
    for _, value in ipairs(selected_hand_index) do
        if not RunHelper:value_in_table(valid_hand_indices, value) then
            return ExecutionResult.failure("Selected card index " .. tostring(value) .. " is not valid.")
        end
    end

    if RunHelper:check_for_duplicates(selected_hand_index) == false then
        return ExecutionResult.failure("You cannot select the same card index more than once.")
    end

    if #selected_hand_index > G.hand.config.highlighted_limit then
        return ExecutionResult.failure(
            "You can only highlight a max of " .. G.hand.config.highlighted_limit .. "card per action.")
    end

    if #selected_hand_index > 0 and selected_action == "Sell" then
        return ExecutionResult.failure("You cannot select cards when trying to sell a card")
    end

    state["card_action"] = selected_action
    state["consumable_index"] = selected_consumable
    state["cards_index"] = selected_hand_index

    local success, result_string = RunHelper:get_consumable_validation(card,selected_hand_index,selected_action,true)
    if success then
        return ExecutionResult.success(result_string)
    elseif success == false then
        return ExecutionResult.failure(result_string)
    end

    if G.STATE == G.STATES.SHOP and card_config.max_highlighted ~= nil then
        return ExecutionResult.failure(
            "You cannot use this card in the shop as selecting cards is needed for it to work.")
    end

    if #selected_hand_index > 0 and card_config.max_highlighted == nil then
        return ExecutionResult.failure(
            "The card you selected does not require cards to be highlighted")
    end

    if card_config.max_highlighted ~= nil then
        if #selected_hand_index ~= card_config.max_highlighted and selected_action == "Use" then
            return ExecutionResult.failure(
                    "You have either selected too many cards or to little from your hand comparative to how many the tarot needs.")
        end
    end

    if table.any(G.hand.cards,function (force_card)
            return force_card.ability.forced_selection
    end) == true and selected_action == "Use" and card_config.max_highlighted ~= nil then
        local index = -1
        for _, card_index in ipairs(selected_hand_index) do
            if G.hand.cards[card_index].ability.forced_selection then
                index = card_index
            end
        end

        if index == -1 then
            return ExecutionResult.failure("You must select the force selected card.")
        end
    end

    if selected_action == "Use" then
        return ExecutionResult.success("Using " .. card.config.center.name)
    end
    return ExecutionResult.success("Selling the " .. card.config.center.name .. " for " .. card.sell_cost)
end

function UseConsumable:_execute_action(state)
    local selected_index = state["cards_index"]
    local selected_consumable = state["consumable_index"]
    local selected_action = state["card_action"]

    local consumable_hand = G.consumeables.cards
    local card = consumable_hand[selected_consumable]

    local start_state = G.STATE

    G.consumeables:add_to_highlighted(card)

    if selected_action == "Use" then
        if #selected_index > 0 then
            RunHelper:reorder_card_area(G.hand, selected_index)
        end

        for i = 1, #selected_index do
            if not G.hand.cards[i].ability.forced_selection then
                G.hand:add_to_highlighted(G.hand.cards[i])
            end
        end
    end

    local button = nil
    for _, children in ipairs(card.children.use_button.UIRoot.children[1].children) do
        local button_label = children.children[1].children[1].config.button
        if (selected_action == "Sell" and button_label == "sell_card")
            or (selected_action == "Use" and (button_label == "use_card" or button_label == nil)) then
            button = children.children[1].children[1]
            break
        end
    end

    if button == nil then
        sendErrorMessage("Can't find the sell or use button")
        self.hook.HookRan = false
        return true
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.25 * G.SPEEDFACTOR, -- else tarot's that need a card to be selected wont work. The delay does not need to be this high but lower can look a bit jank
        blocking = false,
        func = function()
            button:click()
            return true
        end
    }))

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 1 * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            G.FUNCS.sort_hand_value({})
            local window = ActionWindow:new()
            for _, action in ipairs(self.actions) do
                window:add_action(action:new(window, { self.hook }))
            end

            if #G.jokers.cards > 0 then
                window:add_action(self.joker:new(window, { self.hook, self.actions, UseConsumable }))
            end

            if #G.consumeables.cards > 0 then
                window:add_action(UseConsumable:new(window, { self.hook, self.actions, self.joker }))
            end
            local query,state = RunHelper:get_query_string(start_state)
            window:set_force(0.0, query, state, true)
            window:register()
            return true
        end
    }))

    return true
end

return UseConsumable
