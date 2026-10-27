--!strict
-- The chatbox (`chatbox_runScript`'s transfers, EXE6's and EXE5's): the box's tiles and palette, its maps by kind and
-- opening step (eight pointers a kind, the steps 0 to 3 first, 30x8 entries each, counted from the box's first tile),
-- the key-wait arrow's three 16x16 frames, and the text's palette.

local place = require("@exelib/extract/place")
local colors = require("@exelib/extract/colors")

local chatbox = {}

function chatbox.of(rom: Rom, c: ChatboxPlaces): Chatbox
    local at = function(p: Place): number
        return place.at(rom, p)
    end
    local function palette(p: Place): Palette
        local colors_ = gba.palette(rom, at(p))
        return if c.masked then colors.masked(colors_) else colors_
    end
    local tiles = gba.tiles(rom, at(c.tiles), 0x20 * c.tile_count)
    local box_palette = palette(c.palette)
    local boxes: { { Map } } = {}
    for kind = 0, c.kinds - 1 do
        local steps: { Map } = {}
        for step = 0, 3 do
            table.insert(steps, gba.map(rom, rom:u32(at(c.boxes) + 4 * (8 * kind + step)), 30 * 8, c.first_tile))
        end
        table.insert(boxes, steps)
    end
    local arrow = gba.tiles(rom, at(c.arrow), 3 * 0x80)
    local text_palette = palette(c.text_palette)
    return { tiles = tiles, palette = box_palette, boxes = boxes, arrow = arrow, text_palette = text_palette }
end

return chatbox
