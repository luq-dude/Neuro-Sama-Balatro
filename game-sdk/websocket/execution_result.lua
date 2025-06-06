-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local ExecutionResult = {}
ExecutionResult.__index = ExecutionResult

function ExecutionResult:new(successful, message)
    local obj = setmetatable({
        successful = successful or false,
        message = message or ""
    }, self)
    return obj
end

function ExecutionResult.success(message)
    return ExecutionResult:new(true, message)
end

function ExecutionResult.failure(message)
    return ExecutionResult:new(false, message)
end

function ExecutionResult.vedal_failure(message)
    return ExecutionResult.failure(message .. SDK_Strings.action_failed_vedal_fault_suffix)
end

function ExecutionResult.mod_failure(message)
    return ExecutionResult.failure(message .. SDK_Strings.action_failed_mod_fault_suffix)
end

return ExecutionResult