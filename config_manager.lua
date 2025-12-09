local ConfigManager = {}
local default_cfg = NEURO.MOD_CACHE.load("config.lua")
local status, user_cfg = pcall(NEURO.MOD_CACHE.load, "_config.lua")
if not status then user_cfg = {}; print("Local user config not found.") end


function ConfigManager.get(key)
    if user_cfg[key] ~= nil then return user_cfg[key] end
    return default_cfg[key]
end

function ConfigManager.get_tbl()
    local cfg = {}
    for k, v in pairs(default_cfg) do
        if user_cfg[k] ~= nil then
            cfg[k] = user_cfg[k]
        else
            cfg[k] = default_cfg[k]
        end
    end
    return cfg
end

return ConfigManager