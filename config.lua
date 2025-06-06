return {
    -- Websocket server URL
    ["NEURO_SDK_WS_URL"] = "ws://127.0.0.1:8000",
    -- Delay in seconds before attempting to reconnect
    ["RECONNECT_DELAY"] = 2,
    -- The profile Neuro should use. If save data exists in this slot, we are going to assume it belongs to Neuro and
    -- continue the game from there if there's an active run. If there's no save data, we will create a new
    -- profile in this slot.
    ["PROFILE_SLOT"] = 3,
    -- If true, Neuro will have all decks, jokers, vouchers, etc unlocked
    ["UNLOCK_ALL"] = true,
    -- List of allowed decks for Neuro to use. I don't think Neuro should use any other deck as they're a bit
    -- complicated, but you can make an argument for some like Checkered or Plasma. When starting a new game, Neuro will
    -- choose from this list.
    -- Note that if UNLOCK_ALL is false, on a brand new profile Neuro will only have the Red Deck available. If a deck
    -- is not unlocked but is in this list, the mod will not let Neuro use it.
    ["ALLOWED_DECKS"] = { "Red Deck", "Blue Deck", "Yellow Deck", "Green Deck", "Black Deck" }
}