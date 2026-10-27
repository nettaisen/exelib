--!strict
-- What a font's glyphs draw, by a game's encoding (compat's text.toml): the 8x16 font's characters (`cell`), then the
-- dialogue font's past them (`dialogue`).

local glyphs = {}

-- The characters the first `n` glyphs draw: the encoding's (`cell`'s, then `dialogue`'s), a glyph past them its
-- number in brackets (`[1a0]`).
function glyphs.chars(cell: { string }, dialogue: { string }, n: number): { string }
    local out: { string } = {}
    for k = 0, n - 1 do
        local name = if k < #cell then cell[k + 1] else dialogue[k - #cell + 1]
        table.insert(out, name or string.format("[%03x]", k))
    end
    return out
end

return glyphs
