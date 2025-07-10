local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")

local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")
local SkipPack = ModCache.load("custom-actions/skip_pack.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PickCards = setmetatable({}, { __index = NeuroAction })
PickCards.__index = PickCards

local cards_picked = 0

local function pick_pack_card(delay,hook)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PickCards:new(window, {hook}))
            window:register()
            return true
        end
    }
    ))
end

function PickCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    return obj
end

function PickCards:_get_name()
    return "pick_cards"
end

function PickCards:_get_description()  -- use G.P_CENTERS.p-buffoon_jumbo_1.config for getting values
    local description = string.format("Pick cards to add to your deck. You can pick a max of " ..
    SMODS.OPENED_BOOSTER.config.center.config.choose
    .. " cards "
    .. "out of the " .. SMODS.OPENED_BOOSTER.config.center.config.extra .. " available." ..
    " When defining the card's index the first card will be 1.")

    return description
end

local function get_card_context()
    if G.pack_cards == nil or G.pack_cards.cards == nil or G.pack_cards.cards == {} then return end
    if SMODS.OPENED_BOOSTER.config.center.kind == "Buffoon" or G.pack_cards.cards[1].ability.set == "Joker" then
            local hand = table.table_to_string(GetRunText:get_joker_details(G.pack_cards.cards))

            Context.send(string.format("This is the hand of cards that are in this pack: " ..
            hand .. "\n" ..
            "These cards will give passive bonuses after each hand played, these range from increasing the chips" ..
            " increasing the mult of a hand or giving money or consumables after certain actions."))

    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Celestial" or G.pack_cards.cards[1].ability.set == "Celestial" then
        local hand = table.table_to_string(GetRunText:get_celestial_details(G.pack_cards.cards))

        Context.send(string.format("This is the hand of cards that are in this pack: " ..
        hand .. "\n" ..
        "These cards will level up a poker hand and improve the scoring that you will receive for playing them."))
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Standard" or G.pack_cards.cards[1].ability.set == "Base" then
        local hand, enhancements, editions, seals = table.table_to_string(GetRunText:get_card_modifiers(G.pack_cards.cards)),GetRunText:get_current_hand_modifiers(G.pack_cards.cards)

        Context.send(string.format("This is the hand of cards that are in this pack: " ..
        hand .. "\n" ..
        "These are the card modifiers that are on the cards right now," ..
        " there can only be one edition,enhancement and seal on each card: \n" ..
        enhancements .. "\n" ..
        editions .. "\n" ..
        seals),true)
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Spectral" or G.pack_cards.cards[1].ability.set == "Spectral" then
        sendDebugMessage("Spectral should not be called from pick_pack_card")
        return
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" or G.pack_cards.cards[1].ability.set == "Tarot" then
        sendDebugMessage("Arcana should not be called from pick_pack_card")
        return
    else -- modded packs that dont contain contain a default set or if there is something I forgot
        sendDebugMessage("card table: " .. tprint(G.pack_cards.cards,1,2))
        local hand = table.table_to_string(GetRunText:get_hand_names(G.pack_cards.cards))

        Context.send(string.format("This is the hand of cards that are in this pack: " ..
        hand))
    end
end

local function value_in_table(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

local function get_hand_length(card_table)
    local hand_length = {}
    for i = 1, #card_table do
        table.insert(hand_length, i)
    end
    return hand_length
end

function PickCards:_get_schema()
    get_card_context()
    local hand_length = get_hand_length(G.pack_cards.cards)

    return JsonUtils.wrap_schema({
        cards_index = {
            type = "array",
            items ={
                type = "integer",
                enum = hand_length
            }
        },
    })
end

function PickCards:_validate_action(data, state)
    local selected_hand_index = data:get_object("cards_index")
    selected_hand_index = selected_hand_index._data

    local valid_hand_indices = get_hand_length(G.pack_cards.cards)
    for _, value in ipairs(selected_hand_index) do
        if not value_in_table(valid_hand_indices, value) then
            return ExecutionResult.failure("Selected card index " .. tostring(value) .. " is not valid.")
        end
    end

    if #selected_hand_index > 1 then return ExecutionResult.failure("You can only take one card per action.") end

    if #selected_hand_index < 1 then return ExecutionResult.failure("You should either take a card or skip the round") end

    state["cards_index"] = selected_hand_index
	return ExecutionResult.success()
end

-- id play card button: "play_button"
function PickCards:_execute_action(state)
    local selected_index = state["cards_index"]

    local hand = G.pack_cards.cards

    for _, index in ipairs(selected_index) do
        G.pack_cards:add_to_highlighted(hand[index])
        local button = hand[index].children.use_button.UIRoot.children[1]
        button:click()

        cards_picked = cards_picked + 1
        if SMODS.OPENED_BOOSTER.config.center.config.choose > cards_picked then
            pick_pack_card(5,self.hook) -- call action again if more than one pack card can be picked
        else
            cards_picked = 0
        end
        self.hook.HookRan = false
        NeuroActionHandler.unregister_actions({SkipPack})
        return true
    end

    self.hook.HookRan = false
    NeuroActionHandler.unregister_actions({SkipPack})
	return true
end


return PickCards