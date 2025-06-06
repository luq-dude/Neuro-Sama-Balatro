-- Originally from: https://github.com/Gunoshozo/lua-neuro-sama-game-api
-- Licensed under the MIT License. See third_party_licenses/lua-neuro-sama-game-api-LICENSE

-- Modified by LuqDude

local CommandHandler = {}
CommandHandler.__index = CommandHandler

function CommandHandler:new()
    local obj = setmetatable({
        handlers = {}
    }, self)
    return obj
end

function CommandHandler:register(module)
    table.insert(self.handlers, module:new())
end

function CommandHandler:handle(command, data)
    for _, handler in ipairs(self.handlers)
    do
        if handler:can_handle(command) then
            local state = {}
            local validation_result = handler:validate(command, data, state)
            if not validation_result.successful then
                print("Received unsuccessful execution result when handling a message")
                print(validation_result.message)
            end
            handler:report_result(state, validation_result)

            if validation_result.successful then
                handler:execute(state)
            end
        end
    end
end

return CommandHandler