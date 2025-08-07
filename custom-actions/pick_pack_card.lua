local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local SkipPack = ModCache.load("custom-actions/skip_pack.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")
local RunContext = ModCache.load("run_context.lua")

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
            local query,state = RunHelper:get_query_string()
            window:set_force(0.0, query, state, true)
            window:register()
            RunContext:no_hand_booster()
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

function PickCards:_get_description()
    local description = string.format("Pick cards to add to your deck. You can pick a max of " ..
    SMODS.OPENED_BOOSTER.config.center.config.choose
    .. " cards "
    .. "out of the " .. SMODS.OPENED_BOOSTER.config.center.config.extra .. " available." ..
    " When defining the card's index the first card will be 1.")

    return description
end

function PickCards:_get_schema()
    local hand_length = RunHelper:get_hand_length(G.pack_cards.cards)

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

    local valid_hand_indices = RunHelper:get_hand_length(G.pack_cards.cards)
    for _, value in ipairs(selected_hand_index) do
        if not RunHelper:value_in_table(valid_hand_indices, value) then
            return ExecutionResult.failure("Selected card index " .. tostring(value) .. " is not valid.")
        end
    end

    if #selected_hand_index > 1 then return ExecutionResult.failure("You can only take one card per action.") end

    if #selected_hand_index < 1 then return ExecutionResult.failure("You should either take a card or skip the round") end

    state["cards_index"] = selected_hand_index
	return ExecutionResult.success("Taking the " .. G.pack_cards.cards[selected_hand_index[1]].config.center.name .. " card.")
end

function PickCards:_execute_action(state)
    local selected_index = state["cards_index"]

    local hand = G.pack_cards.cards

    for _, index in ipairs(selected_index) do
        G.pack_cards:add_to_highlighted(hand[index])
        local button = nil
        for pos, value in ipairs(hand[index].children.use_button.UIRoot.children) do
            if value.config.button ~= nil then
                button = hand[index].children.use_button.UIRoot.children[pos]
                break
            end
        end
        if button == nil then
            sendErrorMessage("None of the cards have a valid use button")
            return true
        end
        button:click()

        cards_picked = cards_picked + 1
        if SMODS.OPENED_BOOSTER.config.center.config.choose > cards_picked then
            pick_pack_card(5,self.hook) -- call action again if more than one pack card can be picked. This is to reduce cooldown of action being registered
            return true
        else
            cards_picked = 0
        end
        self.hook.HookRan = false
        return true
    end

    self.hook.HookRan = false
	return true
end


return PickCards