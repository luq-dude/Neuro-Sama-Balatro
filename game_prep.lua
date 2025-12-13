local GamePrep = {}

local RunHelper = NEURO.MOD_CACHE.load("run_functions_helper.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local neuro_profile = NEURO.CONFIG["PROFILE_SLOT"]

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

function GamePrep.select_profile(delay)
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
            NEURO.SET_STATE(NEURO.STATES.DECK_SELECTION)
            return true
        end
    }
    ))
end

-- assumes that we are on the title screen
function GamePrep.start_from_title()
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

-- assumes we are on the game over screen
function GamePrep.start_from_gameover()
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 2,
        func = function()
            G.OVERLAY_MENU:get_UIE_by_ID('from_game_over'):click()
            select_deck(2)
            return true
        end
    }))
end

function GamePrep.unlock_all()
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

return GamePrep
