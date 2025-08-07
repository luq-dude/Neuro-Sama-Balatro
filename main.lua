assert(SMODS.load_file("game-sdk/utils/table_utils.lua"))()

assert(SMODS.load_file("game-sdk/sdk_string_consts.lua"))()

assert(SMODS.load_file("modifier_loc.lua"))()
assert(SMODS.load_file("card_loc.lua"))()
assert(SMODS.load_file("voucher_loc.lua"))()
assert(SMODS.load_file("deck_loc.lua"))()


ModCache = assert(SMODS.load_file("module_cache.lua"))()
NeuroConfig = ModCache.load("config.lua")

-- unlike require(), SMODS.load_file() doesn't guarantee files will only get loaded once
-- use ModCache.load() to get them loaded once
-- theres definitely a way to get the sdk working with SMODS.load_file, but the entire sdk was written for require()
-- and i wanted to do minimal changes to get it all working
local Hook = ModCache.load("hook.lua")



Hook.hook_game()