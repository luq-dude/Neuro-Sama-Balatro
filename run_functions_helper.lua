local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

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

function RunHelper:reorder_card_area(card_area, new_indicies)
    card_area.cards = table.reorder_list(card_area.cards, new_indicies)
    card_area:align_cards()
end

function RunHelper.validate_consumable(card, selected_indices, selected_action)
    if selected_action == "Sell" then
        if #selected_indices == 0 then
            return true, "Selling the " .. card.config.center.name .. " for $" .. card.sell_cost
        end
        return false, "You cannot select cards while selling a consumeable"
    end

    local args = NEURO.CONSUMABLE_OVERRIDES[card.config.center_key] or {}
    args.card = card
    args.selected = selected_indices
    local ret_parts = {}
    for _, func in ipairs(NEURO.CONSUMABLE_VALIDATE_FUNCS) do
        local res, string = func(args)
        if not res then
            return res, (string or "")
        end
        if string then ret_parts[#ret_parts+1] = string end
    end
    ret_parts[#ret_parts+1] = "Using " .. GetRunText.get_card_description(card)
    if #ret_parts > 0 then
        return true, table.concat(ret_parts, ". ")
    end
    return true, ""
end

function RunHelper.run_after(delay, func)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        func = func
    }))
end


return RunHelper