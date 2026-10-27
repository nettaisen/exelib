--!strict
-- A window map's patch list (`sub_8027CCC`'s): six bytes a run (column, row, width, height, palette, by column), up
-- to 0xFF; the runs take tile numbers from `first_tile` on.

local patches = {}

function patches.list(rom: Rom, at: number, first_tile: number): PatchList
    local out: { MapPatch } = {}
    local a = at
    while rom:u8(a) ~= 0xFF do
        local b = rom:bytes(a, 6)
        table.insert(out, { x = b:u8(0), y = b:u8(1), width = b:u8(2), height = b:u8(3), palette = b:u8(4), by_column = b:u8(5) == 1 })
        a += 6
    end
    return { first_tile = first_tile, patches = out }
end

return patches
