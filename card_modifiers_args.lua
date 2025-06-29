local CardModifiersArgs = {}

function CardModifiersArgs:get_edition_args(name,card_config)
    local loc_args = {}
    if name == "foil" then loc_args = {card_config.config.extra}
    elseif name == "holo" then loc_args = {card_config.config.extra}
    elseif name == "polychrome" then loc_args = {card_config.config.extra} end
    return loc_args
end

function CardModifiersArgs:get_enhancements_args(name,card_config)
    local loc_args = {}
    if name == "Bonus Card" then loc_args = {card_config.config.bonus}
    elseif name == "Mult Card" then loc_args = {card_config.config.mult}
    elseif name == "Wild Card" then loc_args = {card_config.config.extra} --  localize
    elseif name == "Glass Card" then loc_args = {card_config.config.Xmult, card_config.config.extra} -- 2x 1 in 4 chance to break (this is sent as 4)
    elseif name == "Steel Card" then loc_args = {card_config.config.h_x_mult} -- 1.5 while in hand
    elseif name == "Stone Card" then loc_args = {card_config.config.bonus} -- is always 50
    elseif name == "Gold Card" then loc_args = {card_config.config.h_dollars} -- three in hand
    elseif name == "Lucky Card" then loc_args = {card_config.config.p_dollars,card_config.config.mult} end -- 1 in 5 chance for +20 mult and 1 in 15 for $20 (these are both sent as 20)
    return loc_args
end

function CardModifiersArgs:get_seals_args(name)
    local loc_args = {}
    if name == "Gold" then loc_args = {"gold_seal"}
    elseif name == "Red" then loc_args = {"red_seal"}
    elseif name == "Blue" then loc_args = {"blue_seal"}
    elseif name == "Purple" then loc_args = {"purple_seal"} end
    return loc_args
end

return CardModifiersArgs