--!strict
-- The sprite list (`SpritePointersList` in EXE6): a table of categories, each a table of sprite archive entries (bit
-- 31: LZ77 compressed). Which slots a version or a release fills, and the portraits' placeholder, are the game's.

local place = require("@exelib/extract/place")

local sprites = {}

-- The sprite list's first `n` category tables' addresses (the list at `list`).
function sprites.categories(rom: Rom, list: number, n: number): { number }
    local out: { number } = {}
    for i = 0, n - 1 do
        table.insert(out, rom:u32(list + 4 * i))
    end
    return out
end

-- How many slots category `k` (from 1) of `categories` has: up to the next table after it (or 0x400 bytes), at most
-- 256.
function sprites.slots(categories: { number }, k: number): number
    local c = categories[k]
    local next = c + 0x400
    local found = false
    for _, s in categories do
        if s > c and (not found or s < next) then
            next, found = s, true
        end
    end
    return math.min((next - c) // 4, 256)
end

-- The entry of sprite (category, index), the category its table's byte offset, in the list at `list` (a place).
function sprites.entry(rom: Rom, list: Place, category: number, index: number): number
    return rom:u32(rom:u32(place.at(rom, list) + category) + 4 * index)
end

-- The sheet of the archive an entry points at.
function sprites.sheet(rom: Rom, entry: number, category: number, index: number): Sheet?
    local archive = sprite.archive(rom, entry)
    if archive == nil then
        return nil
    end
    return sprite.sheet(archive, category, index)
end

-- Portrait `index` of category `category` (the chatbox's speakers) from the first of `sources` whose table has its
-- true face there: not the placeholder each ROM has where it has none (the entry its table holds at
-- `placeholder`).
function sprites.portrait(sources: { Rom }, list: Place, category: number, index: number, placeholder: number): Sheet?
    for _, rom in sources do
        local table_at = rom:u32(place.at(rom, list) + category)
        local p = rom:u32(table_at + 4 * index)
        if p ~= rom:u32(table_at + 4 * placeholder) then
            local archive = sprite.archive(rom, p)
            if archive ~= nil then
                local sheet = sprite.portrait(archive, category, index)
                if sheet ~= nil then
                    return sheet
                end
            end
        end
    end
    return nil
end

return sprites
