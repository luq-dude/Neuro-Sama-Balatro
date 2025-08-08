local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")

local UseHandCards = ModCache.load("custom-actions/use_hand_cards.lua")
local JokerInteraction = ModCache.load("custom-actions/joker_interaction.lua")
local UseConsumable = ModCache.load("custom-actions/use_consumables.lua")
local PickCard = ModCache.load("custom-actions/pick_pack_card.lua")
local PickPackCard = ModCache.load("custom-actions/pick_hand_pack_cards.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local SkipPack = ModCache.load("custom-actions/skip_pack.lua")
local DeckTypes = ModCache.load("custom-actions/deck_type.lua")
local PokerHandInfo = ModCache.load("custom-actions/get_poker_hand_info.lua")

local ExitShop = ModCache.load("custom-actions/shop-actions/exit_shop.lua")
local RerollShop = ModCache.load("custom-actions/shop-actions/reroll_shop.lua")
local BuyShopCard = ModCache.load("custom-actions/shop-actions/buy_shop_card.lua")
local BuyShopBooster = ModCache.load("custom-actions/shop-actions/buy_shop_booster.lua")
local BuyShopVoucher = ModCache.load("custom-actions/shop-actions/buy_shop_voucher.lua")

local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local RunContext = ModCache.load("run_context.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")

local PlayingRun = {}

PlayingRun.HookRan = false

local function extra_card_action_check(window,actions)
    if #G.jokers.cards > 0 then
        window:add_action(JokerInteraction:new(window, {PlayingRun,actions,UseConsumable}))
    end

    if #G.consumeables.cards > 0 then
        window:add_action(UseConsumable:new(window, {PlayingRun,actions,JokerInteraction}))
    end
end

function PlayingRun:play_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            local query,state = RunHelper:get_query_string()
            window:set_force(0.0, query, state, true)
            window:add_action(UseHandCards:new(window, {PlayingRun}))
            window:add_action(DeckTypes:new(window,{PlayingRun}))
            window:add_action(PokerHandInfo:new(window,{PlayingRun}))
            extra_card_action_check(window,{UseHandCards,DeckTypes,PokerHandInfo})
            window:register()
            return true
        end
    }
    ))
end

local function pick_pack_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            local query,state = RunHelper:get_query_string()
            window:set_force(0.0, query, state, true)
            window:add_action(PickCard:new(window, {PlayingRun}))
            window:add_action(SkipPack:new(window, {PlayingRun}))
            extra_card_action_check(window,{PickCard,SkipPack})
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
        delay = delay * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PickPackCard:new(window, {PlayingRun}))
            window:add_action(SkipPack:new(window, {PlayingRun}))
            extra_card_action_check(window,{PickPackCard,SkipPack})
            local query,state = RunHelper:get_query_string()
            window:set_force(0.0, query, state, true)
            window:register()
            return true
        end
    }
    ))
end

