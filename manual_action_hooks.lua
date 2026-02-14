local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local CoopContext = NEURO.MOD_CACHE.load("coop_context.lua")

local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

local NeuroActionHandler = NEURO.MOD_CACHE.load("game-sdk/actions/neuro_action_handler.lua")
local UseHandCards = NEURO.MOD_CACHE.load("custom-actions/use_hand_cards.lua")
local JokerInteraction = NEURO.MOD_CACHE.load("custom-actions/joker_interaction.lua")
local UseConsumable = NEURO.MOD_CACHE.load("custom-actions/use_consumables.lua")


local ManualHooks = {}

function ManualHooks.hook_all()
    ManualHooks.hook_start_game()
    ManualHooks.hook_play_cards()
    ManualHooks.hook_discard_cards()
    ManualHooks.hook_play_blind()
    ManualHooks.hook_skip_blind()
    ManualHooks.hook_reroll_shop()
    ManualHooks.hook_reroll_blind()
    ManualHooks.hook_win_blind()
    ManualHooks.hook_sell_card()
    ManualHooks.hook_buy_card()
    ManualHooks.hook_use_card()
    ManualHooks.hook_skip_booster()
end

function ManualHooks.hook_start_game()
    local orig = Game.start_run
    Game.start_run = function (self, args)
        orig(self, args)
        args = args or {}
        if not args.neuro and NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
            Context.send(CoopContext.get_man_deck_select())
        end
    end
end

function ManualHooks.hook_play_blind()
    local orig = G.FUNCS.select_blind
    G.FUNCS.select_blind = function (e)
        e = e or {}
        if not e.neuro then
            if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
                Context.send("Opening the " .. G.GAME.blind_on_deck .. " Blind.", true)
            end
            NEURO.SET_STATE(nil, 10)
        end
        orig(e)
    end
end

function ManualHooks.hook_skip_blind()
    local orig = G.FUNCS.skip_blind
    G.FUNCS.skip_blind = function (e)
        e = e or {}
        if not e.neuro then
            if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
                Context.send("Skipping the " .. G.GAME.blind_on_deck .. " Blind.", true)
            end
            NEURO.INC_STATE()
        end
        orig(e)
    end
end

function ManualHooks.hook_reroll_blind()
    local orig = G.FUNCS.reroll_boss
    G.FUNCS.reroll_boss = function (e)
        e = e or {}
        if not e.neuro then
            if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
                Context.send("Rerolling the boss Blind.", true)
            end
            NEURO.INC_STATE()
        end
        orig(e)
    end
end


local function unregister_run_action()
    local unregister_actions = {UseHandCards}
    if #G.jokers.cards > 0 then unregister_actions[#unregister_actions+1] = JokerInteraction end
    if #G.consumeables.cards > 0 then unregister_actions[#unregister_actions+1] = UseConsumable end
    NeuroActionHandler.unregister_actions(unregister_actions)
end

function ManualHooks.hook_play_cards()
    local play_cards = G.FUNCS.play_cards_from_highlighted
    function G.FUNCS.play_cards_from_highlighted(e)
        local played = GetRunText.get_hand_details(G.hand.highlighted, true)
        e = e or {}
        play_cards(e)
        if not e.neuro then
            -- should never happen normally, but useful when testing
            if NEURO.MODE == "solo" then
                NEURO.INC_STATE()
                print("A hand was manually played in solo mode, this is not officially supported!")
                unregister_run_action()
                return
            end
            if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
                Context.send("These cards were played:" .. table.concat(played), true)
            end
            NEURO.INC_STATE()
        end
    end
end

function ManualHooks.hook_discard_cards()
    local discard_cards = G.FUNCS.discard_cards_from_highlighted
    function G.FUNCS.discard_cards_from_highlighted(e, hook)
        local played = GetRunText.get_hand_details(G.hand.highlighted, true)
        e = e or {}
        discard_cards(e, hook)
        if not e.neuro then
           -- should never happen normally, but useful when testing
            if NEURO.MODE == "solo" then
                NEURO.DEC_STATE()
                print("A hand was manually discarded in solo mode, this is not officially supported!")
                unregister_run_action()
                return
            end
            if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
                Context.send("These cards were discarded:\n" .. table.concat(played), true)
            end
            NEURO.DEC_STATE()
        end
    end
