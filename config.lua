return {
    -- Websocket server URL
    ["NEURO_SDK_WS_URL"] = "ws://127.0.0.1:8000",

    -- Delay in seconds before attempting to reconnect
    ["RECONNECT_DELAY"] = 5,

    -- If true, the game will restart if there is a crash after smods is loaded.
    -- This should be set to false if you need to see logs without checking their respective folder.
    ["CAN_RESTART_ON_CRASH"] = true,

    -- The profile Neuro should use. If save data exists in this slot, we are going to assume it belongs to Neuro and
    -- continue the game from there if there's an active run. If there's no save data, we will create a new
    -- profile in this slot.
    ["PROFILE_SLOT"] = 3,

    -- If true, Neuro will have all decks, jokers, vouchers, etc unlocked
    ["UNLOCK_ALL"] = true,

    -- If true, Neuro will be allowed to continue runs. If false, Neuro will only be allowed to start new runs.
    ["ALLOW_CONTINUE"] = true,

    -- List of allowed decks for Neuro to use. I don't think Neuro should use any other deck as they're a bit
    -- complicated, but you can make an argument for some like Checkered or Plasma. When starting a new game, Neuro will
    -- choose from this list.
    -- Note that if UNLOCK_ALL is false, on a brand new profile Neuro will only have the Red Deck available. If a deck
    -- is not unlocked but is in this list, the mod will not let Neuro use it.
    ["ALLOWED_DECKS"] = {
        "Red Deck",       -- +1 discard every round
        "Blue Deck",      -- +1 hand every round
        "Yellow Deck",    -- Start with extra $10
        "Green Deck",     -- $2 per remaining hand, $1 per remaining discard, Earn no Interest every round
        "Black Deck",     -- +1 Joker slot, -1 hand every round
        --"Magic Deck",     -- Start run with the Crystal Ball voucher and 2 copies of The Fool
        --"Nebula Deck",    -- Start run with the Telescope voucher, -1 consumable slot
        --"Ghost Deck",     -- Spectral cards may appear in the shop, start with a Hex card
        --"Abandoned Deck", -- Start run with no face cards in your deck
        --"Checkered Deck", -- Start run with 26 Spades and 26 Hearts in deck
        --"Zodiac Deck",    -- Start run Tarot Merchant, Planet Merchant, and Overstock
        --"Painted Deck",   -- +2 hand size, -1 Joker slot
        --"Anaglyph Deck",  -- After defeating each Boss Blind, gain a Double Tag
        --"Plasma Deck",    -- Balance Chips and Mult when calculating score for played hand, X2 base Blind size
        --"Erratic Deck",   -- All Ranks and Suits in deck are randomised
        "Glorpy deck",
    },


    ["ALLOWED_STAKES"] = {  --
        "White Stake", -- Does nothing
        "Red Stake",    -- Small Blind gives no reward money Required score scales faster for each Ante
        "Green Stake",  -- Required score scales faster for each Ante
        "Black Stake",  -- 30% chance for Jokers in shops or booster packs to have an Eternal sticker
        "Blue Stake",   -- -1 Discard
        "Purple Stake", -- Required score scales even faster for each Ante
        "Orange Stake", -- 30% chance for Jokers in shops or booster packs to have a Perishable sticker
        "Gold Stake",   -- 30% chance for Jokers in shops or booster packs to have a Rental sticker
    },
}