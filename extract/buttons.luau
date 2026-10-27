--!strict
-- The custom screen's buttons as EXE6's and EXE5's draw them.

local buttons = {}

-- A cursor's place and its corners: two frames of four, each { y, x, hflip, vflip } from the place less 3.
function buttons.cursor(x: number, y: number, corners: { { { any } } }): CursorPlace
    return { x = x, y = y, corners = corners }
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
