local GameHooks = ModCache.load("game-sdk/game_hooks.lua")
local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")
local PlayCards = ModCache.load("custom-actions/play_cards.lua")
local PickCard = ModCache.load("custom-actions/pick_pack_card.lua")
local PickPackCard = ModCache.load("custom-actions/pick_hand_pack_cards.lua")
local GetRunText = ModCache.load("get_run_text.lua")
local SkipPack = ModCache.load("custom-actions/skip_pack.lua")

local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")

local PlayingRun = {}

PlayingRun.HookRan = false

local function play_card(delay)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay,
        blocking = false,
        func = function()
            local window = ActionWindow:new()
            window:add_action(PlayCards:new(window, {PlayingRun}))
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
                        sendDebugMessage("running smods")
                        tprint(booster.config)
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

return PlayingRun