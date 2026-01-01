local GetRunText = NEURO.MOD_CACHE.load("get_run_text.lua")

local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local PlayingRun = {}

function PlayingRun.hook_booster_open()
    local open = Card.open
    function Card:open()
        local is_booster = self.ability.set == "Booster"

        open(self)

        if is_booster then
            NEURO.STATE_INTERRUPT = NEURO.STATE
            NEURO.SET_STATE(NEURO.STATES.IN_BOOSTER_PACK)
        end
    end
end

function PlayingRun.hook_draw_to_hand()
    local deck_to_hand = Game.update_draw_to_hand
    function Game:update_draw_to_hand(dt)
        local complete = G.STATE_COMPLETE
        deck_to_hand(self, dt)
        if not complete and NEURO.STATE ~= NEURO.STATES.IN_BLIND then
            NEURO.SET_STATE(NEURO.STATES.IN_BLIND)
        end
    end
end

function PlayingRun:hook_evaluate_play()
    local eval = G.FUNCS.evaluate_play
    function G.FUNCS.evaluate_play(e)
        eval(e)
        NEURO.INC_STATE()
    end
end

function PlayingRun:hook_round_eval()
    local update_round = add_round_eval_row
    function add_round_eval_row(config)
        update_round(config)
        if config.name == "bottom" then -- bottom is the total
            NEURO.SET_STATE(NEURO.STATES.IN_BLIND, 10)
        end
    end
end

function PlayingRun:hook_new_round()
    local func = new_round
    function new_round()
        func()
        NEURO.PLAYED_BLINDS = NEURO.PLAYED_BLINDS + 1
        if NEURO.PLAYED_BLINDS >= NEURO.MAX_PLAYED_BLINDS then
            NEURO.PLAYED_BLINDS = 0
            Context.send(RunContext.get_all_modifier_desc() .. (#G.vouchers.cards > 0 and ("\n" .. "These are the vouchers you have gotten throughout this run " .. table.table_to_string(GetRunText.get_hand_details(G.vouchers.cards))) or ""), true)
        end
    end
end

return PlayingRun