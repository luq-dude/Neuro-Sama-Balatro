local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local GamePrep = ModCache.load("game_prep.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local SelectDeck = ModCache.load("custom-actions/select_deck.lua")
local PlayingRun = ModCache.load("playing_run.lua")

local PlayBlind = ModCache.load("custom-actions/play_blind.lua")
local SkipBlind = ModCache.load("custom-actions/skip_blind.lua")
local RerollBlind = ModCache.load("custom-actions/reroll_blind.lua")

local GetText = ModCache.load("get_text.lua")


local Hook = {}
Hook.__index = Hook

local should_unlock = NeuroConfig.UNLOCK_ALL

G.can_restart = NeuroConfig.CAN_RESTART_ON_CRASH

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
    PlayingRun:hook_new_round()
    PlayingRun:hook_draw_card()
    PlayingRun:hook_round_eval()
    PlayingRun:hook_end_consumeable()
    PlayingRun:hook_reroll_shop()
    PlayingRun:hook_play_cards()
    PlayingRun:hook_discard_cards()
    PlayingRun:hook_evaluate_play()

    hook_blind_select()
end

return Hook
