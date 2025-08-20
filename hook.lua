local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local GamePrep = ModCache.load("game_prep.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local SelectDeck = ModCache.load("custom-actions/select_deck.lua")
local PlayingRun = ModCache.load("playing_run.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local PlayBlind = ModCache.load("custom-actions/play_blind.lua")
local SkipBlind = ModCache.load("custom-actions/skip_blind.lua")
local RerollBlind = ModCache.load("custom-actions/reroll_blind.lua")

local GetText = ModCache.load("get_text.lua")


local Hook = {}
Hook.__index = Hook

local should_unlock = NeuroConfig.UNLOCK_ALL

G.can_restart = NeuroConfig.CAN_RESTART_ON_CRASH
MAX_PLAYED_BLINDS = NeuroConfig.RESEND_MODIFIER_BLIND_AMOUNT
PLAYED_BLINDS = 0

local function load_profile(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay or 1,
        func = function()
            sendDebugMessage("highlighted profile: " .. G.focused_profile)

            G.PROFILES[neuro_profile].name = "Neuro-Sama"
            local tab_root = G.OVERLAY_MENU:get_UIE_by_ID("tab_contents").config.object.UIRoot

            -- tabs have a very cursed hierachy, there's definitely a better way to do this
            local button = tab_root.children[2].children[2].children[2].children[1].children[1]
            button:click()
            return true
        end
    }))
end

local function select_profile_tab(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay or 1,
        func = function()
            local button = G.OVERLAY_MENU:get_UIE_by_ID("tab_but_" .. neuro_profile)
            button:click()
            load_profile(1)
            return true
        end
    }))
end

local function open_profile_select(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay or 1,
        func = function()
            local profile_btn_box_root = G.PROFILE_BUTTON.UIRoot
            local button = profile_btn_box_root.children[1].children[2].children[1]
            button:click()
            -- idk if calling release does anything or not
            button:release()
            select_profile_tab(0.2)
            return true
        end
    }))
end

local function select_deck(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        func = function()
            local window = ActionWindow:new()
            window:set_force(0.0, "Pick a deck", "", false)
            window:add_action(SelectDeck:new(window, nil))
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
        Context.send("GAME OVER." .. (win and "You still won the game since you passed ante " .. G.GAME.win_ante or
            "You lost.\n" .. get_run_stats()))

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

local function hook_blind_select()
    local blind_select = Game.update_blind_select
    function Game:update_blind_select(dt)
        local complete = G.STATE_COMPLETE
        blind_select(self, dt)

        if complete then return end

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 1,
            blocking = false,
            func = function()
                local msg = "Entering blind selection. Completion of a blind gives money and an opportunity to shop, " ..
                    "while skipping a blind gives a tag instead. Failing a blind results in a game over. " ..
                    "You must at least play the Boss Blind, which has an additional special effect to make it harder.\n"

                Context.send(msg)

                local window = ActionWindow:new()
                window:set_force(0.0, "Choose to select or skip the currently selected blind",
                    GetText:generate_blind_descriptions())
                window:add_action(PlayBlind:new(window))
                if G.GAME.blind_on_deck ~= "Boss" then
                    window:add_action(SkipBlind:new(window))
                end
                if (G.GAME.dollars - G.GAME.bankrupt_at) - 10 >= 0 and
                    G.GAME.blind_on_deck == "Boss" and (G.GAME.used_vouchers["v_retcon"] or
                        (G.GAME.used_vouchers["v_directors_cut"] and not G.GAME.round_resets.boss_rerolled)) then
                    window:add_action(RerollBlind:new(window))
                end
                window:register()
                return true
            end
        }))
    end
end

local function hook_start_run()
    local start_run = G.FUNCS.start_run
    function G.FUNCS.start_run(e,args)
        start_run(e,args)

         -- we do this so we dont send voucher information right after starting a new run as that would be a bit redundant
        if PLAYED_BLINDS >= MAX_PLAYED_BLINDS - MAX_PLAYED_BLINDS / 3 then
            PLAYED_BLINDS = 0
            Context.send(GetRunText:get_all_modifier_desc(),true)
        end
    end
end

function Hook:hook_game()
    if not neuro_profile or neuro_profile < 1 or neuro_profile > 3 then
        neuro_profile = 3
        sendErrorMessage("Invalid profile slot specified in config, defaulting to profile slot 3", "Neuro Integration")
    end

    GameHooks.load()

    local ran_crash_callback = false
    local crash_start_time = 0
    G.on_crash_callback = function()
        if not ran_crash_callback then
            crash_start_time = love.timer.getTime()
            Context.send("There's a problem with the Balatro integration and the game has crashed. " ..
            "We'll automatically restart the game for you, but you'll lose your current run progress.")
            GameHooks.update() -- Game.update isnt called when the game has crashed so we have to manually update it here 
            ran_crash_callback = true
        end

        -- we cant use G.E_MANAGER since Game.update isnt being called
        -- so we have to manually check the time passed 
        if NeuroConfig.RESTART_DELAY <= 0 or love.timer.getTime() - crash_start_time >= NeuroConfig.RESTART_DELAY then
            SMODS.restart_game()
        end
    end

    local update = Game.update
    function Game:update(dt)
        update(self, dt)
        GameHooks.update(dt)
    end

    hook_main_menu()
    hook_game_over()
    hook_win()
    hook_start_run()
    PlayingRun:hook_draw_card()
    PlayingRun:hook_round_eval()
    PlayingRun:hook_end_consumeable()
    PlayingRun:hook_reroll_shop()
    PlayingRun:hook_play_cards()
    PlayingRun:hook_discard_cards()
    PlayingRun:hook_evaluate_play()
    PlayingRun:hook_new_round()

    hook_blind_select()

    Context.send("Welcome to Balatro! Balatro is a roguelike deck builder based around poker. " ..
        "In each round, or blind, you can play or discard a limited number of hands consisting of up to 5 cards. " ..
        "Each blind has a score requirement you have to reach, otherwise you will game over. " ..
        "Each poker hand has a base chips and multiplier that determines how much the hand will score. " ..
        "Then, every card played has it's value added to the chips (11 for Aces, 10 for King/Queen/Jack, then 10-2 for the rest). " ..
        "Only cards that directly count to the poker hand are counted. For example, if you play a two pair with an extra 5th card, " ..
        "the 5th card will not be counted. You may also get cards with modifiers like granting extra chips or mult when scored. " ..
        "The main component of Balatro deckbuilding are jokers. Jokers grant a variety of effects, from extra chips or mult to money or even consumables. " ..
        "The order in which you play cards and sort your jokers matter, as effects activate from left to right. " ..
        "For example, any effect that multiplies your total mult should be after any effects that increase your total mult by a flat amount. " ..
        "With the right setup of jokers, even a single high card can score more than a straight royal flush. Good luck!")
end

return Hook
