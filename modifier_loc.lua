NEURO.LOCS.EDITION = {
	e_base = {},
	e_foil = {"extra"},
	e_holo = {"extra"},
	e_polychrome = {"extra"},
	e_negative = {"extra"}
}

NEURO.LOCS.ENHANCEMENT = {
	m_bonus = {"bonus"},
	m_mult = {"mult"},
	m_wild = {},
	m_glass = function(card)
		return {card.config.Xmult, G.GAME.probabilities.normal, card.config.extra}
	end,
	m_stone = {"bonus"},
	m_gold = {"h_dollars"},
	m_lucky = function(card)
        return {G.GAME.probabilities.normal, card.config.mult, 5, card.config.p_dollars, 15, G.GAME.probabilities.normal}
    end,
	m_steel = {"h_x_mult"}
}

NEURO.LOCS.SEAL = {
	Gold = {"gold_seal"},
	Red = {"red_seal"},
	Blue = {"blue_seal"},
	Purple = {"purple_seal"}
}