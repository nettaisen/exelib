--!strict
-- A banner record in EXE6's and EXE5's form (EXE4's is its own): its head word (x, y, kind), then for a plain
-- banner, one with a number or one that holds (kinds 0 to 2, and 4, the judge's), twenty glyph pointers, which
-- repeat the filler once it shows up, and a numbered banner's number's place after them. Kind 3 (the telops) has no
-- glyphs: a frontend draws the chip's name there.

local band, rshift = bit32.band, bit32.rshift

local banners = {}

-- Banner `id` (its number / 4) of the record table at `table_at`, `filler` the filler glyph's address.
function banners.at(rom: Rom, table_at: number, filler: number, id: number): BannerLayout
    local p = rom:u32(table_at + 4 * id)
    local head = rom:u32(p)
    local x, y, kind = band(head, 0xFF), band(rshift(head, 8), 0xFF), band(rshift(head, 16), 0xFF)
    local glyphs: { Tiles } = {}
    local number_at: { number }? = nil
    if kind <= 2 or kind == 4 then
        local q = p + 4
        for _ = 1, 20 do
            local g = rom:u32(q)
            table.insert(glyphs, gba.tiles(rom, g, 0x40))
            if g ~= filler then
                q += 4
            end
        end
        if rom:u32(q) == filler then
            q += 4
        end
        if kind == 1 then
            local n = rom:u32(q)
            number_at = { band(n, 0xFF), band(rshift(n, 8), 0xFF) }
        end
    end
    return { x = x, y = y, kind = kind, glyphs = gba.join(glyphs), number_at = number_at }
end

return banners
