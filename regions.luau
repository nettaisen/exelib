--!strict
-- Hit regions many kinds use (docs/design/content-model-v2.md §3.6): panels
-- around an anchor, { dx, dy } with dx toward the facing side, in the order
-- hits and effects go over them; or the whole field's panels that meet a
-- condition. No region is `nil`. And walking a region's panels the way the
-- game's helpers do: effects on every panel of a blast, panel types under a
-- seed.

local regions = {}

-- The anchor panel (region 0x01).
regions.single = new.region { panels = { { 0, 0 } } }

-- The anchor and the panel ahead (region 0x02: LongSwrd).
regions.long = new.region { panels = { { 0, 0 }, { 1, 0 } } }

-- The anchor and the panels above and below (region 0x04: WideSwrd).
regions.wide = new.region { panels = { { 0, 0 }, { 0, -1 }, { 0, 1 } } }

-- Three in a row from the anchor (region 0x06: FtrSword).
regions.line = new.region { panels = { { 0, 0 }, { 1, 0 }, { 2, 0 } } }

-- The anchor and its four diagonals (region 0x0B: CrosSwrd).
regions.x = new.region { panels = { { 0, 0 }, { 1, -1 }, { -1, 1 }, { 1, 1 }, { -1, -1 } } }

-- The four panels around the anchor, and its four diagonals (regions 0x0A
-- and 0x0C: JustcOne's landing waves; AirRaid's strays).
regions.neighbors = new.region { panels = { { 0, -1 }, { 0, 1 }, { 1, 0 }, { -1, 0 } } }
regions.diagonals = new.region { panels = { { 1, -1 }, { -1, 1 }, { 1, 1 }, { -1, -1 } } }

-- The halves of that X: the diagonal rising forward (region 0x12) and the
-- one falling forward (0x13), TwinLdrs's Colonel striking both.
regions.rising = new.region { panels = { { 0, 0 }, { 1, -1 }, { -1, 1 } } }
regions.falling = new.region { panels = { { 0, 0 }, { -1, -1 }, { 1, 1 } } }

-- The anchor and the two panels diagonally ahead (region 0x0D: a bullet's
-- burst).
regions.fork = new.region { panels = { { 0, 0 }, { 1, -1 }, { 1, 1 } } }

-- The anchor's column and the one ahead (region 0x11: LifeSrd).
regions.wide_long = new.region {
    panels = { { 0, 0 }, { 0, -1 }, { 0, 1 }, { 1, 0 }, { 1, -1 }, { 1, 1 } },
}

-- The 3x3 around the anchor, the anchor first (region 0x0F).
regions.square = new.region {
    panels = { { 0, 0 }, { 0, -1 }, { 0, 1 }, { 1, 0 }, { -1, 0 }, { 1, -1 }, { -1, 1 }, { 1, 1 }, { -1, -1 } },
}

-- The eight around the anchor (region 0x10).
regions.ring = new.region {
    panels = { { 0, -1 }, { 0, 1 }, { 1, 0 }, { -1, 0 }, { 1, -1 }, { -1, 1 }, { 1, 1 }, { -1, -1 } },
}

