local ActionWindow = ModCache.load("game-sdk/actions/action_window.lua")

local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")
local Context = ModCache.load("game-sdk/messages/outgoing/context.lua")
local RunHelper = ModCache.load("run_functions_helper.lua")
local UseHandCards = ModCache.load("custom-actions/use_hand_cards.lua")
local PickHandPackCards = ModCache.load("custom-actions/pick_hand_pack_cards.lua")

local NeuroActionHandler = ModCache.load("game-sdk/actions/neuro_action_handler.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local UseConsumable = setmetatable({}, { __index = NeuroAction })
UseConsumable.__index = UseConsumable

function UseConsumable:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    obj.hook = state[1]
    obj.actions = state[2]
    obj.joker = state[3]
    return obj
end

function UseConsumable:_get_name()
    return "use_consumeable"
end

function UseConsumable:_get_description()
    local cards = {}
    for index, value in ipairs(G.consumeables.cards) do
        table.insert(cards,"\n" .. tostring(index) .. ": " .. value.config.center.name .. " sell value: " .. value.sell_cost)
    end

    local description = string.format("Use a consumable in your consumable hand. This can either be planet, spectral or tarot cards," ..
    " Each type will affect the game in it's own unique way" ..
    table.concat(cards,"",1,#cards))

    return description
end

local function get_card_actions()
	return {"Use","Sell"}
end

function UseConsumable:_get_schema()
    local hand_length = RunHelper:get_hand_length(G.hand.cards)
    local pack_hand_length = RunHelper:get_hand_length(G.consumeables.cards)

    local schema = {
		card_action = {
			enum = get_card_actions()
		},
		consumable_index = {
			enum = pack_hand_length
		}
	}

    if #hand_length ~= 0 then -- else will not work in shops
        schema["cards_index"] = { -- when adding context messages, make sure neuro knows to send an empty array if she wants to highlight no cards
            type = "array",
            items ={
                type = "integer",
                enum = hand_length
            }
        }
    end
    return JsonUtils.wrap_schema(schema)
end

function UseConsumable:_validate_action(data, state)
	local selected_action = data:get_string("card_action")
	local selected_consumable = data._data["consumable_index"]
    local selected_hand_index = data:get_object("cards_index")
    selected_hand_index = selected_hand_index._data

    local indexs = RunHelper:get_hand_length(G.consumeables.cards)
    if not table.any(indexs, function(options) -- check Neuro doesn't send a invalid index
            return options == selected_consumable
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("consumable_index"))
    end

    local card_config = G.consumeables.cards[tonumber(selected_consumable)].config.center.config

	if not selected_consumable then
		return ExecutionResult.failure("issue with selected_consumable")
	end

	if not selected_action then
		return ExecutionResult.failure("issue with selected_consumable")
	end

    local option = get_card_actions()
    if not table.any(option, function(options)
            return options == selected_action
        end) then
        return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter("card_action"))
    end

    local valid_hand_indices = RunHelper:get_hand_length(G.hand.cards)
    for _, value in ipairs(selected_hand_index) do
        if not RunHelper:value_in_table(valid_hand_indices, value) then
            return ExecutionResult.failure("Selected card index " .. tostring(value) .. " is not valid.")
        end
    end

    if RunHelper:check_for_duplicates(selected_hand_index) == false then
        return ExecutionResult.failure("You cannot select the same card index more than once.")
    end

    if G.STATE == G.STATES.SHOP and card_config.max_highlighted ~= nil then
        return ExecutionResult.failure("You cannot use this card in the shop as selecting cards is needed for it to work.")
    end

    if #selected_hand_index > G.hand.config.highlighted_limit then return ExecutionResult.failure("You can only highlight a max of " .. G.hand.config.highlighted_limit .. "card per action.") end

    if #selected_hand_index > 0 and card_config.max_highlighted == nil then return ExecutionResult.failure("The card you selected does not require cards to be highlighted") end

    if card_config.max_highlighted ~= nil then
        if #selected_hand_index ~= card_config.max_highlighted and selected_action == "Use" then return ExecutionResult.failure("You have either selected too many cards or to little from your hand comparative to how many the tarot needs.") end
    end

	state["card_action"] = selected_action
	state["consumable_index"] = selected_consumable
    state["cards_index"] = selected_hand_index
	return ExecutionResult.success()
end

function UseConsumable:_execute_action(state)
    local selected_index = state["cards_index"]
	local selected_consumable = state["consumable_index"]
	local selected_action = state["card_action"]

    local hand = G.hand.cards
	local consumable_hand = G.consumeables.cards

	for pos, card in ipairs(consumable_hand) do
		sendDebugMessage("for pos: " .. pos .. "  selected_consumable: " .. selected_consumable)
		if pos == selected_consumable then
			G.consumeables:add_to_highlighted(card)
			local use_button_child = card.children.use_button.UIRoot.children[1]
			local button = nil
            for _, children in ipairs(use_button_child.children) do -- one of the children is the use button the other is sell
                if selected_action == "Use" then
                    if children.children[1].children[1].config.button == "use_card" or children.children[1].children[1].config.button == nil then -- or is needed if the cards need to be selected before the button will be able to be clicked
                        local highlighted_cards = {}
                        for _, value in ipairs(selected_index) do
                            highlighted_cards[#highlighted_cards+1] = G.hand.cards[value]
                        end

                        for index, highlight_card in ipairs(highlighted_cards) do
                            highlight_card.states.drag.is = true

                            highlight_card.T.x = G.hand.cards[index].T.x - 0.5

                            G.E_MANAGER:add_event(Event({
                                trigger = "after",
                                delay = 0.25 * G.SPEEDFACTOR,
                                blocking = false,
                                func = function ()
                                    highlight_card.states.drag.is = false
                                    return true
                                end
                            }))
                        end

                        G.E_MANAGER:add_event(Event({
                                trigger = "after",
                                delay = 0.4 * G.SPEEDFACTOR,
                                blocking = false,
                                func = function ()
                                    for index, _ in ipairs(selected_index) do
                                        G.hand:add_to_highlighted(hand[index])
                                    end
                                    return true
                                end
                            }))

                        button = children.children[1].children[1]
                        break
                    else
                    end
                elseif selected_action == "Sell" then
                    if children.children[1].children[1].config.button == "sell_card" then
                        button = children.children[1].children[1]
                        break
                    else
                    end
                end
            end
			if button == nil then
				sendErrorMessage("None of the cards have a valid use button: ")
				self.hook.HookRan = false
				return true
			end
            local delay = 0.25
            if #selected_index > 0 then delay = #selected_index + 0.5 end -- chuck an extra 0.5 on there for fun
            G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = delay * G.SPEEDFACTOR, -- else tarot's that need a card to be selected wont work. The delay does not need to be this high but lower can look a bit jank
            blocking = false,
            func = function()
                button:click()
                return true
            end}))
		end
	end

    local delay = 1
    if #selected_action > 1 then delay = #selected_action + 2 end
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay * G.SPEEDFACTOR,
        blocking = false,
        func = function()
            G.FUNCS.sort_hand_value({}) -- too lazy to set the position of cards back myself so we do this
            local window = ActionWindow:new()
            for index, action in ipairs(self.actions) do
                window:add_action(action:new(window, {self.hook}))
                if action == UseHandCards or action == PickHandPackCards then
                    self.hook:get_cards_context(G.hand.cards)
                end
            end

            if #G.jokers.cards > 0 then
                window:add_action(self.joker:new(window, {self.hook,self.actions,UseConsumable}))
            end

            if #G.consumeables.cards > 0 then
                window:add_action(UseConsumable:new(window, {self.hook,self.actions,self.joker}))
            end
            window:register()
            return true
        end}))
	return true
end


return UseConsumable