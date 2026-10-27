--!strict
-- A battle background's picture from its load descriptor: its tiles' archive (a size word, then an offset to its
-- LZ77 block), their VRAM destination, its map's archive (width and height bytes, then LZ77 entries from +0xC) and
-- its palette's source (+4), as `descriptor` says where the descriptor keeps them. EXE6's and EXE5's descriptors
-- copy each straight to its place (`DIRECT`); EXE4's (0x08026234, 0x08026266) decompress into a buffer first, each
-- source followed by its buffer.

local band = bit32.band

local backgrounds = {}

-- EXE6's (`off_8080F98`'s) and EXE5's descriptors.
backgrounds.DIRECT = { gfx = 0, dest = 4, map = 8, palette = 0x10 } :: BackgroundDescriptor

-- The picture of the background whose descriptor is at `d` (none: no descriptor, or no tiles), laid out as
-- `descriptor` (`DIRECT` if not given): a Background's tiles, first tile, map and its size, and palette.
function backgrounds.picture(rom: Rom, d: number, descriptor: BackgroundDescriptor?): Background?
    local at = descriptor or backgrounds.DIRECT
    if d == 0 then
        return nil
    end
    local gfx = rom:u32(d + at.gfx)
    if gfx == 0 then
        return nil
    end
    local size = rom:u32(gfx) * 4
    local raw = rom:lz77(gfx + rom:u32(gfx + 4))
    if raw == nil then
        return nil
    end
    local tiles = gba.tiles(raw, 0, math.min(size, raw:len()))
    local first_tile = band(rom:u32(d + at.dest), 0xFFFF) // 32
    local map_src = rom:u32(d + at.map)
    local w, h = rom:u8(map_src), rom:u8(map_src + 1)
    local map_raw = rom:lz77(map_src + 0xC)
    if map_raw == nil then
        return nil
    end
    local map = gba.map(map_raw, 0, w * h)
    local pal_src = rom:u32(d + at.palette)
    local palette = if pal_src ~= 0 then gba.palette(rom, pal_src + 4) else nil
    return { tiles = tiles, first_tile = first_tile, map = map, map_width = w, map_height = h, palette = palette }
end

return backgrounds
