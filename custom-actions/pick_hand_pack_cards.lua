local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")
local SkipPack = ModCache.load("custom-actions/skip_pack.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")
local RunContext = ModCache.load("run_context.lua")

local PickHandPackCards = setmetatable({}, { __index = NeuroAction })
PickHandPackCards.__index = PickHandPackCards

local cards_picked = 0

local function pick_hand_pack_card(delay, hook)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            G.FUNCS.sort_hand_value({})
            local window = ActionWindow:new()
            window:add_action(PickHandPackCards:new(window, { hook }))
            local query,state = RunHelper:get_query_string()
            window:set_force(0.0, query, state, true)
            window:register()
            RunContext:hand_pack_booster()
            return true
        end
    }
    ))
end

function PickHandPackCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function PickHandPackCards:_get_name()
    return "pick_hand_cards"
end

function PickHandPackCards:_get_description()
    local description = string.format("Pick cards from this pack, you can pick a max of " ..
        SMODS.OPENED_BOOSTER.config.center.config.choose
        .. " cards "
        .. "out of the " ..
        SMODS.OPENED_BOOSTER.config.center.config.extra ..
        " available. You should pick the cards you want one at a time." ..
        " When defining the card's index the first card will be 1.")

    return description
end

function PickHandPackCards:_get_schema()
    local hand_length = RunHelper:get_hand_length(G.hand.cards)
    local pack_hand_length = RunHelper:get_hand_length(G.pack_cards.cards)

    return JsonUtils.wrap_schema({
        cards_index = {
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
    local selected_hand_index = data:get_object("cards_index")
    local selected_pack_card = data._data["pack_card_index"]
    selected_hand_index = selected_hand_index._data

    local card_config = G.pack_cards.cards[selected_pack_card].config.center.config

    if RunHelper:check_for_duplicates(selected_hand_index) == false then
        return ExecutionResult.failure("You cannot select the same card index more than once.")
    end

    local valid_hand_indices = RunHelper:get_hand_length(G.hand.cards)
    if not table.any(valid_hand_indices, function(options)
            return options == selected_pack_card
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("pack_card_index"))
    end

    if #selected_hand_index > G.hand.config.highlighted_limit then
        return ExecutionResult.failure(
            "You have selected more cards from your hand then you are allowed too.")
    end

    -- should fix issue with certain cards (mainly spectral) not needing highlighted cards
    if #selected_hand_index == 0 and card_config.max_highlighted ~= nil then
        return ExecutionResult.failure(
            "You should either take a card or skip the round.")
    end

    if card_config.max_highlighted ~= nil then
        if #selected_hand_index ~= card_config.max_highlighted then
            return ExecutionResult.failure(
                "You have either selected too many cards or to little from your hand comparative to how many the tarot needs.")
        end
    end

    state["cards_index"] = selected_hand_index
    state["pack_card_index"] = selected_pack_card
    return ExecutionResult.success("Using the " .. G.pack_cards.cards[selected_pack_card].config.center.name .. " card.")
end

function PickHandPackCards:_execute_action(state)
    local selected_index = state["cards_index"]
    local selected_pack_card = state["pack_card_index"]

    local pack_cards_hand = G.pack_cards.cards
    local consumable = pack_cards_hand[selected_pack_card]

    G.pack_cards:add_to_highlighted(consumable)

    -- only select cards in hand if they are required
    if consumable.config.center.config.max_highlighted ~= nil then
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


    cards_picked = cards_picked + 1
    if SMODS.OPENED_BOOSTER.config.center.config.choose > cards_picked then
        pick_hand_pack_card(5, self.hook)
        return true
    else
        cards_picked = 0
    end

    self.hook.HookRan = false
    return true
end

return PickHandPackCards
