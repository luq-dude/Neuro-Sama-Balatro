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
    CARD_INFO = {
        ADD_JOKER_CONSUMABLE_OVERWRITE = {},
        MODIFY_JOKER_CONSUMABLE_OVERWRITE = {}
    },
    -- round evaluation data 
    ROUND_EVAL = {},
    -- strings used for SDK action failures
    SDK_STRINGS = {},
    -- FSM
    STATES = {
        GAME_BOOT = 1,
        DECK_SELECTION = 2,
        BLIND_SELECTION = 3,
        IN_BLIND = 4,
        IN_SHOP = 5,
        IN_BOOSTER_PACK = 6,
        GAME_OVER = 7
    },
    STATE = 1,
    STATE_STATUS = 0
}