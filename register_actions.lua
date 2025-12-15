local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")
local RunHelper = NEURO.MOD_CACHE.load("run_functions_helper.lua")
local GamePrep = NEURO.MOD_CACHE.load("game_prep.lua")
local ActionWindow = NEURO.MOD_CACHE.load("game-sdk/actions/action_window.lua")
local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

local SelectDeck = NEURO.MOD_CACHE.load("custom-actions/select_deck.lua")
local SelectStake = NEURO.MOD_CACHE.load("custom-actions/select_stake.lua")

local PlayBlind = NEURO.MOD_CACHE.load("custom-actions/play_blind.lua")
local SkipBlind = NEURO.MOD_CACHE.load("custom-actions/skip_blind.lua")
local RerollBlind = NEURO.MOD_CACHE.load("custom-actions/reroll_blind.lua")

local UseHandCards = NEURO.MOD_CACHE.load("custom-actions/use_hand_cards.lua")
local JokerInteraction = NEURO.MOD_CACHE.load("custom-actions/joker_interaction.lua")
local UseConsumable = NEURO.MOD_CACHE.load("custom-actions/use_consumables.lua")
local DeckTypes = NEURO.MOD_CACHE.load("custom-actions/deck_type.lua")
local PokerHandInfo = NEURO.MOD_CACHE.load("custom-actions/get_poker_hand_info.lua")
local ModifierInformation = NEURO.MOD_CACHE.load("custom-actions/modifier_information.lua")

local ExitShop = NEURO.MOD_CACHE.load("custom-actions/shop-actions/exit_shop.lua")
local RerollShop = NEURO.MOD_CACHE.load("custom-actions/shop-actions/reroll_shop.lua")
local BuyShopCard = NEURO.MOD_CACHE.load("custom-actions/shop-actions/buy_shop_card.lua")
local BuyShopBooster = NEURO.MOD_CACHE.load("custom-actions/shop-actions/buy_shop_booster.lua")
local BuyShopVoucher = NEURO.MOD_CACHE.load("custom-actions/shop-actions/buy_shop_voucher.lua")

local PickCard = NEURO.MOD_CACHE.load("custom-actions/pick_pack_card.lua")
local PickPackCard = NEURO.MOD_CACHE.load("custom-actions/pick_hand_pack_cards.lua")
local SkipPack = NEURO.MOD_CACHE.load("custom-actions/skip_pack.lua")

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
    elseif NEURO.STATE == NEURO.STATES.IN_BLIND then
        RegisterActions.in_blind()
    elseif NEURO.STATE == NEURO.STATES.IN_SHOP then
        RegisterActions.in_shop()
    elseif NEURO.STATE == NEURO.STATES.IN_BOOSTER_PACK then
        RegisterActions.in_booster_pack()
    elseif NEURO.STATE == NEURO.STATES.GAME_OVER then
        RegisterActions.game_over()
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
            delay = 1 * G.SPEEDFACTOR,
            blocking = false,
            func = function ()
                if G.STATE ~= G.STATES.BLIND_SELECT then return true end
                NEURO.SET_STATE(nil, 0)
                return true
            end
        }))
        NEURO.INC_STATE()
    end
end
local function register_joker_consumables(window)
    if #G.jokers.cards > 0 then
        window:add_action(JokerInteraction:new(window))
    end

    if #G.consumeables.cards > 0 then
        window:add_action(UseConsumable:new(window))
    end
end

