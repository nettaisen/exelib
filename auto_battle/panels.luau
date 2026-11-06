--!strict
-- The panel searches EXE4's and EXE5's auto battle AIs run (each game's rules/auto_battle): where to step, where a
-- chip reaches from. The two games' routines are the same code, and most are EXE6's too; the ones EXE6 hasn't are named
-- by their EXE5 address, EXE4's beside it. A search that finds nothing returns nil; one that finds several picks one
-- with a battle RNG draw (`GetPositiveSignedRNG2`, modulo how many), in the order the original lists them. A game's
-- lists of panel offsets and its chips' reach lists are its own data (its rules/auto_battle/data), handed here as
-- lists of { dx, dy } pairs. A search's conditions are panel flags by name (`field.check`'s require and forbid), their
-- side-relative names of side `of`.

local panels = {}

-- A panel's place packed as the original packs it in a list: x | y << 4.
local function pack(x: number, y: number): number
    return bit32.bor(bit32.band(x, 0xF), bit32.lshift(bit32.band(y, 0xF), 4))
end

local function unpack(p: number): (number, number)
    return bit32.band(p, 7), bit32.rshift(p, 4)
end

-- One of `list` (packed places) at random, unpacked; nil for none (no draw).
local function pick(list: { number }): (number?, number?)
    if #list == 0 then
        return nil, nil
    end
    return unpack(list[battle.rng_positive() % #list + 1])
end
panels.pick = pick

-- `object_getAllianceDirection`: +1 for side 0, -1 for side 1.
function panels.side_direction(side: number): number
    return 1 - 2 * bit32.band(side, 1)
end

-- `object_getFlipDirection`: +1 facing right, -1 facing left.
function panels.flip_direction(side: number, flip: number): number
    return 1 - 2 * bit32.band(bit32.bxor(side, flip), 1)
end

-- `object_getEnemyDirection`: toward the navi's enemies (its side's direction).
function panels.enemy_direction(navi: Object): number
    return panels.side_direction(navi.alliance)
end

-- `object_getFrontDirection`: the way the navi faces.
function panels.front_direction(navi: Object): number
    return panels.flip_direction(navi.alliance, navi.flip)
end

-- The panels a side's navi may step onto (`sub_8010368`'s table, EXE4's 0x0800C41C, by side, each side's the other's
-- mirror, and whether it wears AirShoes; the byte_8015C84 rows `sub_8015C48` uses, EXE4's 0x0800F770, are its first
-- two): its own area's, free, solid unless it wears AirShoes.
local STEP: PanelCondition = { require = { "solid", "own_area" }, forbid = "occupied" }
local AIR_SHOE_STEP: PanelCondition = { require = "own_area", forbid = "occupied" }

-- The side a navi's names are of: the side's bit of its alliance, by which the original reads its tables.
local function side_of(navi: Object): number
    return bit32.band(navi.alliance, 1)
end

