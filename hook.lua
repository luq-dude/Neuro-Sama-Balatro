local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local GamePrep = ModCache.load("game_prep.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local PlayCards = ModCache.load("custom-actions/play_cards.lua")
local PickCard = ModCache.load("custom-actions/pick_pack_card.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local GetText = ModCache.load("get_text.lua")

local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")

local Hook = {}
Hook.__index = Hook

local should_unlock = NeuroConfig.UNLOCK_ALL

local function play_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
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
local function pick_pack_card_and_hand(delay)
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

local function hook_main_menu()
    local main_menu = Game.main_menu
    function Game:main_menu(change_context)
        main_menu(self, change_context)

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 1,
            blocking = false,
            func = function()
                local profile_num = G.SETTINGS.profile
                sendDebugMessage("Currently on profile " .. profile_num, "Neuro Integration")
                sendDebugMessage("Should unlock: " .. tostring(should_unlock), "Neuro Integration")
                sendDebugMessage("All unlocked: " .. tostring(G.PROFILES[G.SETTINGS.profile].all_unlocked),
                    "Neuro Integration")
                -- if the profile isn't neuro's profile, we need to switch to it
                if profile_num ~= neuro_profile then
                    GamePrep.select_profile(1)
                else
                    -- it is neuros profile so lets unlock everything if we need to
                    if should_unlock and not G.PROFILES[neuro_profile].all_unlocked then
                        sendDebugMessage("On neuro's profile AND we should unlock everything AND we haven't yet",
                            "Neuro Integration")
                        G.PROFILES[G.SETTINGS.profile].all_unlocked = true
                        for _, v in pairs(G.P_CENTERS) do
                            if not v.demo and not v.wip then
                                v.alerted = true
                                v.discovered = true
                                v.unlocked = true
                            end
                        end
                        for _, v in pairs(G.P_BLINDS) do
                            if not v.demo and not v.wip then
                                v.alerted = true
                                v.discovered = true
                                v.unlocked = true
                            end
                        end
                        for _, v in pairs(G.P_TAGS) do
                            if not v.demo and not v.wip then
                                v.alerted = true
                                v.discovered = true
                                v.unlocked = true
                            end
                        end
                        SMODS.SAVE_UNLOCKS()
                    end
                    -- now we can start the game
                    GamePrep.start_from_title()
                end
                return true
            end
        }))
    end
end

local function get_run_stats()
    -- TODO: check if its a new high score value
    local best_hand = number_format(G.GAME.round_scores['hand'].amt) -- highest score in a single hand
    local amt = 0
    local most_played = nil                                          -- most played hand type
    for k, v in pairs(G.GAME.hand_usage) do
        if v.count > amt then
            most_played = v.order
            amt = v.count
        end
    end


    local cards_played = G.GAME.round_scores['cards_played'].amt
    local cards_discarded = G.GAME.round_scores['cards_discarded'].amt
    local cards_bought = G.GAME.round_scores['cards_purchased'].amt
    local rerolls = G.GAME.round_scores['times_rerolled'].amt

    local ante = G.GAME.round_scores['furthest_ante'].amt
    local round = G.GAME.round_scores['furthest_round'].amt


    return string.format(
        "Here's some stats about your run:\n" ..
        "Highest scoring hand: %s\n" ..
        "Most played hand type: %s (Played %d times)\n" ..
        "Cards played: %d\n" ..
        "Cards discarded: %d\n" ..
        "Cards purchased: %d\n" ..
        "Times rerolled: %d\n" ..
        "Ante: %d\n" ..
        "Round: %d\n",
        best_hand,
        most_played,
        amt,
        cards_played,
        cards_discarded,
        cards_bought,
        rerolls,
        ante,
        round)
end

local function hook_game_over()
    local game_over = Game.update_game_over
    function Game:update_game_over(dt)
        local complete = G.STATE_COMPLETE -- if this is false then the call to game_over will make G.STATE_COMPLETE true
        game_over(self, dt)

        if complete then return end -- if it was already true then weve already run this before
        local win = G.GAME.round_resets.ante > G.GAME.win_ante
        Context.send("GAME OVER." .. win and "You still won the game since you passed ante " .. G.GAME.win_ante or
            "You lost.\n" .. get_run_stats())

        GamePrep.start_from_gameover()
    end
end

local function hook_win()
    local win = win_game
    function win_game()
        win()
        Context.send(
            "YOU WIN! The game will now continue in Endless Mode. Try to keep your run going for as long as possible!\n" ..
            get_run_stats())
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 2,
            pause_force = true,
            func = function()
                G.FUNCS.exit_overlay_menu()
                return true
            end
        }))
    end
end

local function hook_start_run()
    local start_run = Game.start_run
    function Game:start_run(args)
        start_run(self, args)

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 4,
            blocking = false,
            func = function()
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 4,
                    blocking = false,
                    func = function()
                        sendDebugMessage("start second event")
                        play_card(12)
                        return true
                    end
                }))
                return true
            end
        }))

    end
    return true
end

local function get_current_hand_modifiers(cards)
    local enhancements = table.table_to_string(GetText:get_hand_enhancements(cards))
    local editions = table.table_to_string(GetText:get_hand_editions(cards))
    local seals = table.table_to_string(GetText:get_hand_seals(cards))

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
local function hook_draw_card()
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
                    if G.STATE == nil or G.STATE == G.STATES.HAND_PLAYED or G.STATE == G.STATES.DRAW_TO_HAND  then
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
                    elseif SMODS.OPENED_BOOSTER.config.center.kind == "Arcana" then
                    else
                    end
                return true
            end
        }))
    end
    return true
end

-- call play_card after selecting first bind
SMODS.Keybind {
    key = 'test_cards',
    key_pressed = 'c',

    action = function(self)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0,
            blocking = false,
            func = function()
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0,
                    blocking = false,
                    func = function()
                        sendDebugMessage("start second event")
                        play_card(2)
                        return true
                    end
                }))
                return true
            end
        }))
    end
}


function Hook:hook_game()
    if not neuro_profile or neuro_profile < 1 or neuro_profile > 3 then
        neuro_profile = 3
        sendErrorMessage("Invalid profile slot specified in config, defaulting to profile slot 3", "Neuro Integration")
    end

    GameHooks.load()

    local update = Game.update
    function Game:update(dt)
        update(self, dt)
        GameHooks.update(dt)
    end

    hook_main_menu()
    hook_game_over()
    hook_win()
    hook_start_run()
end

return Hook
