local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local SelectDeck = ModCache.load("custom-actions/select_deck.lua")

local Hook = {}
Hook.__index = Hook

local neuro_profile = NeuroConfig.PROFILE_SLOT
local should_unlock = NeuroConfig.UNLOCK_ALL

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
            window:set_force(0.0, "Pick a deck", "The game has yet to start. " ..
                "To start a new run, first select a deck. " ..
                "Each deck has a different effect that changes how the game is played.", false)
            window:add_action(SelectDeck:new(window))
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
                    open_profile_select(1)
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
                        return true
                    end
                    -- lets start the game
                    -- eventualyl this whole section should be moved somewhere else
                    -- bc games can also start after losing one without going to the main menu
                    -- but for now im leaving it here
                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        delay = 2,
                        func = function()
                            G.MAIN_MENU_UI:get_UIE_by_ID('main_menu_play'):click()
                            select_deck(2)
                            return true
                        end
                    }))
                end
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
end

return Hook
