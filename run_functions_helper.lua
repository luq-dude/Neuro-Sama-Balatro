local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local RunHelper = {}

function RunHelper:value_in_table(tbl,val)
	for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

function RunHelper:get_hand_length(card_table)
    local hand_length = {}
    for i = 1, #card_table do
        table.insert(hand_length, i)
    end
    return hand_length
end

function RunHelper:increment_card_table(table)
    local selected_table = {}
    for _, card in pairs(table) do
        if selected_table[card] == nil then
            selected_table[card] = 1
        else
            selected_table[card] = selected_table[card] + 1
        end
    end
    return selected_table
end

function RunHelper:check_for_duplicates(table)
    local seen = {}
    for _, idx in ipairs(table) do
        if seen[idx] then
            return false
        end
        seen[idx] = true
    end
    return true
end

-- extra should be joker_interaction is extra[1] and use_consumables in extra[2], actions should not include either of those
function RunHelper:register_actions_extra(delay,hook,actions,extra)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            for index, action in ipairs(actions) do
                window:add_action(action:new(window,{hook,actions,extra}))
            end

            if #G.jokers.cards > 0 then
                window:add_action(extra[1]:new(window, {hook,actions,extra[2]}))
            end

            if #G.consumeables.cards > 0 then
                window:add_action(extra[2]:new(window, {hook,actions,extra[1]}))
            end

            window:register()
            return true
        end}))
end

function RunHelper:reorder_card_area(card_area, new_indicies)
    card_area.cards = table.reorder_list(card_area.cards, new_indicies)
    card_area:align_cards()
end

return RunHelper