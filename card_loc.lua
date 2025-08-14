Spectral_Loc = {
	c_familiar = { "extra" },
	c_grim = {"extra"},
	c_incantation = { "extra"},
	c_talisman = { "extra", "max_highlighted"},
	c_aura = {},
	c_wraith = {},
	c_sigil = {},
	c_ouija = {},
	c_ectoplasm = {},
	c_immolate = function (card)
		return {"5", "20"} -- these are from extra as it is a table
	end,
	c_ankh = {"extra"},
	c_deja_vu = {"extra", "max_highlighted"},
	c_hex = {"extra"},
	c_trance = {"extra","max_highlighted"},
	c_medium = {"extra", "max_highlighted"},
	c_cryptid = {"extra", "max_highlighted"},
	c_soul = {},
	c_black_hole = {},
}

Tarot_Loc = {
	c_fool = {},
	c_magician = function (card)
		return {card.config.center.config.max_highlighted,"Lucky Card"}
	end,
	c_high_priestess = {"planets"},
	c_empress = function (card)
		return {card.config.center.config.max_highlighted,"Mult Card"}
	end,
	c_emperor = {"tarots"},
	c_heirophant = function (card)
		return {card.config.center.config.max_highlighted,"Bonus Card"}
	end,
	c_lovers = function(card)
		return {card.config.center.config.max_highlighted,"Wild Card",}
	end,
	c_chariot = function(card)
		return {card.config.center.config.max_highlighted,"Steel Card"}
	end,
	c_justice = function(card)
		return {card.config.center.config.max_highlighted,"Glass Card"}
	end,
	c_hermit = {"extra"},
	c_wheel_of_fortune = function(card)
		return {G.GAME.probabilities.normal, card.config.center.config.extra}
	end,
	c_strength = function(card)
		return {card.config.center.config.max_highlighted,"1"}
	end,
	c_hanged_man = {"max_highlighted"},
	c_death = {"max_highlighted"},
	c_temperance = function (card)
		return {card.ability.extra, card.ability.money}
	end,
	c_devil = function(card)
		return {card.config.center.config.max_highlighted,"Gold Card"}
	end,
	c_tower = function(card)
		return {card.config.center.config.max_highlighted, "Stone Card"}
	end,
	c_star = function (card)
		return {card.config.center.config.max_highlighted,localize(card.config.center.config.suit_conv, 'suits_plural'),colours = {G.C.SUITS[card.config.center.config.suit_conv]}} -- send colour as text changes with suit colour
	end,
	c_moon = function (card)
		return {card.config.center.config.max_highlighted,localize(card.config.center.config.suit_conv, 'suits_plural'),colours = {G.C.SUITS[card.config.center.config.suit_conv]}}
	end,
	c_sun = function (card)
		return {card.config.center.config.max_highlighted,localize(card.config.center.config.suit_conv, 'suits_plural'),colours = {G.C.SUITS[card.config.center.config.suit_conv]}}
	end,
	c_judgement = {},
	c_world = function (card)
		return {card.config.center.config.max_highlighted,localize(card.config.center.config.suit_conv, 'suits_plural'),colours = {G.C.SUITS[card.config.center.config.suit_conv]}}
	end,
}

Non_Valid_Add_Joker_Consumables = {
	c_wraith = false,
	c_soul = false,
	c_judgement = false
}

Non_Valid_Modify_Joker_Consumables = {
	c_hex = false,
	c_ectoplasm = false,
	c_ankh = false,
	c_wheel_of_fortune = false,
}