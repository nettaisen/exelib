--!strict
-- The battle field in the format EXE6, EXE5 and EXE4 share: its tiles (LZ77), the background palettes 1 to 8 at a
-- battle's start, a 5x3 block of map entries a panel by `6 * type + 3 * owner + row - 1`, the highlighted blocks,
-- the front edges by owner; and the panels' palette animations.

local band = bit32.band

local field = {}

-- The panel palette animations of a list in EXE6's and EXE5's form (`sub_800C192`'s): a word list of records, each
-- its frame count, timer slot and destination, then a palette and a duration a frame.
function field.palette_anims(rom: Rom, list: number, palette_buffer: number): { PaletteAnim }
    local out: { PaletteAnim } = {}
    local e = list
    while true do
        local p = rom:u32(e)
        if p == 0 then
            break
        end
        local count = rom:u8(p + 1)
        local timer_slot = rom:u8(p + 2)
        local dest = rom:u32(p + 4)
        local frames: { { any } } = {}
        for i = 0, count - 1 do
            local f = p + 8 + 8 * i
            table.insert(frames, { gba.palette(rom, rom:u32(f)), band(rom:u32(f + 4), 0xFF) } :: { any })
        end
        -- The timers start at 0xE, 0xD .. by their counter byte (EXE6's `sub_800BF88`).
        local initial_timer = 0xE - math.max(timer_slot - 3, 0) // 2
        table.insert(out, { slot = band((dest - palette_buffer) // 32, 0xFF), frames = frames, initial_timer = initial_timer })
        e += 4
    end
    return out
end

-- The field at `a` (its `palette_anims` unread), with these panel types (their names, in the game's order: its
-- blocks') and panel palette animations.
function field.with(rom: Rom, a: FieldAddresses, panel_types: { string }, palette_anims: { PaletteAnim }): Field
    local raw = rom:lz77(a.tiles)
    if raw == nil then
        error(string.format("the field's tiles at %#x aren't LZ77", a.tiles), 2)
    end
    local tiles = gba.tiles(raw, 0, raw:len())
    local palettes = gba.palettes(rom, a.palettes, 8)
    local panels: { Map } = {}
    for i = 0, #panel_types * 6 - 1 do
        table.insert(panels, gba.map(rom, a.panels + 32 * i, 15))
    end
    local front_edges = { gba.map(rom, a.edges, 5), gba.map(rom, a.edges + 32, 5) }
    local highlights = { gba.map(rom, a.highlights[1], 15), gba.map(rom, a.highlights[2], 15) }
    return {
        tiles = tiles,
        first_tile = 0x1460 // 32,
        palettes = palettes,
        first_palette = 1,
        palette_anims = palette_anims,
        panels = panels,
        panel_types = panel_types,
        front_edges = front_edges,
        highlights = highlights,
    }
end

-- The field at `a`, its panel palette animations read from `a.palette_anims`.
function field.read(rom: Rom, a: FieldAddresses, panel_types: { string }): Field
    local anims = field.palette_anims(rom, a.palette_anims, a.palette_buffer)
    return field.with(rom, a, panel_types, anims)
end

return field
