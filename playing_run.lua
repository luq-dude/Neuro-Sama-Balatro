local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local PlayCards = ModCache.load("custom-actions/play_cards.lua")
local PickCard = ModCache.load("custom-actions/pick_pack_card.lua")
local PickPackCard = ModCache.load("custom-actions/pick_hand_pack_cards.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")

local PlayingRun = {}

local function play_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PlayCards:new(window, nil))
            window:register()
            return true
        end
    }
    ))
end

local function pick_pack_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PickCard:new(window, nil))
            window:register()
            return true
        end
    }
    ))
end

-- use for tarot and spectral
local function pick_hand_pack_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PickPackCard:new(window, nil))
            window:register()
            return true
        end
    }
    ))
end


local function get_current_hand_modifiers(cards)
    local enhancements = table.table_to_string(GetRunText:get_hand_enhancements(cards))
    local editions = table.table_to_string(GetRunText:get_hand_editions(cards))
    local seals = table.table_to_string(GetRunText:get_hand_seals(cards))

    local enhancements_string = "- card enhancements: " .. enhancements
    local editions_string = "- card editions: " .. editions
    local seals_string = "- card seals: " .. seals

    if enhancements == "" then
        enhancements_string = "There are no enhancements on your cards"
    elseif editions == "" then
        editions_string = "There are no editions on your cards"
    elseif seals == "" then
        seals_string = "There are no seals on your cards"
    end

    return enhancements_string,editions_string,seals_string
end

-- TODO: Stop spamming of running event / sending actions while it does get handled the fact it happens is still suboptimal
-- TODO: Add checks for current state this can be done with G.STATE a good example of this is in G.FUNCS.draw_from_deck_to_hand
function PlayingRun:hook_draw_card()
    local original_draw_card = draw_card
    function draw_card(from, to, percent, dir, sort, card, delay, mute, stay_flipped, vol, discarded_only)
        original_draw_card(from, to, percent, dir, sort, card, delay, mute, stay_flipped, vol, discarded_only)

        sendDebugMessage("draw_card called")

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blocking = false,
            delay = 8,
            func = function ()
                    sendDebugMessage("start second event")
                    if G.STATE == nil or G.STATE == G.STATES.HAND_PLAYED or G.STATE == G.STATES.DRAW_TO_HAND or G.STATE == G.STATES.SHOP then
                        return true
                    end

                    if G.STATE == G.STATES.SELECTING_HAND then
                        local enhancements, editions, seals = get_current_hand_modifiers(G.hand.cards)

                        Context.send(string.format("These are what the card's modifiers do," ..
                        " there can only be one edition,enhancement and seal on each card: \n" ..
                        enhancements .. "\n" ..
                        editions .. "\n" ..
                        seals),true)

                        play_card(14)
                        return true
                    end

                    if SMODS.OPENED_BOOSTER == nil then
                        return true
                    end

                    sendDebugMessage("LOOKS AT THIS: " .. SMODS.OPENED_BOOSTER.config.center.kind)

                    -- use this to send different context for each type of pack and different action for spectral and arcana
                    if SMODS.OPENED_BOOSTER.config.center.kind == "Buffoon" then -- cant use G.STATE
                        local hand = table.table_to_string(GetRunText:get_joker_details(G.pack_cards.cards))

                        Context.send(string.format("This is the hand of cards that are in this pack: \n" ..
                        hand .. "\n" ..
                        "These cards will give passive bonuses after each hand played, these range from increasing the chips" ..
                        " increasing the mult of a hand or giving money or consumables after certain actions."))

                        pick_pack_card(12)
                    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Celestial" then
                        local hand = table.table_to_string(GetRunText:get_celestial_details(G.pack_cards.cards))

                        Context.send(string.format("This is the hand of cards that are in this pack: \n" ..
                        hand .. "\n" ..
                        "These cards will level up a poker hand and improve the scoring that you will receive for playing them."))

                        pick_pack_card(20)
                    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Standard" then
                        local hand, enhancements, editions, seals = table.table_to_string(GetRunText:get_card_modifiers(G.pack_cards.cards)),get_current_hand_modifiers(G.pack_cards.cards)

                        Context.send(string.format("This is the hand of cards that are in this pack: \n" ..
                        hand .. "\n" ..
                        "These are the card modifiers that are on the cards right now," ..
                        " there can only be one edition,enhancement and seal on each card: \n" ..
                        enhancements .. "\n" ..
                        editions .. "\n" ..
                        seals),true)
                        sendDebugMessage("Get last opened booster" .. tprint(SMODS.OPENED_BOOSTER,1,2))
                        pick_pack_card(20)
                    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Spectral" then
                        local hand, enhancements, editions, seals = table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards)),get_current_hand_modifiers(G.hand.cards)
                        local pack_hand = table.table_to_string(GetRunText:get_spectral_details(G.pack_cards.cards))

                        Context.send(string.format("This is the hand of cards that are in this pack: " ..
                        pack_hand .. "\n" ..
                        "these are the cards in your hand \n" .. hand .. "\n" ..
                        "These are the card modifiers that are on the cards right now," ..
                        " there can only be one edition,enhancement and seal on each card: \n" ..
                        enhancements .. "\n" ..
                        editions .. "\n" ..
                        seals),true)
                        pick_hand_pack_card(20)
                    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" then
                        sendDebugMessage("running arcana action")
                        local hand, enhancements, editions, seals = table.table_to_string(GetRunText:get_card_modifiers(G.hand.cards)),get_current_hand_modifiers(G.hand.cards)
                        local pack_hand = table.table_to_string(GetRunText:get_tarot_details(G.pack_cards.cards))

                        Context.send(string.format("This is the hand of cards that are in this pack: " ..
                        pack_hand .. "\n" ..
                        "these are the cards in your hand \n" .. hand .. "\n" ..
                        "These are the card modifiers that are on the cards right now," ..
                        " there can only be one edition,enhancement and seal on each card: \n" ..
                        enhancements .. "\n" ..
                        editions .. "\n" ..
                        seals),true)
                        pick_hand_pack_card(20)
                    else
                    end
                return true
            end
        }))
    end
    return true
end



return PlayingRun