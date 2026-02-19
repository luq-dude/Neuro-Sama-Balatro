local Mode = NEURO.MOD_CACHE.load("modes/mode.lua")

local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")
local GamePrep = NEURO.MOD_CACHE.load("game_prep.lua")
local ActionWindow = NEURO.MOD_CACHE.load("game-sdk/actions/action_window.lua")

local SelectDeck = NEURO.MOD_CACHE.load("custom-actions/select_deck.lua")
local SelectStake = NEURO.MOD_CACHE.load("custom-actions/select_stake.lua")

local PlayBlind = NEURO.MOD_CACHE.load("custom-actions/play_blind.lua")
local SkipBlind = NEURO.MOD_CACHE.load("custom-actions/skip_blind.lua")
local RerollBlind = NEURO.MOD_CACHE.load("custom-actions/reroll_blind.lua")

local UseHandCards = NEURO.MOD_CACHE.load("custom-actions/use_hand_cards.lua")
local JokerInteraction = NEURO.MOD_CACHE.load("custom-actions/joker_interaction.lua")
local UseConsumable = NEURO.MOD_CACHE.load("custom-actions/use_consumables.lua")

local QueryDeck = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_deck.lua")
local QueryJokers = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_jokers.lua")
local QueryConsumables = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_consumables.lua")
local QueryMoney = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_money.lua")
local QueryModifiers = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_modifiers.lua")
local QueryVouchers = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_vouchers.lua")
local QueryPokerHands = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_poker_hands.lua")
local QueryHand = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_hand.lua")
local QueryShop = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_shop.lua")
local QueryBoosterCards = NEURO.MOD_CACHE.load("custom-actions/query-actions/query_booster_cards.lua")

local ExitShop = NEURO.MOD_CACHE.load("custom-actions/shop-actions/exit_shop.lua")
local RerollShop = NEURO.MOD_CACHE.load("custom-actions/shop-actions/reroll_shop.lua")
local BuyShopCard = NEURO.MOD_CACHE.load("custom-actions/shop-actions/buy_shop_card.lua")
local BuyShopBooster = NEURO.MOD_CACHE.load("custom-actions/shop-actions/buy_shop_booster.lua")
local BuyShopVoucher = NEURO.MOD_CACHE.load("custom-actions/shop-actions/buy_shop_voucher.lua")

local PickCard = NEURO.MOD_CACHE.load("custom-actions/pick_pack_card.lua")
local PickPackCard = NEURO.MOD_CACHE.load("custom-actions/pick_hand_pack_cards.lua")
local SkipPack = NEURO.MOD_CACHE.load("custom-actions/skip_pack.lua")

local CoopContext = NEURO.MOD_CACHE.load("coop_context.lua")

local CoopMode = setmetatable({}, { __index = Mode })
CoopMode.__index = CoopMode

function CoopMode:new()
    local obj = Mode:new(self)
    obj.non_perishable_window = nil
    obj.hand_window = nil
    obj.shop_window = nil
    obj.booster_window = nil
    return obj
end

function CoopMode:main_menu()
    if NEURO.STATE_STATUS == 0 then
        Context.send(CoopContext.get_boot_text())
        if NEURO.CONFIG["COOP_ACTIONS"]["PICK_DECK"] then
            GamePrep.start_from_title()
        end
        NEURO.INC_STATE()
    end
end

function CoopMode:register_non_perishable()
    if not self.non_perishable_window then
       local window = ActionWindow:new()
       window:add_action(QueryDeck:new(window))
       window:add_action(QueryJokers:new(window))
       window:add_action(QueryConsumables:new(window))
       window:add_action(QueryMoney:new(window))
       window:add_action(QueryModifiers:new(window))
       window:add_action(QueryVouchers:new(window))
       window:add_action(QueryPokerHands:new(window))
       window:set_perishable(false) -- don't unregister after one of these is completed
       window:register()
       self.non_perishable_window = window
    end
end

