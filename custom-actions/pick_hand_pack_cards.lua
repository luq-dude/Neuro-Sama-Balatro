local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")

local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")
local SkipPack = ModCache.load("custom-actions/skip_pack.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PickHandPackCards = setmetatable({}, { __index = NeuroAction })
PickHandPackCards.__index = PickHandPackCards

local cards_picked = 0

local function pick_hand_pack_card(delay,hook)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PickHandPackCards:new(window, {hook}))
            window:register()
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
    SMODS.OPENED_BOOSTER.config.center.config.extra .. " available. You should pick the cards you want one at a time." ..
    " When defining the card's index the first card will be 1.")

    return description
end

local function get_pack_context()
    if #G.hand.cards > 0 then
        local hand, enhancements, editions, seals = table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards)),GetRunText:get_current_hand_modifiers(G.hand.cards)

        Context.send(string.format(
        "These are the playing cards in your hand \n" .. hand .. "\n" ..
        "These are the card modifiers that are on the cards right now," ..
        " there can only be one edition,enhancement and seal on each card: \n" ..
        enhancements .. "\n" ..
        editions .. "\n" ..
        seals),true)
    end

    if G.pack_cards == nil or G.pack_cards.cards == nil or G.pack_cards.cards == {} then return end
    if SMODS.OPENED_BOOSTER.config.center.kind == "Spectral" then
        local pack_hand = table.table_to_string(GetRunText:get_spectral_details(G.pack_cards.cards))
        Context.send(string.format("This is the hand of cards that are in this pack: " .. pack_hand))
    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" then
        local pack_hand = table.table_to_string(GetRunText:get_tarot_details(G.pack_cards.cards))
        Context.send(string.format("This is the hand of cards that are in this pack: " .. pack_hand))
    else -- modded packs that dont contain contain a default set or if there is something I forgot
        local pack_hand = table.table_to_string(GetRunText:get_hand_details(G.pack_cards.cards))
        Context.send(string.format("This is the hand of cards that are in this pack: " .. pack_hand))
    end
end

local function check_for_duplicates(table)
    local seen = {}
    for _, idx in ipairs(table) do
        if seen[idx] then
            return false
        end
        seen[idx] = true
    end
    return true
end

local function get_hand_length(card_table)
    local hand_length = {}
    for i = 1, #card_table do
        table.insert(hand_length, i)
    end
    return hand_length
end

local function value_in_table(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

function PickHandPackCards:_get_schema()
    get_pack_context()
    local hand_length = get_hand_length(G.hand.cards)
    local pack_hand_length = get_hand_length(G.pack_cards.cards)

    return JsonUtils.wrap_schema({
        cards_index = {
            type = "array",
            items ={
                type = "integer",
                enum = hand_length
            }
        },
		pack_card_index = { -- this is the tarot or spectral card
            type = "array",
            items = {
                type = "integer",
                enum = pack_hand_length
            }
		}
    })
end

function PickHandPackCards:_validate_action(data, state)
    local selected_hand_index = data:get_object("cards_index")
    local selected_pack_card = data:get_object("pack_card_index")
    selected_hand_index = selected_hand_index._data
    selected_pack_card = selected_pack_card._data

    if check_for_duplicates(selected_hand_index) == false then
        return ExecutionResult.failure("You cannot select the same card index more than once.")
    end

    local valid_hand_indices = get_hand_length(G.hand.cards)
    for _, value in ipairs(selected_hand_index) do
        if not value_in_table(valid_hand_indices, value) then
            return ExecutionResult.failure("Selected card index " .. tostring(value) .. " is not valid.")
        end
    end

    local valid_pack_indices = get_hand_length(G.pack_cards.cards)
    for _, value in ipairs(selected_pack_card) do
        if not value_in_table(valid_pack_indices, value) then
            return ExecutionResult.failure("Selected card index " .. tostring(value) .. " is not valid.")
        end
    end

    if #selected_hand_index > 5 then return ExecutionResult.failure("You tried to take more cards then you are allowed too.") end

    if #selected_hand_index == 0 then return ExecutionResult.failure("You should either take a card or skip the round.") end

    if #selected_pack_card > 1 then return ExecutionResult.failure("You should only pick one pack card at at time.") end
    if #selected_pack_card < 0 then return ExecutionResult.failure("You have took a pack card index that is too low.") end

    state["cards_index"] = selected_hand_index
    state["pack_card_index"] = selected_pack_card
    return ExecutionResult.success()
end

function PickHandPackCards:_execute_action(state)
    local selected_index = state["cards_index"]
    local selected_pack_card = state["pack_card_index"]

    local hand = G.hand.cards
    local pack_cards_hand = G.pack_cards.cards

    for _, index in ipairs(selected_index) do
        local card_id = hand[index]
        G.hand:add_to_highlighted(hand[index])
    end

    for _, index in ipairs(selected_pack_card) do
        G.pack_cards:add_to_highlighted(pack_cards_hand[index])
        local button = pack_cards_hand[index].children.use_button.UIRoot.children[2]
        button:click()
        cards_picked = cards_picked + 1
        if SMODS.OPENED_BOOSTER.config.center.config.choose > cards_picked then
            pick_hand_pack_card(5,self.hook) -- call action again if more than one pack card can be picked.
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


return PickHandPackCards