NEURO.CONSUMABLE_OVERRIDES["c_aura"] = {min_highlighted = 1, max_highlighted = 1}
NEURO.CONSUMABLE_OVERRIDES["c_wraith"] = {jokers_created = 1}
NEURO.CONSUMABLE_OVERRIDES["c_soul"] = {jokers_created = 1}
NEURO.CONSUMABLE_OVERRIDES["c_judgement"] = {jokers_created = 1}
NEURO.CONSUMABLE_OVERRIDES["c_hex"] = {jokers_required = true}
NEURO.CONSUMABLE_OVERRIDES["c_ectoplasm"] = {jokers_required = true}
NEURO.CONSUMABLE_OVERRIDES["c_wheel_of_fortune"] = {jokers_required = true}
NEURO.CONSUMABLE_OVERRIDES["c_ankh"] = {jokers_created = 1, jokers_required = true}
-- below are all spectral cards that modify the entire hand
NEURO.CONSUMABLE_OVERRIDES["c_familiar"] = {require_hand = true}
NEURO.CONSUMABLE_OVERRIDES["c_grim"] = {require_hand = true}
NEURO.CONSUMABLE_OVERRIDES["c_incantation"] = {require_hand = true}
NEURO.CONSUMABLE_OVERRIDES["c_immolate"] = {require_hand = true}
NEURO.CONSUMABLE_OVERRIDES["c_sigil"] = {require_hand = true}
NEURO.CONSUMABLE_OVERRIDES["c_ouija"] = {require_hand = true}


NEURO.DESELECT_AFTER_USE = {c_aura = true, c_cryptid = true}

-- check if weve selected a valid number of cards
NEURO.CONSUMABLE_VALIDATE_FUNCS[#NEURO.CONSUMABLE_VALIDATE_FUNCS + 1] = function (args)
	local card = args.card
	local config = card.config.center.config
	local selected = args.selected or {}
	local max_highlighted = args.max_highlighted or config.max_highlighted
	local min_highlighted = args.min_highlighted or config.min_highlighted
	local require_hand = args.require_hand
	if max_highlighted == nil and #selected > 0 then
		return false, "This consumable does not require any cards to be selected"
	end
	if max_highlighted ~= nil then
		if G.STATE == G.STATES.SHOP then
			return false, "This consumable requires cards to be selected, " ..
							"and thus cannot be used in shop"
		end
		if not G.hand or #G.hand.cards == 0 then
			return false, "This consumable requires cards in hand to be selected, " ..
							"and thus cannot be used currently"
		end
		if #selected > max_highlighted then
			return false, string.format("You have selected too many cards. " ..
										"This consumable requires a max of %d cards selected",
										max_highlighted)
		end
		if #selected == 0 then
			return false, "This consumable requires cards to be selected as a target"
		end
	end
	if min_highlighted ~= nil then
		if G.GAME.STATE == G.STATES.SHOP then
			return false, "This consumable requires cards to be selected, " .. 
							"and thus cannot be used in shop"
		end
		if #selected < min_highlighted then
			return false, string.format("You have not selected enough cards. " .. 
										"This consumable requires you select a minimum of %d cards",
										min_highlighted)
		end
	end
	if require_hand then
		if not G.hand or #G.hand.cards == 0 then
			return false, "This consumeable requires a hand to be drawn, " ..
							"so it cannot be currently used"
		end
	end
	return true
end

-- check if we havent selected any forced cards
NEURO.CONSUMABLE_VALIDATE_FUNCS[#NEURO.CONSUMABLE_VALIDATE_FUNCS + 1] = function (args)
	local selected = args.selected or {}
	if #selected ~= 0 then
        for k, v in ipairs(G.hand.cards) do
            if v.ability.forced_selection then
                if not table.any(selected, function (check) return check == k end) then
                    return false, "Cards in hand that are forced must be selected"
                end
            end
        end
    end
	return true
end

-- check if we have enough space in the consumable inventory
NEURO.CONSUMABLE_VALIDATE_FUNCS[#NEURO.CONSUMABLE_VALIDATE_FUNCS + 1] = function (args)
	local card = args.card
	local consumables_created = args.consumables_created
	if not consumables_created then
		consumables_created = 0
		for card_type, amount in pairs(card.ability.consumeable or {}) do
            if card_type == "spectrals" or card_type == "planets" or card_type == "tarots" then
                consumables_created = consumables_created + amount
			end
        end
	end
	if consumables_created > 0 then
		local free_space = G.consumeables.config.card_limit - #G.consumeables.cards
		if card.area ~= G.pack_cards then free_space = free_space + 1 end
		if free_space <= 0 then
            return false, "You do not have any space in your consumable inventory to use this"
        elseif free_space >= consumables_created then
            return true
        else
            return true, string.format("Only creating %d cards since your inventory is now full",
										consumables_created - free_space)
        end
	end
	return true
end

-- check if we have enough space in the joker inventory
NEURO.CONSUMABLE_VALIDATE_FUNCS[#NEURO.CONSUMABLE_VALIDATE_FUNCS + 1] = function (args)
	local jokers_created = args.jokers_created or 0
	if jokers_created > 0 then
		if #G.jokers.cards + jokers_created > G.jokers.config.card_limit then
			return false, "You do not have any space in your joker inventory to use this"
		end
	end
	return true
end

-- check if we have a valid joker 
NEURO.CONSUMABLE_VALIDATE_FUNCS[#NEURO.CONSUMABLE_VALIDATE_FUNCS+1] = function (args)
	local jokers_required = args.jokers_required or false
	if jokers_required and #G.jokers.cards == 0 then
		return false, "This consumable requires a joker to use"
	end
	return true
end

-- check c_aura
NEURO.CONSUMABLE_VALIDATE_FUNCS[#NEURO.CONSUMABLE_VALIDATE_FUNCS+1] = function (args)
	local card = args.card
	local selected = args.selected
	if card.config.center_key == "c_aura" then
		if G.hand.cards[selected[1]].edition then
			return false, "Cannot use Aura on a card that already has an edition"
		end
	end
	return true
end

-- check c_fool
NEURO.CONSUMABLE_VALIDATE_FUNCS[#NEURO.CONSUMABLE_VALIDATE_FUNCS+1] = function (args)
	local card = args.card
	if card.config.center_key == "c_fool" then
		if G.GAME.last_tarot_planet == nil or G.GAME.last_tarot_planet == 'c_fool' then
			return false, "You cannot use The Fool right now, as you have either not played " ..
							"a tarot card yet, or your last played tarot card was also The Fool"
		end
	end
	return true
end

-- check c_ectoplasm
NEURO.CONSUMABLE_VALIDATE_FUNCS[#NEURO.CONSUMABLE_VALIDATE_FUNCS+1] = function (args)
	local card = args.card
	if card.config.center_key == "c_ectoplasm" then
		for _, v in ipairs(G.jokers.cards) do
			if not v.edition then
				return true
			end
		end
		return false, "Ectoplasm requires a joker that does not already have an edition"
	end
	return true
end

-- check c_hex
NEURO.CONSUMABLE_VALIDATE_FUNCS[#NEURO.CONSUMABLE_VALIDATE_FUNCS+1] = function (args)
	local card = args.card
	if card.config.center_key == "c_hex" then
		for _, v in ipairs(G.jokers.cards) do
			if not v.edition then
				return true
			end
		end
		return false, "Hex requires a joker that does not already have an edition"
	end
	return true
end