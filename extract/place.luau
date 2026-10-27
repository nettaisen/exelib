--!strict
-- Places (docs/design/extraction-recipes.md §3.2): where each of a game's four ROMs has a block. A place is the
-- address, in each ROM, of the game's own pointer to the block (a routine's literal, a load list's entry), in the
-- order of the game's ROMs (its manifest's [extract] `roms`: its two US ROMs, then their Japanese ones), so every
-- ROM is read the way its own code reaches the block, whatever moved in it. A block no pointer of the game's reaches
-- has its own address stated.

local place = {}

-- A pointer the two versions' code has at the same address: at `us` in both US ROMs and at `jp` in both Japanese
-- ones.
function place.pointer(us: number, jp: number): Place
    return { at = { us, us, jp, jp }, pointer = true }
end

-- A pointer at an address of its own in each ROM (code past the first of what the two versions have otherwise).
function place.pointer_in_each(at: { number }): Place
    return { at = at, pointer = true }
end

-- The block's own address in each ROM, for data a ROM holds and nothing of its points at; 0 where a ROM doesn't
-- have it so.
function place.stated(at: { number }): Place
    return { at = at, pointer = false }
end

-- Where `rom` has the block at `p`: the pointer word read at its address for the ROM's slot, or the address stated.
function place.at(rom: Rom, p: Place): number
    local a = p.at[rom.slot]
    if p.pointer then
        return rom:u32(a)
    end
    return a
end

return place
