-- we cant use require(), but we can use SMODS.load_file
-- the issue is SMODS.load_file doesn't guarantee that we only load the same file once because it doesnt cache anything
-- this acts as a wrapper that caches the result so we don't reload the same file
-- there's probably a way to design the sdk to not need this but i wanted to make minimal changes to the lua sdk
local cache = {}

local function load_once(path, id)
    if not cache[path] then
        local chunk, err = SMODS.load_file(path, id)
        if not chunk then error(err) end
        cache[path] = chunk()
    end
    return cache[path]
end

return {
    load = load_once
}
