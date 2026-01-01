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
    ManualHooks.hook_reroll_blind()
    ManualHooks.hook_win_blind()
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

return ManualHooks