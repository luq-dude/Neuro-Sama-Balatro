local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local SelectDeck = setmetatable({}, { __index = NeuroAction })
SelectDeck.__index = SelectDeck

function SelectDeck:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function SelectDeck:_get_name()
    return "select_deck"
end

function SelectDeck:_get_description()
    return "Select a deck to start the game with."
end

function SelectDeck:_get_schema()
    return JsonUtils.wrap_schema({
        deck = {
            enum = self:_get_decks()
        }
    })
end

function SelectDeck:_validate_action(data, state)
    local cell = data:get_string("deck")
    if not cell then
        return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("deck"))
    end

    local cells = self:_get_decks()
    if not table.any(cells, function(free_cell)
            return free_cell == cell
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("deck"))
    end
    return ExecutionResult.success()
end

function SelectDeck:_execute_action(state)
    --TODO: select the deck here
end


function SelectDeck:_get_decks()
    -- TODO: get all deck options.
    return {"Red Deck", "Yellow Deck"}
end

return SelectDeck