function CoopMode:deck_selection()
    if NEURO.STATE_STATUS == 0 then
        if NEURO.CONFIG["COOP_ACTIONS"]["PICK_DECK"] then
            G.OVERLAY_MENU.definition.nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].nodes[1].config.button_UIE:click()
            local context = RunContext.get_deck_context()
            local window = ActionWindow:new()
            window:add_action(SelectDeck:new(window))
            window:set_context(context.query .. "\n" .. context.state, true)
            window:register()
        end
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- wait
    elseif NEURO.STATE_STATUS == 2 then
        if NEURO.CONFIG["COOP_ACTIONS"]["PICK_DECK"] then
            local window = ActionWindow:new()
            local context = RunContext.get_stake_context()
            window:add_action(SelectStake:new(window, nil))
            window:set_context(context.query .. "\n" .. context.state, true)
            window:register()
        end
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 3 then
        -- wait
    elseif NEURO.STATE_STATUS == 4 then
        NEURO.INC_STATE()
    end
end

function CoopMode:select_blind()
    if NEURO.STATE_STATUS == 0 then
        self:register_non_perishable()
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 1,
            blocking = false,
            func = function ()
                local ctx = RunContext.get_select_blind_context()
                if NEURO.CONFIG["COOP_ACTIONS"]["SELECT_BLIND"] then
                    local window = ActionWindow:new()
                    window:add_action(PlayBlind:new(window))
                    if G.GAME.blind_on_deck ~= "Boss" then
                        window:add_action(SkipBlind:new(window))
                    end
                    if (G.GAME.dollars - G.GAME.bankrupt_at) - 10 >= 0 and
                        G.GAME.blind_on_deck == "Boss" and (G.GAME.used_vouchers["v_retcon"] or
                        (G.GAME.used_vouchers["v_directors_cut"] and
                            not G.GAME.round_resets.boss_rerolled)) then
                                window:add_action(RerollBlind:new(window))
                    end
                    window:register()
                end
                Context.send(ctx.state, true)
                return true
            end
        }))
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- wait
    elseif NEURO.STATE_STATUS == 2 then
        -- blind just got skipped
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
    if #G.jokers.cards > 0 and NEURO.CONFIG["COOP_ACTIONS"]["MODIFY_JOKERS"] then
        window:add_action(JokerInteraction:new(window))
    end

    if #G.consumeables.cards > 0 and NEURO.CONFIG["COOP_ACTIONS"]["USE_CONSUMABLES"] then
        window:add_action(UseConsumable:new(window))
    end
end


function CoopMode:in_blind()
    if NEURO.STATE_STATUS == 0 then
        -- we just drew a hand
        if self.hand_window then
            self.hand_window:_end()
            self.hand_window = nil
        end
        if self.shop_window then
            self.shop_window:_end()
            self.shop_window = nil
        end
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 4 * G.SPEEDFACTOR,
            blocking = false,
            func = function ()
                local window = ActionWindow:new()
                if NEURO.CONFIG["COOP_ACTIONS"]["PLAY_CARDS"] then
                    window:add_action(UseHandCards:new(window))
                end
                window:add_action(QueryHand:new(window))
                register_joker_consumables(window)
                if NEURO.CONFIG["COOP_STATE_CONTEXT"] then
                    local ctx = RunContext.get_in_blind_context()
                    Context.send(ctx.state, true)
                end
                window:register()
                self.hand_window = window
                return true
            end
        }))
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- waiting for action execute
    elseif NEURO.STATE_STATUS == 2 then
        -- waiting for hand to score
        if self.hand_window then
            self.hand_window:_end()
            self.hand_window = nil
        end
    elseif NEURO.STATE_STATUS == 3 then
        -- hand has scored
        NEURO.INC_STATE()
        local chip_total = hand_chips * mult
        if G.GAME.chips + chip_total >= tonumber(G.GAME.blind.chips) then
            Context.send(CoopContext.get_blind_win_text(), true)
            return --  instead let the round eval hook do this
        end

        if G.GAME.current_round.hands_left < 1 then
            return -- context handled by losing run hook
        end
        Context.send(CoopContext.get_last_hand_text(), true)
        NEURO.SET_STATE(nil, 0)
    end
end


