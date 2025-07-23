local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local UseHandCards = ModCache.load("custom-actions/use_hand_cards.lua")
local JokerInteraction = ModCache.load("custom-actions/joker_interaction.lua")
local UseConsumable = ModCache.load("custom-actions/use_consumables.lua")
local PickCard = ModCache.load("custom-actions/pick_pack_card.lua")
local PickPackCard = ModCache.load("custom-actions/pick_hand_pack_cards.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local SkipPack = ModCache.load("custom-actions/skip_pack.lua")
local RerollShop = ModCache.load("custom-actions/reroll_shop.lua")
local ExitShop = ModCache.load("custom-actions/exit_shop.lua")
local BuyShopCard = ModCache.load("custom-actions/buy_shop_card.lua")
local BuyShopBooster = ModCache.load("custom-actions/buy_shop_booster.lua")
local BuyShopVoucher = ModCache.load("custom-actions/buy_shop_voucher.lua")


local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")

local PlayingRun = {}

PlayingRun.HookRan = false

local function extra_card_action_check(window)
    if #G.jokers.cards > 0 then
        window:add_action(JokerInteraction:new(window, {PlayingRun}))
    end

    if #G.consumeables.cards > 0 then
        window:add_action(UseConsumable:new(window, {PlayingRun}))
    end
end

local function play_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(UseHandCards:new(window, {PlayingRun}))
            extra_card_action_check(window)

            window:register()
            return true
        end
    }
    ))
end

local function pick_pack_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()

            window:add_action(PickCard:new(window, {PlayingRun}))
            extra_card_action_check(window)

            window:register()
            return true
        end
    }
    ))
end

-- use for tarot and spectral
local function pick_hand_pack_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()

            window:add_action(PickPackCard:new(window, {PlayingRun}))
            extra_card_action_check(window)

            window:register()
            return true
        end
    }
    ))
end

local function skip_pack(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(SkipPack:new(window, {PickCard,PickPackCard,PlayingRun}))
            window:register()
            return true
        end
    }
    ))
end

function PlayingRun:hook_draw_card()
    local original_draw_card = draw_card
    function draw_card(from, to, percent, dir, sort, card, delay, mute, stay_flipped, vol, discarded_only)
        original_draw_card(from, to, percent, dir, sort, card, delay, mute, stay_flipped, vol, discarded_only)
        if G.STATE == G.STATES.HAND_PLAYED then return true end
        if self.HookRan then sendDebugMessage("Blocked a hook call G.state was " .. G.STATE) return true end -- this stops actions or context being sent multiple times
        self.HookRan = true -- this needs to be set back to false after in an actions execute_action
        sendDebugMessage("draw_card called")

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blocking = false,
            delay = 8,
            func = function ()
                    if G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.DRAW_TO_HAND then
                        play_card(14)
                        return true
                    end

                    local booster = SMODS.OPENED_BOOSTER
                    if booster == nil then
                        sendDebugMessage("booster is nil: " .. G.STATE)
                        self.HookRan = false
                        return true
                    end

                    if G.STATE == 999 then -- I'm pretty sure all boosters go through this then become the vanilla state so just using this should be fine
                        if booster.config.center.draw_hand then
                            pick_hand_pack_card(20)
                            skip_pack(20)
                            return true
                        else
                            pick_pack_card(20)
                            skip_pack(20)
                            return true
                        end
                    end

                    sendDebugMessage(G.STATE .. " was not used as a state")
                    self.HookRan = false
                return true
            end
        }))
    end
    return true
end

ROUND_EVAL = {} -- we set this in round_eval.toml
local function get_round_info(round_eval)
    local context = "This is how much money you have made in the blind: "
    table.reverse(round_eval)
    for index, value in pairs(round_eval) do
        local name = value[1]
        local money = value[2]
        if string.match(name,"blind") ~= nil then name = "Blind" end -- otherwise name would be 'blind1'
        if string.match(name,"bottom") ~= nil then
            context = context .. "\nIn total you have made $" .. money
            goto continue
        end
        if string.match(name,"custom") ~= nil then name = round_eval.text end -- added by smods for modded rows

        context = context .. "\nFrom " .. name .. " you have made $" .. money
        ::continue::
    end

    ROUND_EVAL = {}
    return context
end

function PlayingRun:hook_round_eval()
    local update_round = add_round_eval_row
    function add_round_eval_row(config)
        update_round(config)
        local round_eval = ROUND_EVAL

        if config.name == "bottom" then -- bottom is the total
            Context.send(get_round_info(round_eval))
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 5 * G.SPEEDFACTOR,
                blocking = false,
                func = function()
                    G.FUNCS.cash_out({ config = {} })
                    self:register_store_actions(2 * G.SPEEDFACTOR)
                    return true
                end
            }
            ))
        end
    end
end

function PlayingRun:hook_reroll_shop()
    local reroll_shop = G.FUNCS.reroll_shop
    function G.FUNCS.reroll_shop(e)
        reroll_shop(e)
        -- TODO: send context here
        PlayingRun:register_store_actions(2 * G.SPEEDFACTOR,PlayingRun)
    end
end

function PlayingRun:register_play_actions(delay,hook)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            if G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.DRAW_TO_HAND then
                window:add_action(UseHandCards:new(window, {hook}))
            end

            extra_card_action_check(window)

            window:register()
            return true
        end
    }
    ))
end

function PlayingRun:register_store_actions(delay,hook)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()

            window:add_action(ExitShop:new(window,{self}))
            if G.GAME.dollars > G.GAME.current_round.reroll_cost or G.GAME.current_round.free_rerolls > 0 then
                window:add_action(RerollShop:new(window,{self}))
            end
            if #G.shop_jokers.cards > 0 then
                window:add_action(BuyShopCard:new(window,{self}))
            end
            if #G.shop_booster.cards > 0 then
                window:add_action(BuyShopBooster:new(window,{self}))
            end
            if #G.shop_vouchers.cards > 0 then
                window:add_action(BuyShopVoucher:new(window,{self}))
            end

            window:register()
            return true
        end
    }
    ))
end

return PlayingRun