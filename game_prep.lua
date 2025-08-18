local GamePrep = {}

local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local SelectDeck = ModCache.load("custom-actions/select_deck.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local GetRunText = ModCache.load("get_run_text.lua")

local neuro_profile = NeuroConfig.PROFILE_SLOT

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
            G.OVERLAY_MENU.definition.nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[1].config.button_UIE:click() -- this clicks new run button... i'm so sorry.
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

-- assumes that we are on the title screen
function GamePrep.start_from_title()
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 2,
        func = function()
            G.MAIN_MENU_UI:get_UIE_by_ID('main_menu_play'):click()
            select_deck(2)
            Context.send(GetRunText:get_all_modifier_desc(), true)
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

return GamePrep
