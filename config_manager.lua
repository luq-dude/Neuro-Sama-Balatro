local ConfigManager = {}
local default_cfg = ModCache.load("config.lua")
local status, user_cfg = pcall(ModCache.load, "_config.lua")
if not status then user_cfg = {}; print("Local user config not found.") end


function ConfigManager.get(key)
    if user_cfg[key] ~= nil then return user_cfg[key] end
    return default_cfg[key]
end

return ConfigManager