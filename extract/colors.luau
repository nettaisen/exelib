--!strict
-- Colors as the hardware shows them. A palette is read as stored (`gba.palette`); whether bit 15 counts is the
-- game's code's (EXE6's HUD reads palettes as stored and its custom screen drops bit 15, EXE5's and EXE4's drop it
-- everywhere), and a pack keeps what the game shows.

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
