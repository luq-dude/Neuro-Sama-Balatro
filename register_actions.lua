local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")
local RunHelper = NEURO.MOD_CACHE.load("run_functions_helper.lua")
local GamePrep = NEURO.MOD_CACHE.load("game_prep.lua")
local ActionWindow = NEURO.MOD_CACHE.load("game-sdk/actions/action_window.lua")
local SelectDeck = NEURO.MOD_CACHE.load("custom-actions/select_deck.lua")
local SelectStake = NEURO.MOD_CACHE.load("custom-actions/select_stake.lua")
local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")
local PlayBlind = NEURO.MOD_CACHE.load("custom-actions/play_blind.lua")
local SkipBlind = NEURO.MOD_CACHE.load("custom-actions/skip_blind.lua")
local RerollBlind = NEURO.MOD_CACHE.load("custom-actions/reroll_blind.lua")

local RegisterActions = {}

local should_unlock = NEURO.CONFIG["UNLOCK_ALL"]
local neuro_profile = NEURO.CONFIG["PROFILE_SLOT"]

local prev_state = -1
local prev_progress = -1
function RegisterActions.update()
    if prev_state ~= NEURO.STATE or prev_progress ~= NEURO.STATE_STATUS then 
        print(string.format("Current state: %d (%d)", NEURO.STATE, NEURO.STATE_STATUS))
    end
    prev_state = NEURO.STATE
    prev_progress = NEURO.STATE_STATUS
    if NEURO.STATE == NEURO.STATES.GAME_BOOT then
        RegisterActions.game_boot()
    elseif NEURO.STATE == NEURO.STATES.DECK_SELECTION then
        RegisterActions.deck_selection()
    elseif NEURO.STATE == NEURO.STATES.BLIND_SELECTION then
        RegisterActions.select_blind()
    end
end

function RegisterActions.game_boot()
    if NEURO.STATE_STATUS == 0 then
        Context.send(RunContext.get_boot_text())
        Context.send(RunContext.get_all_modifier_desc())
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- wait for main_menu call
    elseif NEURO.STATE_STATUS == 2 then
        RunHelper.run_after(1, function ()
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
                        GamePrep.unlock_all()
                    end
                    -- now we can start the game
                    GamePrep.start_from_title()
                end
                return true
        end)
        NEURO.INC_STATE()
    end
end

function RegisterActions.deck_selection()
    if NEURO.STATE_STATUS == 0 then
        G.OVERLAY_MENU.definition.nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[1].config.button_UIE:click() -- this clicks new run button... i'm so sorry.
        local window = ActionWindow:new()
        window:set_force(0.0, "Pick a deck", "The game has yet to start. " ..
            "To start a new run, first select a deck. " ..
            "Each deck has a different effect that changes how the game is played.", false)
        window:add_action(SelectDeck:new(window))
        window:register()
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- wait for select_deck execute
    elseif NEURO.STATE_STATUS == 2 then
        local window = ActionWindow:new()
        window:add_action(SelectStake:new(window, nil))
        window:set_force(1.0, "Pick a stake", "Next you need to select a stake. The white stake is the default, with" ..
        " every stake after making the game harder. Stakes are progressive, so a higher stake applies all previous effects.", false)
        window:register()
        NEURO.INC_STATE()
    end
end

function RegisterActions.select_blind()
    if NEURO.STATE_STATUS == 0 then
       RunHelper.run_after(1, function()
            local msg = "Entering blind selection. Completion of a blind gives money and an opportunity to shop, " ..
                "while skipping a blind gives a tag instead. Failing a blind results in a game over. " ..
                "You must at least play the Boss Blind, which has an additional special effect to make it harder.\n"
            Context.send(msg)
            local window = ActionWindow:new()
            window:set_force(0.0, "Choose to select or skip the currently selected blind",
                table.table_to_string(GetRunText.get_blind_descriptions()))
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
        end)
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- wait for either played blind or skip blind execute
    elseif NEURO.STATE_STATUS == 2 then
        -- skip blind was executed
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 2,
            blocking = false,
            func = function ()
                if G.STATE ~= G.STATES.BLIND_SELECT then return false end
                NEURO.SET_STATE(nil, 0)
                return true
            end
        }))
        NEURO.INC_STATE()
    end
end

return RegisterActions