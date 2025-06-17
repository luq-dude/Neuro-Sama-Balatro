local NeuroAction = ModCache.load("game-sdk/actions/neuro_action.lua")
local ExecutionResult = ModCache.load("game-sdk/websocket/execution_result.lua")

local JsonUtils = ModCache.load("game-sdk/utils/json_utils.lua")

local PlayCards = setmetatable({}, { __index = NeuroAction })
PlayCards.__index = PlayCards

function PlayCards:new(actionWindow, state)
    local obj = NeuroAction.new(self, actionWindow)
    return obj
end

function PlayCards:_get_name()
    return "play_cards"
end

function PlayCards:_get_description()
    local description = "play a maximum of 5 cards with your current hand."

    return description
end

function PlayCards:_get_schema()
    return JsonUtils.wrap_schema({
        hand = {
			type = "array",
            items = {
				type = "string",
				enum = self:_get_hand()
			},
		}
    })
end

function PlayCards:_validate_action(data, state)
    local selected_hand = data:get_object("hand")
    selected_hand = selected_hand._data  -- get_object returns incoming data instead of the object :)

    -- sendErrorMessage(selected_hand) -- issue here?

    for key, value in pairs(selected_hand) do
        sendDebugMessage("table k/v: " .. key .. " , " .. value)
    end

    if not selected_hand then
        return ExecutionResult.failure(SDK_Strings.action_failed_missing_required_parameter("hand"))
    end

	sendInfoMessage("Length of table: " .. #selected_hand) -- TODO: selected hand is always 0 idk why

    if #selected_hand == 0 then return ExecutionResult.failure("At least one card must be selected.") end

    if #selected_hand > 5 then return ExecutionResult.failure("Cannot play more than 5 cards.") end

	local hand = self:_get_hand() -- check hand to see if has selected more than are available
    local selected_amount = {}
    local hand_amount = {}

    -- check if card exist
	for _, selected_card in pairs(selected_hand) do
        if not table.any(hand, function(hand_card)
                return hand_card == selected_card
            end) then
            return ExecutionResult.failure(SDK_Strings.action_failed_invalid_parameter(selected_card .. " is not in your hand."))
        end
    end

    --TODO: dont repeate this code as much

    -- add one for each card that is in the hand
    for _, card in pairs(hand) do
        if hand_amount[card] == nil then
            sendDebugMessage("setting " .. card .. "to 1 on hand")
            hand_amount[card] = 1
        else
            sendDebugMessage("adding 1 to " .. card .. " on hand")
            hand_amount[card] = hand_amount[card] + 1 -- should increment for each type of card in hand
        end
    end

    -- add one for each card that is in the selected hand
    for _, card in pairs(selected_hand) do
        if selected_amount[card] == nil then
            sendDebugMessage("setting " .. card .. "to 1")
            selected_amount[card] = 1
        else
            sendDebugMessage("adding 1 to " .. card)
            selected_amount[card] = selected_amount[card] + 1 -- should increment for each type of card in hand
        end
    end

    -- get if trying to play more cards than in hand
    for _, card in pairs(selected_hand) do
        if selected_amount[card] > hand_amount[card] then
            return ExecutionResult.failure("You can only use the cards given in the hand. You tried to play more " .. card .. "'s when those do not exist")
        else
            sendDebugMessage("lowering " .. card .. "by 1")
            selected_amount[card] = selected_amount[card] - 1
        end
    end

    state["hand"] = selected_hand
    return ExecutionResult.success()
end

-- id play card button: "play_button"
function PlayCards:_execute_action(state)
    sendDebugMessage("running PlayCards execute")
    local selected_hand = state["hand"]

    sendDebugMessage("G.deck" .. tostring(G.play.cards))
    sendDebugMessage(tostring(selected_hand))

    for key, value in pairs(G.hand.highlighted) do
        sendDebugMessage("first key: " .. tostring(key) .. " value: " .. tostring(value))
    end


    local play_button = G.buttons:get_UIE_by_ID('play_button')
    local hand_string = self:_get_hand()
    local hand = G.hand.cards
    for location, card in pairs(selected_hand) do -- TODO: find way too include position of card in hand as right now it will do card 1-5
        for index = 1, #hand_string, 1  do
            if card == hand_string[index] then
                G.hand:add_to_highlighted(hand[index])
                -- send_hand[#send_hand + 1] = hand[index]
            end
        end
    end

    for key, value in pairs(G.hand.highlighted) do
        sendDebugMessage("key: " .. tostring(key) .. " value: " .. tostring(value))
    end

    -- shouldn't cause any issues with mods
    G.FUNCS.play_cards_from_highlighted() -- try

    -- couldn't get this to work and I hate ui so function call is good enough for now
    -- play_button:click() -- play_cards_from_highlighted
    -- G.buttons:get_UIE_by_ID('play_button'):release()

	return true
end

 -- foil var localize: G.P_CENTERS.e_foil.config.extra
local function get_edition_args(name,card_config)
    sendDebugMessage(tprint(card_config,1,2))
    local loc_args = {}
    if name == "foil" then loc_args = {card_config.config.extra} end -- returns 50 as foil adds 50 chips
    -- if name == "foil" then loc_args = {localize{type = 'name_text', key = 'e_foil', set='G.P_CENTERS.e_foil.config.extra'}} end
    return loc_args
end

function PlayCards:_get_hand() -- G.hand.cards  G.play.cards
	local cards = {}
	for pos, card in ipairs(G.hand.cards) do -- Can get editions with card.edition / enhancements with card.ability / seal with card.seal

        local name = card.base.name

        sendDebugMessage("card edition " .. tostring(card.config))

        if card.edition then
            local key_override
            for _, v in pairs(G.P_CENTER_POOLS.Edition) do
                local loc_args,loc_nodes = get_edition_args(card.edition.type,G.P_CENTERS[v.key]), {} -- idk why G.P_CENTERS contains the extra's details but it works
                sendDebugMessage("original_key: " .. tostring(v.original_key) .. " edition type: " .. tostring(card.edition.type))
                sendDebugMessage(tprint(v,1,2))
                sendDebugMessage("v: " .. tostring(v) .. " v type " .. type(v))
                if v.original_key ~= card.edition.type then goto continue end
                if v.loc_vars and type(v.loc_vars) == 'function' then
                    -- local res = v:loc_vars() or {}
                    loc_args = v.vars or loc_args
                    key_override = v.key
                    sendDebugMessage("key: " .. v.key .. " vars " .. tprint(loc_args,1,2))
                    -- sendDebugMessage("loc_vars: " .. v:loc_vars())

                    localize{type = "descriptions", set = 'Edition',key= key_override or card.key, nodes = loc_nodes, vars = loc_args}
                    sendDebugMessage("loc_vars " .. tostring(card.loc_vars) .. " type " .. type(card.loc_vars))
                    -- sendDebugMessage("override " .. key_override)

                    sendDebugMessage("loc_args " .. tostring(loc_args[1]) .. " loc_nodes " .. tostring(loc_nodes[1]))

                    local description = ""
                    sendDebugMessage("before loc_nodes for " .. tostring(table.get_keys(loc_nodes)))
                    for _, line in ipairs(loc_nodes) do
                        for _, v in ipairs(line) do
                            sendDebugMessage("Text: " .. v.config.text)
                            description = description .. v.config.text
                        end
                        description = description
                    end

                    name = name .. description
                end
            ::continue::
            end

        -- for _, desc in pairs(G.P_CENTERS.e_foil) do
        --     if desc.loc_vars and type(desc.loc_vars) == 'function' then
        --         local res = desc:loc_vars() or {}
        --         loc_args = res.vars or {}
        --         key_override = res.key
        --     end
        -- end


        --TODO: change this to get from localize like select_deck

        -- if card.ability.name == "Bonus Card" then
        --     name = name .. " Enhancement: Bonus Card: +30 chips"
        -- elseif card.ability.name == "Mult Card" then
        --     name = name .. " Enhancement: Bonus Card: 	+4 Mult"
        -- end

        -- if edition == nil then
        --     goto continue
        -- end

        -- -- this should probably be changed for modding support but good enough for vanilla
        -- if card.edition.foil then
        --     name = name .. " edition: Foil: +50 chips when scored."
        -- elseif card.edition.holo then
        --     name = name .. " edition: Holographic: +10 Mult when scored."
        -- elseif card.edition.polychrome then
        --     name = name .. " edition: Polychrome: X1.5 Mult when scored."
        -- elseif card.edition == nil then
        --     name = name
        -- end
        -- elseif card.edition.negative then -- this is unused in vanilla (according to the wiki)
        --     name = " edition: Negative: +1 hand size"

		cards[#cards+1] = name -- this will give to neuro as "{value} of {suit}"
        end
    end
    return cards
end

-- self.edition
-- chips: integer = 50,
-- foil: boolean = true,
-- holo: boolean = true,
-- mult: integer = 10,
-- negative: boolean = true,
-- polychrome: boolean = true,
-- type: string = 'foil'|'holo'|'negative'|'polychrome',
-- x_mult: number = 1.5,

-- self.ability

-- bonus: integer,
-- burnt_hand: integer = 0,
-- caino_xmult: integer = 1,
-- consumeable: unknown,
-- d_size: integer = 0,
-- effect: unknown,
-- extra: table,
-- extra_value: integer = 0,
-- forced_selection: nil,
-- h_dollars: integer = 0,
-- h_mult: integer = 0,
-- h_size: integer = 0,
-- h_x_mult: integer = 0,
-- hands_played_at_create: integer = 0|1,
-- invis_rounds: integer = 0,
-- loyalty_remaining: unknown,
-- mult: integer = 0,
-- name: unknown,
-- order: nil,
-- p_dollars: integer = 0,
-- perma_bonus: integer = 0,
-- set: unknown,
-- t_chips: integer = 0,
-- t_mult: integer = 0,
-- to_do_poker_hand: unknown,
-- type: string = '',
-- x_mult: integer = 1,
-- yorick_discards: unknown,


return PlayCards