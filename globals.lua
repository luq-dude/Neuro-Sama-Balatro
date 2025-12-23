NEURO = {
    -- table with all the config values, with _config.lua taking priority over config.lua
    CONFIG = {},
    -- cache for lua modules
    MOD_CACHE = {},
    -- # of played blinds since we last sent voucher/modifier context 
    PLAYED_BLINDS = 0,
    -- how many blinds we should have before sending voucher/modifier context
    MAX_PLAYED_BLINDS = 0,
    -- localization lookup tables
    LOCS = {
        EDITION = {},
        ENHANCEMENT = {},
        SEAL = {},
        BACK = {},
        STAKE = {}
    },
    -- whether or not we can restart after a crash
    CAN_RESTART = false,
    -- additional card info
    CONSUMABLE_VALIDATE_FUNCS = {},
    CONSUMABLE_OVERRIDES = {},
    DESELECT_AFTER_USE = {},
    -- round evaluation data 
    ROUND_EVAL = {},
    -- strings used for SDK action failures
    SDK_STRINGS = {},
    -- FSM
    STATES = {
        GAME_BOOT = 1,
        MAIN_MENU = 2,
        DECK_SELECTION = 3,
        BLIND_SELECTION = 4,
        IN_BLIND = 5,
        IN_SHOP = 6,
        IN_BOOSTER_PACK = 7,
        GAME_OVER = 8
    },
    STATE = 1,
    STATE_STATUS = 0,
    -- stores the previous state whenever booster packs interrupt the current state
    STATE_INTERRUPT = nil,
    -- either "solo" or "coop"
    MODE = "solo",
    CAN_SWITCH_MODES = true,
    INC_STATE = function (amt)
        amt = amt or 1
        NEURO.STATE_STATUS = NEURO.STATE_STATUS + amt
    end,
    DEC_STATE = function (amt)
        amt = amt or 1
        NEURO.STATE_STATUS = NEURO.STATE_STATUS - amt
    end,
    SET_STATE = function (state, progress)
        if state then NEURO.STATE = state end
        NEURO.STATE_STATUS = progress or 0
    end
}