end

function ManualHooks.hook_win_blind()
    local orig = G.FUNCS.cash_out
    G.FUNCS.cash_out = function (e)
        e = e or {}
        orig(e)
        if NEURO.MODE == "coop" and not e.neuro then
            if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
                Context.send(GetRunText.get_round_info(), true)
            end
            NEURO.SET_STATE(NEURO.STATES.IN_SHOP)
        end
    end
end

function ManualHooks.hook_buy_card()
    local orig = G.FUNCS.buy_from_shop
    G.FUNCS.buy_from_shop = function (e)
        local ret = orig(e)
        local card = e.config.ref_table
        if not card then return end
        if not e.neuro then
            if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
                if e.config.id == 'buy_and_use' then
                    Context.send("Bought and used " .. GetRunText.get_card_description(card), true)
                else
                    Context.send("Bought " .. GetRunText.get_card_description(card), true)
                end
            end
            NEURO.DEC_STATE()
        end
        return ret
    end
end

function ManualHooks.hook_sell_card()
    local orig = G.FUNCS.sell_card
    G.FUNCS.sell_card = function (e)
        orig(e)
        if e.neuro then return end
        local card = e.config.ref_table
        if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
            Context.send("Sold " .. GetRunText.get_card_description(card), true)
        end
    end
end

function ManualHooks.hook_reroll_shop()
    local orig = G.FUNCS.reroll_shop
    G.FUNCS.reroll_shop = function (e)
        if e.neuro then return end
        if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
            Context.send("Rerolled shop for $" .. G.GAME.current_round.reroll_cost, true)
        end
        orig(e)
    end
end

local function on_consumable_use(card)
    if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
        Context.send("Using " .. GetRunText.get_card_description(card), true)
    end
    NEURO.DEC_STATE()
end

local function on_voucher_redeem(card)
    if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
        Context.send("Bought " .. GetRunText.get_card_description(card), true)
    end
    NEURO.DEC_STATE()
end


local function on_booster_open(card)
    if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
        Context.send("Opening " .. GetRunText.get_card_description(card, false, false, "Other"), true)
    end
end

local function on_booster_pick(card)
    if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
        if card.ability.consumeable then
            Context.send("Using " .. GetRunText.get_card_description(card), true)
        else
            Context.send("Taking " .. GetRunText.get_card_description(card), true)
        end
    end

    print(G.GAME.pack_choices)
    if (G.GAME.pack_choices or 1) > 1 then
        NEURO.DEC_STATE()
    else
        NEURO.INC_STATE()
    end
end

function ManualHooks.hook_use_card()
    local orig = G.FUNCS.use_card
    G.FUNCS.use_card = function (e)
        local card = e.config.ref_table
        if e.neuro then orig(e); return end
        if card.ability.consumeable and card.area ~= G.pack_cards then
            print('consumeable used')
            on_consumable_use(card)
        elseif card.ability.set == 'Voucher' then
            print('voucher redeemed')
            on_voucher_redeem(card)
        elseif card.ability.set == 'Booster' then
            print('booster opened')
            on_booster_open(card)
        elseif card.area == G.pack_cards then
            print('used booster card')
            on_booster_pick(card)
        end

        orig(e)
    end
end

function ManualHooks.hook_skip_booster()
    local orig = G.FUNCS.skip_booster
    G.FUNCS.skip_booster = function (e)
        orig(e)
        if e.neuro then return end
        if NEURO.CONFIG["COOP_MANUAL_ACTION_CONTEXT"] then
            Context.send("Skipping the current pack", true)
        end
        NEURO.INC_STATE()
    end
end

return ManualHooks