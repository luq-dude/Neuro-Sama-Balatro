local Mode = {}
Mode.__index = Mode

function Mode:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Mode:main_menu()
    return false
end

function Mode:deck_selection()
    return false
end

function Mode:select_blind()
    return false
end

function Mode:in_blind()
    return false
end

function Mode:in_booster_pack()
    return false
end

function Mode:game_over()
    return false
end

return Mode