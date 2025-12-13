local GameHooks = NEURO.MOD_CACHE.load("game-sdk/game_hooks.lua")
local GamePrep = NEURO.MOD_CACHE.load("game_prep.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local ActionWindow = NEURO.MOD_CACHE.load("game-sdk/actions/action_window.lua")

local SelectDeck = NEURO.MOD_CACHE.load("custom-actions/select_deck.lua")
local PlayingRun = NEURO.MOD_CACHE.load("playing_run.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local RunHelper = NEURO.MOD_CACHE.load("run_functions_helper.lua")
local RegisterActions = NEURO.MOD_CACHE.load("register_actions.lua")

local Hook = {}
Hook.__index = Hook

local should_unlock = NEURO.CONFIG["UNLOCK_ALL"]
local neuro_profile = NEURO.CONFIG["PROFILE_SLOT"]

NEURO.CAN_RESTART = NEURO.CONFIG["CAN_RESTART_ON_CRASH"]
NEURO.MAX_PLAYED_BLINDS = NEURO.CONFIG["RESEND_MODIFIER_BLIND_AMOUNT"]
NEURO.PLAYED_BLINDS = 0

local function hook_main_menu()
    local main_menu = Game.main_menu
    function Game:main_menu(change_context)
        main_menu(self, change_context)
        if NEURO.STATE == NEURO.STATES.GAME_BOOT and NEURO.STATE_STATUS == 1 then
            NEURO.INC_STATE()
        end
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
        blind_select(self, dt)
        if NEURO.STATE ~= NEURO.STATES.BLIND_SELECTION then
            NEURO.SET_STATE(NEURO.STATES.BLIND_SELECTION)
        end
    end
end

local function hook_start_run()
    local start_run = G.FUNCS.start_run
    function G.FUNCS.start_run(e,args)
        start_run(e,args)

         -- we do this so we dont send voucher information right after starting a new run as that would be a bit redundant
        if NEURO.PLAYED_BLINDS >= NEURO.MAX_PLAYED_BLINDS - NEURO.MAX_PLAYED_BLINDS / 3 then
            NEURO.PLAYED_BLINDS = 0
            Context.send(RunContext.get_all_modifier_desc(),true)
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
        if NEURO.CONFIG["RESTART_DELAY"] <= 0 or love.timer.getTime() - crash_start_time >= NEURO.CONFIG["RESTART_DELAY"] then
            SMODS.restart_game()
        end
    end

    local update = Game.update
    function Game:update(dt)
        update(self, dt)
        GameHooks.update(dt)
        RegisterActions.update()
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
end

return Hook
