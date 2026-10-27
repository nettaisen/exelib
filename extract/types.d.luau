-- The shared types of exelib's recipe code (extract/): what a game's recipe passes its makers. Only the recipes'
-- modules check against them (docs/design/extraction-recipes.md §4.5).

-- Where each of a game's four ROMs has a block (@exelib/extract/place): the address, in each ROM by its slot, of
-- the game's own pointer to it (`pointer`), or of the block itself where nothing points at it.
export type Place = { at: { number }, pointer: boolean }

-- Where the field's blocks are (@exelib/extract/field), as addresses in one ROM.
export type FieldAddresses = {
    tiles: number,
    palettes: number,
    panels: number,
    highlights: { number },
    edges: number,
    palette_anims: number,
    palette_buffer: number,
}

-- Where a background's load descriptor keeps what it copies (@exelib/extract/backgrounds), as byte offsets into it.
export type BackgroundDescriptor = { gfx: number, dest: number, map: number, palette: number }

-- The chatbox's places and sizes (@exelib/extract/chatbox): its tiles (the first of which its maps count from,
-- `first_tile`) and palettes, its maps (`kinds` kinds of eight pointers, the opening steps first), its key-wait
-- arrow; and whether its palettes' colors lose bit 15.
export type ChatboxPlaces = {
    tiles: Place,
    tile_count: number,
    first_tile: number,
    palette: Place,
    text_palette: Place,
    boxes: Place,
    kinds: number,
    arrow: Place,
    masked: boolean,
}
