local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local GamePrep = ModCache.load("game_prep.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local Hook = {}
Hook.__index = Hook

local should_unlock = NeuroConfig.UNLOCK_ALL


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
                print('aaaaaaaaa')
                G.FUNCS.exit_overlay_menu()
                return true
            end
        }))
    end
end


SMODS.Keybind {
    event = 'pressed',
    key_pressed = 'p',
    action = function()
        win_game()
    end
}

SMODS.Keybind {
    event = 'pressed',
    key_pressed = "'",
    action = function()
        G.FUNCS.exit_overlay_menu()
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
end

return Hook
