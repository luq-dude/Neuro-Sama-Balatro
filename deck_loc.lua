Back_Loc = {
    b_red = { "discards" },
    b_blue = { "hands" },
    b_yellow = { "dollars" },
    b_green = { "extra_hand_bonus", "extra_discard_bonus" },
    b_black = function(back)
        return { back.config.joker_slot, -back.config.hands }
    end,
    b_magic = function(back)
        return {"Crystal Ball", "The Fool"}
    end,
    b_nebula = function(back)
        return {"Telescope", -1}
    end,
    b_ghost = {},
    b_abandoned = {},
    b_checkered = {},
    b_zodiac = function(back)
        return {"Tarot Merchant", "Planet Merchant", "Overstock"}
    end,
    b_painted = {"hand_size", "joker_slot"},
    b_anaglyph = function(back)
        return {"Double Tag"}
    end,
    b_plasma = {"ante_scaling"},
    b_erratic = {}
}

Stake_Loc = {
    stake_gold = {},
    stake_white = {},
    stake_red = {},
    stake_green = {},
    stake_black = {},
    stake_blue = {},
    stake_purple = {},
    stake_orange = {}
}