function PlayingRun:hook_new_round()
    local round = new_round
    function new_round()
        round()
        local jokers = table.table_to_string(GetRunText:get_joker_details(G.jokers.cards))
        local consumeables = table.table_to_string(GetRunText:get_consumeables_text(G.consumeables.cards))

        if #jokers > 0 then
            Context.send("These are the jokers in your hand and their abilites: " .. jokers,true)
        else
            Context.send("You do not have any jokers as of right now.",true)
        end

        if #consumeables > 0 then
            Context.send("These are the consumeables in your hand and their abililties: " .. consumeables,true)
        else
            Context.send("You do not have any consumeables as of right now.",true)
        end
    end
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
            delay = 2 * G.SPEEDFACTOR,
            func = function ()
                    if G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.DRAW_TO_HAND then
                        Context.send("You now have the option to select a hand, you have " .. tostring(G.GAME.current_round.hands_left) .. " hands left and " .. tostring(G.GAME.current_round.discards_left) .. " discards left")
                        Context.send("You have " .. tostring(#G.deck.cards) .. " cards remaining in your deck that have the ability to be drawn, out of the " .. tostring(G.deck.config.card_limit) .. " cards in it.")
                        self:play_card(3)
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
                            pick_hand_pack_card(5)
                            return true
                        else
                            pick_pack_card(5)
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

local function unregister_run_action()
    local unregister_actions = {UseHandCards}
    if #G.jokers.cards > 0 then unregister_actions[#unregister_actions+1] = JokerInteraction end
    if #G.consumeables.cards > 0 then unregister_actions[#unregister_actions+1] = UseConsumable end
    NeuroActionHandler.unregister_actions(unregister_actions)
end

-- these two are for testing
function PlayingRun:hook_play_cards()
    local play_cards = G.FUNCS.play_cards_from_highlighted
    function G.FUNCS.play_cards_from_highlighted(e)
        if PlayingRun.HookRan then
            PlayingRun.HookRan = false
            unregister_run_action()
        end

        play_cards(e)
    end
end

function PlayingRun:hook_discard_cards()
    local discard_cards = G.FUNCS.discard_cards_from_highlighted
    function G.FUNCS.discard_cards_from_highlighted(e)
        if PlayingRun.HookRan then
            PlayingRun.HookRan = false
            unregister_run_action()
        end

        discard_cards(e)
    end
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

function PlayingRun:hook_evaluate_play()
    local eval = G.FUNCS.evaluate_play
    function G.FUNCS.evaluate_play(e)
        local _,disp_text,_,_ = G.FUNCS.get_poker_hand_info(G.play.cards)
        eval(e)
        local chip_total = hand_chips * mult
        if G.GAME.chips + chip_total >= tonumber(G.GAME.blind.chips) then
            Context.send("Congratulations! You just won the blind with the hand type: " .. disp_text .. ", you scored " .. G.GAME.chips + chip_total .. " chips this blind. You had to score " .. G.GAME.blind.chips .. " chips to win this blind.")
            return
        end

        if G.GAME.current_round.hands_left < 1 then
            return -- context handled by losing run hook
        end

        Context.send("This hand, you scored: " .. chip_total .. " chips, with the hand type: " .. disp_text .. ". This blind you have a total of: " .. G.GAME.chips + chip_total ..  " chips. You need to score a total of: " .. G.GAME.blind.chips .. " chips to win this blind")
    end
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
                    self:register_store_actions(2)
                    return true
                end
            }
            ))
        end
    end
end

function PlayingRun:hook_end_consumeable()
    local end_consumeable = G.FUNCS.end_consumeable
    function G.FUNCS.end_consumeable(e,s)
        if G.shop and G.booster_pack then -- this is for boosters
            PlayingRun:register_store_actions(2,PlayingRun)
        end

        end_consumeable(e,s)
    end
end

function PlayingRun:hook_reroll_shop()
    local reroll_shop = G.FUNCS.reroll_shop
    function G.FUNCS.reroll_shop(e)
        reroll_shop(e)
        PlayingRun:register_store_actions(2,PlayingRun)
    end
end

function PlayingRun:register_store_actions(delay,hook)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            local query,state = RunHelper:get_query_string()

            local actions = {ExitShop}
            if (G.GAME.dollars-G.GAME.bankrupt_at) - G.GAME.current_round.reroll_cost < 0 and G.GAME.current_round.free_rerolls < 1 then
            else
                actions[#actions+1] = RerollShop
                state = state .. "\n Rerolling the shop costs: $" .. G.GAME.current_round.reroll_cost .. " You have" .. G.GAME.current_round.free_rerolls .. " free rerolls."
            end
            if #G.shop_jokers.cards > 0 then
                actions[#actions+1] = BuyShopCard
                state = state .. "\n These are the cards in the shop right now: " .. table.table_to_string(GetRunText:get_consumeables_text(G.shop_jokers.cards,true))
            end
            if #G.shop_booster.cards > 0 then
                actions[#actions+1] = BuyShopBooster
                state = state .. "\n These are the booster packs in the shop: " .. table.table_to_string(GetRunText:get_shop_text(G.shop_booster.cards,true))
            end
            if #G.shop_vouchers.cards > 0 then
                actions[#actions+1] = BuyShopVoucher
                state = state .. "\n This is the voucher in the shop: " .. table.table_to_string(GetRunText:get_shop_text(G.shop_vouchers.cards,true))
            end

            actions[#actions+1] = DeckTypes
            actions[#actions+1] = PokerHandInfo

            extra_card_action_check(window,actions)

            for index, action in ipairs(actions) do
                window:add_action(action:new(window,{self}))
            end
            window:set_force(0.0, query, state, true)
            window:register()
            return true
        end
    }
    ))
end

return PlayingRun