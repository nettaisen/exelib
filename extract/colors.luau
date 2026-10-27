--!strict
-- Colors as the hardware shows them. A palette is read as stored (`gba.palette`); whether bit 15 is dropped is the
-- game's code's: EXE6's HUD reads palettes as stored and its custom screen drops bit 15; EXE5's HUD, custom screen and
-- chip pictures drop it, as EXE4's HUD, custom screen and panels' cycling palettes do; the three games' field and
-- backgrounds keep it, exelib's makers reading them as stored (docs/design/extraction-recipes.md §3.4). The hardware
-- ignores the bit: what it changes is a pack's bytes, which stay as the games' packs have always had them.

local colors = {}

-- A color with bit 15 dropped (the pictures of the chips the US release cut hold 0xCCCC).
function colors.color(c: number): number
    return bit32.band(c, 0x7FFF)
end

-- A palette with each color's bit 15 dropped.
function colors.masked(p: Palette): Palette
    local out: { number } = {}
    for _, c in p do
        table.insert(out, bit32.band(c, 0x7FFF))
    end
    return out
end

return colors