function RegisterActions.in_blind()
    if NEURO.STATE_STATUS == 0 then
        -- we just drew a hand
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 4 * G.SPEEDFACTOR,
            blocking = false,
            func = function ()
                local ctx = RunContext.get_in_blind_context()
                local window = ActionWindow:new()
                window:set_force(0.0, ctx.query, ctx.state, true)
                window:add_action(UseHandCards:new(window))
                window:add_action(DeckTypes:new(window))
                window:add_action(PokerHandInfo:new(window))
                window:add_action(ModifierInformation:new(window))
                register_joker_consumables(window)
                window:register()
                return true
            end
        }))
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- waiting for action execute
    elseif NEURO.STATE_STATUS == 2 then
        -- waiting for hand to score
    elseif NEURO.STATE_STATUS == 3 then
        -- hand has scored
        NEURO.INC_STATE()

        local chip_total = hand_chips * mult
        if G.GAME.chips + chip_total >= tonumber(G.GAME.blind.chips) then
            local _,disp_text,_,_ = G.FUNCS.get_poker_hand_info(G.play.cards)
            Context.send(string.format(
                "Congratulations! You just won the blind with the hand type: %s, " ..
                "you scored %d chips out of a required %d chips to win.",
                disp_text,
                G.GAME.chips + chip_total,
                G.GAME.blind.chips)
            )

            return --  instead let the round eval hook do this
        end

        if G.GAME.current_round.hands_left < 1 then
            return -- context handled by losing run hook
        end

        local _,disp_text,_,_ = G.FUNCS.get_poker_hand_info(G.play.cards)
        Context.send(string.format(
            "This hand, you scored %d chips with the hand type %s. You need to score %d total to win this blind.",
            chip_total,
            disp_text,
            G.GAME.chips + chip_total,
            G.GAME.blind.chips)
        )
        NEURO.SET_STATE(nil, 0)
    elseif NEURO.STATE_STATUS == 10 then
        -- blind won
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 5 * G.SPEEDFACTOR,
            blocking = false,
            func = function()
                G.FUNCS.cash_out({ config = {} })
                Context.send(GetRunText.get_round_info())
                NEURO.SET_STATE(NEURO.STATES.IN_SHOP)
                return true
            end
        }))
        NEURO.INC_STATE()
    end
end

local function register_shop_actions(window)
    if (G.GAME.dollars-G.GAME.bankrupt_at) - G.GAME.current_round.reroll_cost >= 0 or
        G.GAME.current_round.free_rerolls > 1 then
            window:add_action(RerollShop:new(window))
    end

    if #G.shop_jokers.cards > 0 then
        window:add_action(BuyShopCard:new(window))
    end

    if #G.shop_booster.cards > 0 then
        window:add_action(BuyShopBooster:new(window))
    end

    if #G.shop_vouchers.cards > 0 then
        window:add_action(BuyShopVoucher:new(window))
    end

    window:add_action(ExitShop:new(window))
end

function RegisterActions.in_shop()
    if NEURO.STATE_STATUS == 0 then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 2 * G.SPEEDFACTOR,
            blocking = false,
            func = function()
                local ctx = RunContext.get_shop_context()
                local window = ActionWindow:new()
                window:set_force(0.0, ctx.query, ctx.state, true)
                window:add_action(DeckTypes:new(window))
                window:add_action(PokerHandInfo:new(window))
                window:add_action(ModifierInformation:new())
                register_shop_actions(window)
                register_joker_consumables(window)
                window:register()
                return true
            end
        }))
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- waiting for action execute
    end
end

function RegisterActions.in_booster_pack()
    if NEURO.STATE_STATUS == 0 then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blocking = false,
            delay = 2 * G.SPEEDFACTOR,
            func = function ()
                local ctx = RunContext.get_booster_context()
                local window = ActionWindow:new()
                local booster = SMODS.OPENED_BOOSTER
                if booster.config.center.draw_hand then
                    window:add_action(PickPackCard:new(window))
                else
                    window:add_action(PickCard:new(window))
                end
                window:add_action(SkipPack:new(window))
                register_joker_consumables(window)
                window:set_force(0.0, ctx.query, ctx.state, true)
                window:register()
                return true
            end
        }))
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- wait for action execute
    elseif NEURO.STATE_STATUS == 2 then
        -- closing pack
        if not NEURO.STATE_INTERRUPT then
            sendErrorMessage("No state to return to from pack opening")
            Context.send("An error with the integration has occurred. " ..
                "The game will likely be soft-locked without manual intervention. " ..
                "Please tell someone to report this to the integration devs on Discord!")
            NEURO.INC_STATE()
            return
        end
        -- go back to previous state
        NEURO.SET_STATE(NEURO.STATE_INTERRUPT)
        NEURO.STATE_INTERRUPT = nil
    end
end

function RegisterActions.game_over()
    if NEURO.STATE_STATUS == 0 then
        -- we lost
        Context.send(RunContext.get_game_over_text(false))
        GamePrep.start_from_gameover()
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- waiting
    elseif NEURO.STATE_STATUS == 2 then
        -- we won
        Context.send(RunContext.get_game_over_text(true))
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 2,
            pause_force = true,
            func = function()
                G.FUNCS.exit_overlay_menu()
                return true
            end
        }))
        NEURO.INC_STATE()
    end
end
return RegisterActions