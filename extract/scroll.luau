--!strict
-- A BG1 scroll callback that speeds up, read from its code (EXE5's 0x080019EC, EXE4's the scrollers' +0xB8): it
-- loads its counter, takes `movs r3, #a; lsls r3, r3, #b` from it, holds it at `movs r3, #c; lsls r3, r3, #d; negs
-- r3, r3`, stores it, and adds the counter's arithmetic shift right 16 to BG1's offset (`ldrh r3, [r1, #o]; adds r3,
-- r3, r2`: the picture moves the counter's way) or takes it away (`subs`: the other way); +0x10 the x offset, +0x12
-- the y. One that first asks for a battle flag (`push {lr}; bl ...; movs r1, #flag; tst r0, r1; beq`) is
-- `from_battle` (EXE5's flag 0x40, which the battle's intro sets on the battle's first frame); any other flag, or
-- other code, is none. It is the series' code, read halfword by halfword: a background's `speeding`.

local band, rshift, lshift = bit32.band, bit32.rshift, bit32.lshift

local scroll = {}

-- The speeding scroll of the callback at `at` (its address, the Thumb bit off), if it is one.
function scroll.speeding(rom: Rom, at: number): Speeding?
    local function op(i: number): number
        return rom:u16(at + 2 * i)
    end
    -- `movs rd, #imm`'s immediate.
    local function movs(o: number, rd: number): number?
        if rshift(o, 11) == 0b00100 and band(rshift(o, 8), 7) == rd then
            return band(o, 0xFF)
        end
        return nil
    end
    -- `lsls rd, rd, #imm`'s shift.
    local function lsls(o: number, rd: number): number?
        if rshift(o, 11) == 0 and band(o, 7) == rd and band(rshift(o, 3), 7) == rd then
            return band(rshift(o, 6), 31)
        end
        return nil
    end
    -- (The flag test: push {lr}, a bl's two halves, movs r1, #flag, tst r0, r1, beq.)
    local from_battle = op(0) == 0xB500
    local i = 0
    if from_battle then
        if rshift(op(1), 11) ~= 0b11110 or rshift(op(2), 11) ~= 0b11111 or movs(op(3), 1) ~= 0x40 or op(4) ~= 0x4208 or rshift(op(5), 8) ~= 0xD0 then
            return nil
        end
        i = 6
    end
    -- ldr r1, [pc, #n] (the counter); ldr r2, [r1, #0].
    if rshift(op(i), 8) ~= 0x49 or op(i + 1) ~= 0x680A then
        return nil
    end
    local a = movs(op(i + 2), 3)
    if a == nil then
        return nil
    end
    local b = lsls(op(i + 3), 3)
    if b == nil then
        return nil
    end
    local step = lshift(a, b)
    -- subs r2, r2, r3; then the top, negated.
    if op(i + 4) ~= 0x1AD2 then
        return nil
    end
    local c = movs(op(i + 5), 3)
    if c == nil then
        return nil
    end
    local d = lsls(op(i + 6), 3)
    if d == nil then
        return nil
    end
    local top = lshift(c, d)
    if op(i + 7) ~= 0x425B then
        return nil
    end
    -- cmp r2, r3; bge; adds r2, r3, #0; str r2, [r1, #0]; asrs r2, r2, #16; mov r1, sl; ldr r1, [r1, #8] (the render
    -- info); then BG1's offset.
    local load, change = op(i + 15), op(i + 16)
    if rshift(load, 11) ~= 0b10001 or band(load, 0x3F) ~= 11 or op(i + 12) ~= 0x1412 then
        return nil
    end
    local sign
    if change == 0x189B then
        sign = -1 -- adds r3, r3, r2: the counter's way, which falls
    elseif change == 0x1A9B then
        sign = 1 -- subs r3, r3, r2
    else
        return nil
    end
    step, top = sign * step, sign * top
    local offset = band(rshift(load, 6), 31) * 2
    if offset == 0x10 then
        return { step = { step, 0 }, top = { top, 0 }, from_battle = from_battle }
    elseif offset == 0x12 then
        return { step = { 0, step }, top = { 0, top }, from_battle = from_battle }
    end
    return nil
end

return scroll
