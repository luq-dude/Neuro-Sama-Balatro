assert(SMODS.load_file("globals.lua"))()

assert(SMODS.load_file("game-sdk/utils/table_utils.lua"))()

assert(SMODS.load_file("game-sdk/sdk_string_consts.lua"))()

assert(SMODS.load_file("modifier_loc.lua"))()
assert(SMODS.load_file("card_info.lua"))()
assert(SMODS.load_file("deck_loc.lua"))()

NEURO.MOD_CACHE = assert(SMODS.load_file("module_cache.lua"))()
local config_mgr = NEURO.MOD_CACHE.load("config_manager.lua")
NEURO.CONFIG = config_mgr.get_tbl()

-- unlike require(), SMODS.load_file() doesn't guarantee files will only get loaded once
-- use NEURO.MOD_CACHE.load() to get them loaded once
-- theres definitely a way to get the sdk working with SMODS.load_file, but the entire sdk was written for require()
-- and i wanted to do minimal changes to get it all working
local Hook = NEURO.MOD_CACHE.load("hook.lua")
Hook.hook_game()