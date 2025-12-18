local NeuroAction = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = NEURO.MOD_CACHE.load("game-sdk/websocket/execution_result.lua")
local RunHelper = NEURO.MOD_CACHE.load("run_functions_helper.lua")

local JsonUtils = NEURO.MOD_CACHE.load("game-sdk/utils/json_utils.lua")

local PickHandPackCards = setmetatable({}, { __index = NeuroAction })
PickHandPackCards.__index = PickHandPackCards


function PickHandPackCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function PickHandPackCards:_get_name()
    return "pick_pack_cards"
end

function PickHandPackCards:_get_description()
    local description = string.format("Pick a consumable to use from this pack, you can pick a max of " ..
        SMODS.OPENED_BOOSTER.config.center.config.choose
        .. " consumables "
        .. "out of the " ..
        SMODS.OPENED_BOOSTER.config.center.config.extra ..
        " available. Some consumables require you to select cards in hand to use. " .. 
        "Use pack_card_index to specify what consumable you are using and hand_cards_index to specify what cards it is being used on. " ..
        "When defining the card's index the first card will be 1.")

    return description
end

function PickHandPackCards:_get_schema()
    local hand_length = RunHelper:get_hand_length(G.hand.cards)
    local pack_hand_length = RunHelper:get_hand_length(G.pack_cards.cards)

    return JsonUtils.wrap_schema({
        hand_cards_index = {
            type = "array",
            items = {
                type = "integer",
                enum = hand_length
            }
        },
        pack_card_index = { -- this is the tarot or spectral card
            enum = pack_hand_length
        }
    })
end

function PickHandPackCards:_validate_action(data, state)
    local selected_hand_index = data:get_object("hand_cards_index")
    local selected_pack_card = data._data["pack_card_index"]
    selected_hand_index = selected_hand_index._data

    local card = G.pack_cards.cards[selected_pack_card]
    local card_config = card.config.center.config

    if RunHelper:check_for_duplicates(selected_hand_index) == false then
        return ExecutionResult.failure("You cannot select the same card index more than once.")
    end

    local valid_hand_indices = RunHelper:get_hand_length(G.hand.cards)
    if not table.any(valid_hand_indices, function(options)
            return options == selected_pack_card
        end) then
        return ExecutionResult.failure(NEURO.SDK_STRINGS.action_failed_invalid_parameter("pack_card_index"))
    end

    if #selected_hand_index > G.hand.config.highlighted_limit then
        return ExecutionResult.failure(
            "You have selected more cards from your hand then you are allowed too.")
    end
    state["cards_index"] = selected_hand_index
    state["pack_card_index"] = selected_pack_card
    local success, ret_string = RunHelper.validate_consumable(card, selected_hand_index, "Use")
    if success then
        return ExecutionResult.success(ret_string)
    end
    return ExecutionResult.failure(ret_string)
end

function PickHandPackCards:_execute_action(state)
    local selected_index = state["cards_index"]
    local selected_pack_card = state["pack_card_index"]

    local pack_cards_hand = G.pack_cards.cards
    local consumable = pack_cards_hand[selected_pack_card]

    G.pack_cards:add_to_highlighted(consumable)

    -- only select cards in hand if they are required
    if consumable.config.center.config.max_highlighted ~= nil or consumable.config.center_key == "c_aura" then
        if #selected_index > 0 then
            RunHelper:reorder_card_area(G.hand, selected_index)
        end

        for i = 1, #selected_index do
            G.hand:add_to_highlighted(G.hand.cards[i])
        end
    end

    -- not sure why but we now need a brief delay here after selecting the card in order to find the button
    -- we didnt before so /shrug
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.25 * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            local button = nil
            for _, v in ipairs(consumable.children.use_button.UIRoot.children) do
                if v.config.button ~= nil then
                    button = v
                    break
                end
            end

            if button == nil then
                sendErrorMessage("Can't find the use button")
                return true
            end

            button:click()
            return true
        end
    }))

    if NEURO.DESELECT_AFTER_USE[consumable.config.center_key] then
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


    local can_pick_another = (G.GAME.pack_choices or 1) > 1
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 5 * G.SPEEDFACTOR,
        blocking = false,
        func = function ()
            if can_pick_another then
                NEURO.DEC_STATE()
            else
                NEURO.INC_STATE()
            end
            return true
        end
    }))

    return true
end

return PickHandPackCards
