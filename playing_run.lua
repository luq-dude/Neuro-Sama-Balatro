local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local PlayCards = ModCache.load("custom-actions/play_cards.lua")
local PickCard = ModCache.load("custom-actions/pick_pack_card.lua")
local PickPackCard = ModCache.load("custom-actions/pick_hand_pack_cards.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local SkipPack = ModCache.load("custom-actions/skip_pack.lua")

local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")

local PlayingRun = {}

local function play_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PlayCards:new(window, nil))
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
            window:add_action(PickCard:new(window, nil))
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
            window:add_action(PickPackCard:new(window, nil))
            window:register()
            return true
        end
    }
    ))
end

-- use for tarot and spectral
local function skip_pack(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(SkipPack:new(window, {PickCard,PickPackCard}))
            window:register()
            return true
        end
    }
    ))
end


-- TODO: Stop spamming of running event / sending actions while it does get handled the fact it happens is still suboptimal (This only happens when hand is drawn as they are drawn one by one)
function PlayingRun:hook_draw_card()
    local original_draw_card = draw_card
    function draw_card(from, to, percent, dir, sort, card, delay, mute, stay_flipped, vol, discarded_only)
        original_draw_card(from, to, percent, dir, sort, card, delay, mute, stay_flipped, vol, discarded_only)

        sendDebugMessage("draw_card called")

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blocking = false,
            delay = 8,
            func = function ()
                    sendDebugMessage("start second event")
                    if G.STATE == nil or G.STATE == G.STATES.HAND_PLAYED or G.STATE == G.STATES.DRAW_TO_HAND or G.STATE == G.STATES.SHOP then
                        return true
                    end

                    if G.STATE == G.STATES.SELECTING_HAND then
                        play_card(14)
                        return true
                    end

                    local booster = SMODS.OPENED_BOOSTER
                    if booster == nil then
                        return true
                    end

                    if booster.config.center.draw_hand and G.STATE ~= G.STATES.SHOP then -- this is if cards from playing hand will be drawn
                        pick_hand_pack_card(20)
                        skip_pack(20)
                    else
                        pick_pack_card(20)
                        skip_pack(20)
                    end
                return true
            end
        }))
    end
    return true
end

return PlayingRun