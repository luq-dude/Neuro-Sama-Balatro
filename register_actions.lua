local SoloMode = NEURO.MOD_CACHE.load("modes/solo.lua")
local Context = NEURO.MOD_CACHE.load("game-sdk/messages/outgoing/context.lua")
local RunContext = NEURO.MOD_CACHE.load("run_context.lua")

local RegisterActions = {}


local prev_state = -1
local prev_progress = -1
function RegisterActions.update()
    if prev_state ~= NEURO.STATE or prev_progress ~= NEURO.STATE_STATUS then
        print(string.format("Current state: %d (%d)", NEURO.STATE, NEURO.STATE_STATUS))
    end
    local mode
    if NEURO.MODE == "solo" then
        mode = SoloMode:new()
    elseif NEURO.MODE == "coop" then
        -- not implemented
    end
    local ret
    if mode then
        if NEURO.STATE == NEURO.STATES.GAME_BOOT then
            -- universal across all modes
            RegisterActions.game_boot()
        elseif NEURO.STATE == NEURO.STATES.MAIN_MENU then
            ret = mode:main_menu()
        elseif NEURO.STATE == NEURO.STATES.DECK_SELECTION then
            ret = mode:deck_selection()
        elseif NEURO.STATE == NEURO.STATES.BLIND_SELECTION then
            ret = mode:select_blind()
        elseif NEURO.STATE == NEURO.STATES.IN_BLIND then
            ret = mode:in_blind()
        elseif NEURO.STATE == NEURO.STATES.IN_SHOP then
            ret = mode:in_shop()
        elseif NEURO.STATE == NEURO.STATES.IN_BOOSTER_PACK then
            ret = mode:in_booster_pack()
        elseif NEURO.STATE == NEURO.STATES.GAME_OVER then
            ret = mode:game_over()
        end
    end
    -- cant do if not ret, have to do explicit false check 
    if ret == false and (prev_state ~= NEURO.STATE or prev_progress ~= NEURO.STATE_STATUS) then
        sendErrorMessage(string.format("No function found for state %d", NEURO.STATE))
    end
    prev_state = NEURO.STATE
    prev_progress = NEURO.STATE_STATUS
end

function RegisterActions.game_boot()
    if NEURO.STATE_STATUS == 0 then
        Context.send(RunContext.get_boot_text())
        Context.send(RunContext.get_all_modifier_desc())
        NEURO.INC_STATE()
    end
end

return RegisterActions