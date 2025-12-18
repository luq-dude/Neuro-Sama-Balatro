local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local RunHelper = NEURO.MOD_CACHE.load("run_functions_helper.lua")

local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")

local UseConsumable = setmetatable({}, { __index = NeuroAction })
UseConsumable.__index = UseConsumable

function UseConsumable:new(actionWindow)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function UseConsumable:_get_name()
    return "use_consumeable"
end

function UseConsumable:_get_description()
    local description = string.format(
        "Use or sell a consumable in your consumable hand. This will either be planet, spectral or tarot cards." ..
        " Each card has a unique effect that will alter your run and help you build your deck." ..
        " Some consumables need to be used on cards in hand." ..
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
        return ExecutionResult.failure(NEURO.SDK_STRINGS.action_failed_invalid_parameter("consumable_index"))
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
        return ExecutionResult.failure(NEURO.SDK_STRINGS.action_failed_invalid_parameter("card_action"))
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
    local success, ret_string = RunHelper.validate_consumable(card, selected_hand_index, selected_action)
    if success then
        return ExecutionResult.success(ret_string)
    end
    return ExecutionResult.failure(ret_string)
end

function UseConsumable:_execute_action(state)
    local selected_index = state["cards_index"]
    local selected_consumable = state["consumable_index"]
    local selected_action = state["card_action"]

    local consumable_hand = G.consumeables.cards
    local card = consumable_hand[selected_consumable]

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
        return true
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
         -- else tarot's that need a card to be selected wont work
         -- the delay does not need to be this high but lower can look a bit jank
        delay = 0.25 * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            button:click()
            return true
        end
    }))

    if NEURO.CARD_INFO.DESELECT_AFTER_USE[card.config.center_key] then
        -- for some reason, aura and cryptid dont unselect after use
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 1 * G.SPEEDFACTOR,
            blocking = false,
            func = function ()
                G.hand:remove_from_highlighted(G.hand.cards[1])
                return true
            end
        }))
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 2 * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            G.FUNCS.sort_hand_value({})
            NEURO.DEC_STATE()
            return true
        end
    }))

    return true
end

return UseConsumable