local function register_shop_actions(window)
    if ((G.GAME.dollars-G.GAME.bankrupt_at) - G.GAME.current_round.reroll_cost >= 0 or
        G.GAME.current_round.free_rerolls > 1) and NEURO.CONFIG["COOP_ACTIONS"]["REROLL_SHOP"] then
            window:add_action(RerollShop:new(window))
    end

    if #G.shop_jokers.cards > 0 and NEURO.CONFIG["COOP_ACTIONS"]["BUY_CARDS"] then
        window:add_action(BuyShopCard:new(window))
    end

    if #G.shop_booster.cards > 0 and NEURO.CONFIG["COOP_ACTIONS"]["BUY_BOOSTERS"] then
        window:add_action(BuyShopBooster:new(window))
    end

    if #G.shop_vouchers.cards > 0 and NEURO.CONFIG["COOP_ACTIONS"]["BUY_VOUCHERS"] then
        window:add_action(BuyShopVoucher:new(window))
    end

    if NEURO.CONFIG["COOP_ACTIONS"]["EXIT_SHOP"] then
        window:add_action(ExitShop:new(window))
    end
end

function CoopMode:in_shop()
    if NEURO.STATE_STATUS == 0 then
        if self.shop_window then
            self.shop_window:_end()
            self.shop_window = nil
        end
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 2 * G.SPEEDFACTOR,
            blocking = false,
            func = function()
                if NEURO.STATE ~= NEURO.STATES.IN_SHOP or G.STATE ~= G.STATES.SHOP then
                    return true
                end
                local ctx = RunContext.get_shop_context()
                local window = ActionWindow:new()
                window:add_action(QueryShop:new())
                register_shop_actions(window)
                register_joker_consumables(window)
                if NEURO.CONFIG["COOP_STATE_CONTEXT"] then
                    Context.send(ctx.state, true)
                end
                window:register()
                self.shop_window = window
                return true
            end
        }))
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- waiting for action execute
    end
end


function CoopMode:in_booster_pack()
    if NEURO.STATE_STATUS == 0 then
        if self.shop_window then
            self.shop_window:_end()
            self.shop_window = nil
        end
        if self.booster_window then
            self.booster_window:_end()
            self.booster_window = nil
        end
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blocking = false,
            delay = 3 * G.SPEEDFACTOR,
            func = function ()
                if NEURO.STATE ~= NEURO.STATES.IN_BOOSTER_PACK then return true end
                local ctx = RunContext.get_booster_context()
                local window = ActionWindow:new()
                local booster = SMODS.OPENED_BOOSTER
                if NEURO.CONFIG["COOP_ACTIONS"]["PICK_PACK_CARDS"] then
                    if booster.config.center.draw_hand then
                        window:add_action(PickPackCard:new(window))
                    else
                        window:add_action(PickCard:new(window))
                    end
                    window:add_action(SkipPack:new(window))
                end
                register_joker_consumables(window)
                if NEURO.CONFIG["COOP_STATE_CONTEXT"] then
                    Context.send(ctx.state, true)
                end
                window:register()
                self.booster_window = window
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
            NEURO.INC_STATE()
            return
        end
        -- go back to previous state
        NEURO.SET_STATE(NEURO.STATE_INTERRUPT)
        NEURO.STATE_INTERRUPT = nil
    end
end

function CoopMode:game_over()
    if NEURO.STATE_STATUS == 0 then
        -- we lost
        Context.send(RunContext.get_game_over_text(false))
        if self.non_perishable_window then
            self.non_perishable_window:_end()
            self.non_perishable_window = nil
        end
        if self.hand_window then
            self.hand_window:_end()
            self.hand_window = nil
        end
        if NEURO.CONFIG["COOP_ACTIONS"]["PICK_DECK"] then
            GamePrep.start_from_gameover()
        end
        NEURO.INC_STATE()
    elseif NEURO.STATE_STATUS == 1 then
        -- waiting
    elseif NEURO.STATE_STATUS == 2 then
        -- we won
        Context.send(RunContext.get_game_over_text(true))
        NEURO.INC_STATE()
    end
end

return CoopMode
