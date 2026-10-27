--!strict
-- The custom screen's buttons as EXE6's and EXE5's draw them, and the cursor's corners as EXE5's and EXE4's keep them.

local band, rshift = bit32.band, bit32.rshift

local buttons = {}

-- A number's low byte, signed.
local function signed_byte(n: number): number
    local b = band(n, 0xFF)
    return if b >= 0x80 then b - 0x100 else b
end

-- A cursor's place and its corners: two frames of four, each { y, x, hflip, vflip } from the place less 3.
function buttons.cursor(x: number, y: number, corners: { { { any } } }): CursorPlace
    return { x = x, y = y, corners = corners }
end

-- A cursor's corners from a table of them at `a` (EXE5's and EXE4's): two frames of four words, each corner's y in its
-- low half's low byte, its x in its high half's, and its flips in the high half (0x1000 h, 0x2000 v); each corner
-- { y, x, hflip, vflip }.
function buttons.corners(rom: Rom, a: number): { { { any } } }
    local frames: { { { any } } } = {}
    for f = 0, 1 do
        local four: { { any } } = {}
        for k = 0, 3 do
            local w = rom:u32(a + 16 * f + 4 * k)
            local hi = rshift(w, 16)
            local corner: { any } = { signed_byte(w), signed_byte(hi), band(hi, 0x1000) ~= 0, band(hi, 0x2000) ~= 0 }
            table.insert(four, corner)
        end
        table.insert(frames, four)
    end
    return frames
end

-- A button two slots wide in the slots' row (EXE6's `sub_8028250`: twelve tiles a state, the two slots' icons and
-- codes, a state each), with its picture in the chip window, whose palette is its only one.
function buttons.row(tiles: Tiles, picture: Picture, cursor: CursorPlace): ButtonPictures
    return {
        width = 2,
        height = 3,
        tiles = tiles,
        sets = "each",
        cursor = cursor,
        palettes = { picture.palette :: Palette },
        picture = picture,
    }
end

return buttons
