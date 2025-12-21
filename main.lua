assert(SMODS.load_file("globals.lua"))()

assert(SMODS.load_file("game-sdk/utils/table_utils.lua"))()

assert(SMODS.load_file("game-sdk/sdk_string_consts.lua"))()

assert(SMODS.load_file("modifier_loc.lua"))()
assert(SMODS.load_file("consumable_validation.lua"))()
assert(SMODS.load_file("deck_loc.lua"))()

NEURO.MOD_CACHE = assert(SMODS.load_file("module_cache.lua"))()
local config_mgr = NEURO.MOD_CACHE.load("config_manager.lua")
NEURO.CONFIG = config_mgr.get_tbl()
NEURO.MODE = NEURO.CONFIG["DEFAULT_MODE"]

-- unlike require(), SMODS.load_file() doesn't guarantee files will only get loaded once
-- use NEURO.MOD_CACHE.load() to get them loaded once
-- theres definitely a way to get the sdk working with SMODS.load_file, but the entire sdk was written for require()
-- and i wanted to do minimal changes to get it all working
local Hook = NEURO.MOD_CACHE.load("hook.lua")
Hook.hook_game()

SMODS.Keybind{
    key_pressed = NEURO.CONFIG["SOLO_MODE_KEYBIND"],
    action = function(self)
        if not NEURO.CAN_SWITCH_MODES then return end
        print("solo")
        NEURO.MODE = "solo"
    end
}

SMODS.Keybind{
    key_pressed = NEURO.CONFIG["COOP_MODE_KEYBIND"],
    action = function(self)
        if not NEURO.CAN_SWITCH_MODES then return end
        print("coop")
        NEURO.MODE = "coop"
    end
}
