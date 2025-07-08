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
		return {"5", "20"}
	end, -- extra is a table and these are values not 100% sure if this will work
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
		return {card.config.max_highlighted,"Lucky Card"}
	end,
	c_high_priestess = {"planets"},
	c_empress = function (card)
		return {card.config.max_highlighted,"Mult Card"}
	end,
	c_emperor = {"tarots"},
	c_heirophant = function (card)
		return {card.config.max_highlighted,"Bonus Card"}
	end,
	c_lovers = function(card)
		return {card.config.max_highlighted,"Wild Card",}
	end,
	c_chariot = function(card)
		return {card.config.max_highlighted,"Steel Card"}
	end,
	c_justice = function(card)
		return {card.config.max_highlighted,"Glass Card"}
	end,
	c_hermit = {"extra"},
	c_wheel_of_fortune = {"extra"},
	c_strength = function(card)
		return {card.config.max_highlighted,"1"}
	end,
	c_hanged_man = {"max_highlighted"},
	c_death = {"max_highlighted"},
	c_temperance = {"extra"},
	c_devil = function(card)
		return {card.config.max_highlighted,"Gold Card"}
	end,
	c_tower = function(card)
		return {card.config.max_highlighted, "Stone Card"}
	end,
	c_star = {"max_highlighted", "suit_conv"},
	c_moon = {"max_highlighted", "suit_conv"},
	c_sun = {"max_highlighted", "suit_conv"},
	c_judgement = {},
	c_world = {"max_highlighted", "suit_conv"},
}

Celestial_Loc = {
	c_mercury = {"hand_type"},
	c_venus = {"hand_type"},
	c_earth = {"hand_type"},
	c_mars = {"hand_type"},
	c_jupiter = {"hand_type"},
	c_saturn = {"hand_type"},
	c_uranus = {"hand_type"},
	c_neptune = {"hand_type"},
	c_pluto = {"hand_type"},
	c_planet_x = {"hand_type"},
	c_ceres = {"hand_type"},
	c_eris = {"hand_type"},
}