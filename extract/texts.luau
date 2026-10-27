--!strict
-- The HUD's text lines (`TextScript86F0374` in EXE6): a table of halfword offsets, then each line's glyphs, each
-- line cut at its end mark or at anything but a glyph (a byte from `limit` on: a text command).

local texts = {}

-- The lines at `at`, each up to 0x40 bytes: its glyphs before `end_mark` or a byte of `limit` or more.
function texts.lines(rom: Rom, at: number, end_mark: number, limit: number): { { number } }
    local function offset(i: number): number
        return rom:u16(at + 2 * i)
    end
    local out: { { number } } = {}
    for i = 0, offset(0) // 2 - 1 do
        local line = rom:bytes(at + offset(i), 0x40)
        local glyphs: { number } = {}
        for k = 0, 0x3F do
            local c = line:u8(k)
            if c == end_mark or c >= limit then
                break
            end
            table.insert(glyphs, c)
        end
        table.insert(out, glyphs)
    end
    return out
end

return texts