-- `sub_8010368` (EXE4's 0x0800C3FC): the conditions of a panel `navi` may step onto: (require, forbid), and the side
-- their names are of.
function panels.step_condition(navi: Object): (PanelFlags?, PanelFlags?, number)
    local row = if navi.status.air_shoe then AIR_SHOE_STEP else STEP
    return row.require, row.forbid, side_of(navi)
end

-- `object_getPanelsFiltered` (rows 3 to 1, columns 6 to 1), and without the navi's own panel
-- (`object_getPanelsExceptCurrentFiltered`). With `order`, in that side's order: the original's for the canonical
-- side, its columns the other way for the other (where the order counts: docs/engine/side-symmetry.md).
local function filtered(
    require: PanelFlags?,
    forbid: PanelFlags?,
    except: Object?,
    of: number?,
    order: number?
): { number }
    local out = {}
    local first, last, step = 6, 1, -1
    if order ~= nil and field.side_sign(order) < 0 then
        first, last, step = 1, 6, 1
    end
    for y = 3, 1, -1 do
        for x = first, last, step do
            local own = except and x == except.panel_x and y == except.panel_y
            if field.check(x, y, require, forbid, of) and not own then
                table.insert(out, pack(x, y))
            end
        end
    end
    return out
end
panels.filtered = filtered

-- `object_getPanelsInRowFiltered`: row `y`'s panels meeting the conditions, left to right.
local function in_row(y: number, require: PanelFlags?, forbid: PanelFlags?, of: number?): { number }
    local out = {}
    for x = 1, 6 do
        if field.check(x, y, require, forbid, of) then
            table.insert(out, pack(x, y))
        end
    end
    return out
end

-- `sub_8015C48` (EXE4's 0x0800F734): any panel of the navi's own area but its own (`byte_8015C84`), at random; none:
-- its own panel.
function panels.random_own(navi: Object): (number, number)
    local x, y = pick(filtered(STEP.require, STEP.forbid, navi, side_of(navi)))
    if x == nil then
        return navi.panel_x, navi.panel_y
    end
    return x :: number, y :: number
end

-- The other side's bodies a side looks for (`byte_8015F38`: panel flag 0x04000000 for side 0, 0x08000000 for 1).
local ENEMY_BODIES = "enemy_body"

-- `sub_8015EC6` (EXE4's 0x0800FA0C): a panel of the navi's own area in an enemy's row, at random; nil if no enemy
-- stands anywhere, or none of the row's panels is the navi's to step on. The routine means the row of the enemy
-- nearest the navi's own row, but its loop reads the first of the panels an enemy stands on (rows 3 to 1, columns 6
-- to 1, the navi's own left out) every time: that panel's row. (In the navi's side's order: the original's first is
-- the one furthest right whatever the side, docs/engine/side-symmetry.md.)
function panels.row_of_nearest_enemy(navi: Object): (number?, number?)
    local side = side_of(navi)
    local enemies = filtered(ENEMY_BODIES, nil, navi, side, navi.alliance)
    if #enemies == 0 then
        return nil, nil
    end
    local _, row = unpack(enemies[1])
    return pick(in_row(row, STEP.require, STEP.forbid, side))
end

-- The panels behind a body a side's searches stop at (`byte_8015D78`: flags 0x01800000 for side 0, 0x02800000 for 1).
local BLOCKING: { PanelFlag } = { "enemy_other_body", "neutral" }

-- `sub_8015CC0`: from (x, y) toward the navi's own side, past `skip` blocking panels (another body of the other
-- side's, or a neutral one), the panels meeting the conditions before the next one: one at random, and the last
-- blocking panel the walk met (nil x when no panel turned up).
function panels.behind(
    navi: Object,
    x: number,
    y: number,
    require: PanelFlags?,
    forbid: PanelFlags?,
    skip: number,
    of: number?
): (number?, number?, number, number)
    local back = -panels.side_direction(navi.alliance)
    local side = side_of(navi)
    local found = {}
    local hits, lx, ly = 0, 0, 0
    x += back
    while true do
        if field.any(x, y, BLOCKING, side) then
            lx, ly = x, y
            hits += 1
            if hits > skip then
                break
            end
        end
        if hits == skip and field.check(x, y, require, forbid, of) then
            table.insert(found, pack(x, y))
        end
        x += back
        if not field.valid(x, y) then
            break
        end
    end
    local px, py = pick(found)
    return px, py, lx, ly
end

-- `_GetRandomRelativePanelFiltered` (EXE4's 0x0800F8AC; `GetRandomRelativePanelFiltered`, EXE5's 0x08012C26 and EXE4's
-- 0x0800F902, is the same over a list of the game's panel offsets): of the panels `list` names from (x, y) (dx toward
-- side `side`'s enemies), those meeting the conditions: one at random, and how many there were.
function panels.random_relative(
    x: number,
    y: number,
    require: PanelFlags?,
    forbid: PanelFlags?,
    list: { { number } },
    side: number,
    of: number?
): (number?, number?, number)
    local dir = panels.side_direction(side)
    local found = {}
    for _, d in list do
        local px, py = x + d[1] * dir, y + d[2]
        if field.check(px, py, require, forbid, of) then
            table.insert(found, pack(px, py))
        end
    end
    local px, py = pick(found)
    return px, py, #found
end

-- EXE5's 0x08012C38 (EXE4's 0x0800F910): the panels from which a chip of reach list `list` reaches (x, y): the list
-- turned the other side's way.
function panels.reaching(
    x: number,
    y: number,
    require: PanelFlags?,
    forbid: PanelFlags?,
    list: { { number } },
    side: number,
    of: number?
): (number?, number?, number)
    return panels.random_relative(x, y, require, forbid, list, bit32.bxor(side, 1), of)
end

-- `sub_8015D80` (EXE4's 0x0800F83C): of the panels `list` names from (x, y) (dx toward the navi's enemies), those
-- meeting the conditions: one at random.
function panels.random_toward(
    navi: Object,
    x: number,
    y: number,
    require: PanelFlags?,
    forbid: PanelFlags?,
    list: { { number } },
    of: number?
): (number?, number?)
    local dir = panels.enemy_direction(navi)
    local found = {}
    for _, d in list do
        local px, py = x + d[1] * dir, y + d[2]
        if field.check(px, py, require, forbid, of) then
            table.insert(found, pack(px, py))
        end
    end
    return pick(found)
end

-- The panels above and below (0x08012D7C; EXE4's 0x0800FAC8).
local UP_DOWN: { { number } } = { { 0, -1 }, { 0, 1 } }

-- EXE5's 0x08012D48 (EXE4's 0x0800FA94): the panel above or below the navi it may step onto (`byte_8015C84`'s
-- rows), at random.
function panels.random_up_down(navi: Object): (number?, number?)
    return panels.random_toward(navi, navi.panel_x, navi.panel_y, STEP.require, STEP.forbid, UP_DOWN, side_of(navi))
end

-- `sub_800D1F0`: in each row, the front panel of `side`'s area (as `side` faces with `flip`: from the far end back
-- to the first panel `side` holds), if it meets the conditions; top to bottom.
function panels.area_fronts(
    side: number,
    flip: number,
    require: PanelFlags?,
    forbid: PanelFlags?,
    of: number?
): { number }
    local back = -panels.flip_direction(side, flip)
    local start = 6 - 5 * bit32.band(bit32.bxor(side, flip), 1)
    local out = {}
    for y = 1, 3 do
        local x = start
        while true do
            local p = field.panel(x, y)
            if p == nil then
                break
            end
            if p.alliance == side then
                if field.check(x, y, require, forbid, of) then
                    table.insert(out, pack(x, y))
                end
                break
            end
            x += back
        end
    end
    return out
end

-- The panels a side's front panel faces that a navi in auto battle won't step behind (0x080131A0: flags 0x01800000
-- for side 0, 0x02800000 for 1: another body of the other side's, or a neutral one).
local FRONT_BLOCKING: { PanelFlag } = { "enemy_other_body", "neutral" }

-- EXE5's 0x08013126: of the front panels of the navi's own area it may step onto (`sub_800D1F0`), those whose next
-- panel forward is free of those bodies (of `side`) and has the flag 0x10000 (`on_field`, every panel on the field's):
-- one at random.
function panels.front_line(navi: Object, side: number, flip: number): (number?, number?)
    local require, forbid, of = panels.step_condition(navi)
    local fronts = panels.area_fronts(side, flip, require, forbid, of)
    local found = {}
    for _, p in fronts do
        local x, y = unpack(p)
        if field.check(x + panels.flip_direction(side, flip), y, "on_field", FRONT_BLOCKING, bit32.band(side, 1)) then
            table.insert(found, p)
        end
    end
    return pick(found)
end

return panels