-- The anchor and its four neighbors (region 0x09: H-Burst's even bursts).
regions.plus = new.region { panels = { { 0, 0 }, { 0, -1 }, { 0, 1 }, { 1, 0 }, { -1, 0 } } }

-- The anchor and the panel above it (region 0x18: a big rolling log).
regions.tall = new.region { panels = { { 0, 0 }, { 0, -1 } } }

-- The anchor and the two panels diagonally behind it (region 0x1F: EXE5's
-- ColonelSoul's screen divide).
regions.vee = new.region { panels = { { 0, 0 }, { -1, -1 }, { -1, 1 } } }

-- Six in a row from the anchor (region 0x08: EXE5's MagnetSoul's pull,
-- EXE4's MagBolt and LaserMan's laser, WaveArm's look ahead, DblHero's
-- shots).
regions.row = new.region { panels = { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }, { 5, 0 } } }

-- The anchor and the column ahead of it (region 0x15: ElcPuls's pulse).
regions.fan = new.region { panels = { { 0, 0 }, { 1, -1 }, { 1, 1 }, { 1, 0 } } }

-- The anchor and the two columns ahead of it (region 0x1A: the Beast
-- charged chips' pillars).
regions.deep_fan = new.region {
    panels = { { 0, 0 }, { 1, -1 }, { 1, 0 }, { 1, 1 }, { 2, -1 }, { 2, 0 }, { 2, 1 } },
}

-- The 5x5 around the anchor, row by row from the far back corner (region
-- 0x26: ElecMan's reach).
regions.big_square = new.region {
    panels = {
        { -2, -2 }, { -1, -2 }, { 0, -2 }, { 1, -2 }, { 2, -2 },
        { -2, -1 }, { -1, -1 }, { 0, -1 }, { 1, -1 }, { 2, -1 },
        { -2, 0 }, { -1, 0 }, { 0, 0 }, { 1, 0 }, { 2, 0 },
        { -2, 1 }, { -1, 1 }, { 0, 1 }, { 1, 1 }, { 2, 1 },
        { -2, 2 }, { -1, 2 }, { 0, 2 }, { 1, 2 }, { 2, 2 },
    },
}

-- A side's area: side 0's (region 0x81, the panels without flag 0x20) and
-- side 1's (0x82, with it).
regions.area = {
    [0] = new.region { field = { own_area = true }, side = 0 },
    [1] = new.region { field = { own_area = true }, side = 1 },
}

-- The other side's area: side 0's target (region 0x82) and side 1's (0x81)
-- (EXE5's and EXE4's Discord).
regions.other_area = { [0] = regions.area[1], [1] = regions.area[0] }

-- Every panel (region 0x80: Silence).
regions.field = new.region { field = {} }

-- Every solid panel (region 0x83: Timpani).
regions.solid = new.region { field = { solid = true } }

-- The panels of the other side's player navi: side 0's target (region
-- 0x85) and side 1's (0x84) (Discord, the Guardian's strike).
regions.other_navi = {
    [0] = new.region { field = { enemy_navi = true }, side = 0 },
    [1] = new.region { field = { enemy_navi = true }, side = 1 },
}

-- Every panel without a navi on it (region 0x86).
regions.no_navi = new.region { field = { own_navi = false, enemy_navi = false } }

-- A side's solid panels: side 0's (region 0x87) and side 1's (0x88).
regions.solid_area = {
    [0] = new.region { field = { solid = true, own_area = true }, side = 0 },
    [1] = new.region { field = { solid = true, own_area = true }, side = 1 },
}

-- `GetRandomRelativePanelFiltered`: of region `r`'s panels around (x, y),
-- dx stepping by `dir`, one that meets `cond` (`field.check`:
-- side-relative flags of side `of`), at random (one `rng_positive` draw,
-- only when there is one); nil if none.
function regions.random_panel(
    x: number,
    y: number,
    r: Region,
    dir: number,
    cond: PanelCondition?,
    of: number?
): (number?, number?)
    local found: { number } = {}
    for _, p in r.panels or {} do
        local px: number, py: number = x + p[1] * dir, y + p[2]
        if field.check(px, py, cond, of) then
            local packed: number = px + py * 0x10
            table.insert(found, packed)
        end
    end
    if #found == 0 then
        return nil, nil
    end
    local pick = found[battle.rng_positive() % #found + 1]
    return bit32.band(pick, 7), bit32.rshift(pick, 4)
end

-- `object_isValidPanel` on whole numbers (the API's panel arguments wrap
-- to a byte, which could bring a far-off panel back onto the field).
local function valid(x: number, y: number): boolean
    return x >= 1 and x <= 6 and y >= 1 and y <= 3
end

-- `sub_80CE468`: `sub_801BD3C` (`battle.region_effects`: `effect` on each
-- panel of region `r` around (x, y) at height `z`, or on each of a
-- whole-field region's from the bottom right, on the ground), skipping
-- missing panels too, and with dx stepping by `dir`
-- (`panels.side_direction`), which its callers compute from the side and
-- flip halfword.
function regions.effects_on_panels(x: number, y: number, effect: Effect, r: Region, dir: number, z: number)
    local cond = r.field
    if cond then
        for py = 3, 1, -1 do
            for px = 6, 1, -1 do
                -- (Its names of the region's side, where it gives one.)
                if field.check(px, py, cond, r.side) then
                    local cx, cy = field.center(px, py)
                    battle.effect(Vec3.new(cx, cy, 0), effect)
                end
            end
        end
        return
    end
    for _, p in r.panels or {} do
        local px, py = x + p[1] * dir, y + p[2]
        if valid(px, py) then
            local panel = field.panel(px, py)
            if panel and panel.kind ~= PanelType.missing then
                local cx, cy = field.center(px, py)
                battle.effect(Vec3.new(cx, cy, z), effect)
            end
        end
    end
end

-- `sub_80CE424`: panel type `kind` on each panel of region `r` around
-- (x, y), dx not mirrored (`object_setPanelType` leaves missing panels,
-- and the field's border, alone).
function regions.set_types(x: number, y: number, kind: PanelType, r: Region)
    for _, p in r.panels or {} do
        field.set_type(x + p[1], y + p[2], kind)
    end
end

-- The rest of the original's regions, named for their shapes. A number in a
-- name is how many columns the region reaches, the anchor's among them.

-- The panel ahead of the anchor (region 0x03).
regions.ahead = new.region { panels = { { 1, 0 } } }

-- The panels above and below the anchor (region 0x05).
regions.above_below = new.region { panels = { { 0, -1 }, { 0, 1 } } }

-- Four in a row from the anchor (region 0x07: WaveArm's look ahead,
-- DblHero's shots).
regions.line_4 = new.region { panels = { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 } } }

-- The two panels diagonally ahead of the anchor: the fork without its
-- anchor (region 0x0E).
regions.diagonals_ahead = new.region { panels = { { 1, -1 }, { 1, 1 } } }

-- The anchor, the panels above and below it and the one ahead (region 0x14).
regions.tee = new.region { panels = { { 0, 0 }, { 0, -1 }, { 0, 1 }, { 1, 0 } } }

-- The anchor and the panel diagonally ahead and up (region 0x16), or ahead
-- and down (0x17) (WaveArm's look before it turns).
regions.up_ahead = new.region { panels = { { 0, 0 }, { 1, -1 } } }
regions.down_ahead = new.region { panels = { { 0, 0 }, { 1, 1 } } }

-- The anchor and the panel below it (region 0x19: EXE4's BurnMan's pillar,
-- with `tall` for the panel above).
regions.tall_down = new.region { panels = { { 0, 0 }, { 0, 1 } } }

-- The anchor and the three columns ahead of it (region 0x1B: EXE5's
-- BigNoise), and the four (0x1C).
regions.fan_4 = new.region {
    panels = { { 0, 0 }, { 1, -1 }, { 1, 0 }, { 1, 1 }, { 2, -1 }, { 2, 0 }, { 2, 1 }, { 3, -1 }, { 3, 0 }, { 3, 1 } },
}
regions.fan_5 = new.region {
    panels = {
        { 0, 0 },
        { 1, -1 }, { 1, 0 }, { 1, 1 },
        { 2, -1 }, { 2, 0 }, { 2, 1 },
        { 3, -1 }, { 3, 0 }, { 3, 1 },
        { 4, -1 }, { 4, 0 }, { 4, 1 },
    },
}

-- The anchor and the panels ahead of and behind it (region 0x1D: EXE5's
-- Meddy's capsule's row), and those two without the anchor (0x1E).
regions.across = new.region { panels = { { 0, 0 }, { 1, 0 }, { -1, 0 } } }
regions.ahead_behind = new.region { panels = { { 1, 0 }, { -1, 0 } } }

-- Five in a row from the anchor (region 0x20: WaveArm's look ahead,
-- DblHero's shots).
regions.line_5 = new.region { panels = { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 } } }

-- The anchor's column and the three ahead of it (region 0x21), column by
-- column.
regions.wide_long_4 = new.region {
    panels = {
        { 0, 0 }, { 0, -1 }, { 0, 1 },
        { 1, 0 }, { 1, -1 }, { 1, 1 },
        { 2, 0 }, { 2, -1 }, { 2, 1 },
        { 3, 0 }, { 3, -1 }, { 3, 1 },
    },
}

-- The three panels above the anchor, the anchor and the three below
-- (region 0x22).
regions.hourglass = new.region {
    panels = { { -1, -1 }, { 0, -1 }, { 1, -1 }, { 0, 0 }, { -1, 1 }, { 0, 1 }, { 1, 1 } },
}

-- The anchor's column and the five ahead of it (region 0x23: TenguMan's
-- dash), row by row from the top.
regions.wide_long_6 = new.region {
    panels = {
        { 0, -1 }, { 1, -1 }, { 2, -1 }, { 3, -1 }, { 4, -1 }, { 5, -1 },
        { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }, { 5, 0 },
        { 0, 1 }, { 1, 1 }, { 2, 1 }, { 3, 1 }, { 4, 1 }, { 5, 1 },
    },
}

-- Three rows of three, each a panel further forward than the one below it
-- (region 0x24), or than the one above it (0x25: TenguMan's dive): the
-- rising and the falling diagonals, three panels thick.
regions.rising_band = new.region {
    panels = {
        { 0, -1 }, { 1, -1 }, { 2, -1 },
        { -1, 0 }, { 0, 0 }, { 1, 0 },
        { -2, 1 }, { -1, 1 }, { 0, 1 },
    },
}
regions.falling_band = new.region {
    panels = {
        { -2, -1 }, { -1, -1 }, { 0, -1 },
        { -1, 0 }, { 0, 0 }, { 1, 0 },
        { 0, 1 }, { 1, 1 }, { 2, 1 },
    },
}

-- The rows above and below the anchor, six long from its column, and the
-- far end of its own row between them, open toward the anchor (region
-- 0x27).
regions.bracket = new.region {
    panels = {
        { 0, -1 }, { 1, -1 }, { 2, -1 }, { 3, -1 }, { 4, -1 }, { 5, -1 },
        { 5, 0 },
        { 0, 1 }, { 1, 1 }, { 2, 1 }, { 3, 1 }, { 4, 1 }, { 5, 1 },
    },
}

-- Three in a row from the anchor, and the panels above and below the third
-- (region 0x28).
regions.hammer = new.region { panels = { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 2, -1 }, { 2, 1 } } }

-- The hourglass around the panel ahead of the anchor, the anchor not among
-- them (region 0x29: Colonel's ScreenDivide).
regions.hourglass_ahead = new.region {
    panels = { { 0, -1 }, { 1, -1 }, { 2, -1 }, { 1, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 } },
}

-- The panels above and below the anchor, and six in a row from it (region
-- 0x2A).
regions.long_tee = new.region {
    panels = { { 0, -1 }, { 0, 1 }, { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }, { 5, 0 } },
}

-- Three in a row from the anchor backward (region 0x2B).
regions.line_behind = new.region { panels = { { 0, 0 }, { -1, 0 }, { -2, 0 } } }

-- Every panel up to five columns and two rows from the anchor but the 3x3
-- around it (region 0x2C): the rows two above and two below, then the
-- rows above, below and through the anchor, each from the front.
regions.outside_square = new.region {
    panels = {
        { 5, -2 }, { 4, -2 }, { 3, -2 }, { 2, -2 }, { 1, -2 }, { 0, -2 },
        { -1, -2 }, { -2, -2 }, { -3, -2 }, { -4, -2 }, { -5, -2 },
        { 5, 2 }, { 4, 2 }, { 3, 2 }, { 2, 2 }, { 1, 2 }, { 0, 2 },
        { -1, 2 }, { -2, 2 }, { -3, 2 }, { -4, 2 }, { -5, 2 },
        { 5, -1 }, { 4, -1 }, { 3, -1 }, { 2, -1 }, { -2, -1 }, { -3, -1 }, { -4, -1 }, { -5, -1 },
        { 5, 1 }, { 4, 1 }, { 3, 1 }, { 2, 1 }, { -2, 1 }, { -3, 1 }, { -4, 1 }, { -5, 1 },
        { 5, 0 }, { 4, 0 }, { 3, 0 }, { 2, 0 }, { -2, 0 }, { -3, 0 }, { -4, 0 }, { -5, 0 },
    },
}

-- The anchor's whole column, up to two panels above and below it (region
-- 0x2D), and the same without the anchor (0x2E).
regions.column = new.region { panels = { { 0, 0 }, { 0, -2 }, { 0, -1 }, { 0, 1 }, { 0, 2 } } }
regions.rest_of_column = new.region { panels = { { 0, -2 }, { 0, -1 }, { 0, 1 }, { 0, 2 } } }

return regions
