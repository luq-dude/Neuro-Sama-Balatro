local GameHooks = NEURO.MOD_CACHE.load("game-sdk/game_hooks.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")

local PlayingRun = NEURO.MOD_CACHE.load("playing_run.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

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

local function hook_game_over()
    local game_over = Game.update_game_over
    function Game:update_game_over(dt)
        local complete = G.STATE_COMPLETE
        game_over(self, dt)

        if complete then return end
        NEURO.SET_STATE(NEURO.STATES.GAME_OVER)
    end
end

local function hook_win()
    local win = win_game
    function win_game()
        win()
        NEURO.SET_STATE(NEURO.STATES.GAME_OVER, 2)
    end
end

local function hook_blind_select()
    local blind_select = Game.update_blind_select
    function Game:update_blind_select(dt)
        blind_select(self, dt)
        if NEURO.STATE ~= NEURO.STATES.BLIND_SELECTION
            and NEURO.STATE ~= NEURO.STATES.IN_BLIND and not NEURO.STATE_INTERRUPT then
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
    PlayingRun:hook_round_eval()
    PlayingRun:hook_play_cards()
    PlayingRun:hook_discard_cards()
    PlayingRun:hook_evaluate_play()
    PlayingRun:hook_new_round()
    PlayingRun.hook_draw_to_hand()
    PlayingRun.hook_booster_open()
    hook_blind_select()
end

return Hook
