--!strict
-- Where the fists go (EXE6's and EXE5's MetrKnuk controller's `sub_80E8C44` and `sub_80E8BF8`,
-- docs/engine/dimming-chip-effects.md §18; EXE4's Duo's, 0x080CBA0C and 0x080CB9C2, the same code in his own actor):
-- the first at a random panel an enemy stands on; a later one at a random panel of the enemy's area around the
-- enemies, never the last one twice in a row. What differs by game is the thrower's (`Spec`): which panels count as
-- an enemy's, and what is marked when no enemy stands.

local panels = require("../panels")

local targets = {}

-- (What differs: `FistTargets`, types.d.luau's.)
type Test = FistTargetTest
type Spec = FistTargets

-- What a thrower keeps between fists.
export type State = {
    -- The last target (the original's word, y << 4 | x; 0: none).
    last: number,
    -- The panels around the enemies (`grid[6 * y + x + 1]`: the original's 0x28 bytes).
    grid: { number },
}

-- The declared types of `State`'s fields in a kind's state.
targets.LAST, targets.GRID = schema.u32, schema.array(schema.u8, 40)

-- An enemy's body on a panel of the enemy's area (EXE6's `byte_80E8D6C`), an enemy's body on any panel (EXE4's
-- 0x080CBABC), and the enemy's area (`byte_80E8D58`; EXE4's 0x080CB9FC), of the thrower's side.
targets.BODY_IN_AREA = { require = { "enemy_body", "on_field", "enemy_area" } } :: Test
targets.BODY = { require = "enemy_body" } :: Test
local ENEMY_AREA = { require = { "on_field", "enemy_area" } } :: Test
-- `byte_80E8D80`: a body's 3x3, which `sub_80E8CC4` walks from the last.
local AROUND = { { -1, -1 }, { 0, -1 }, { 1, -1 }, { -1, 0 }, { 0, 0 }, { 1, 0 }, { -1, 1 }, { 0, 1 }, { 1, 1 } }
local GRID = 0x28

local function grid_index(x: number, y: number): number
    return 6 * y + x + 1
end

local function clear_grid(s: State)
    for i = 1, GRID do
        s.grid[i] = 0
    end
end

-- `sub_80E8C44`: a random panel an enemy stands on, or (EXE6's) of the enemy's area when none does (a `rng_positive`
-- draw); 0 when there is no panel.
function targets.first(side: number, spec: Spec): number
    local list = panels.filtered(spec.body.require, spec.body.forbid, side)
    if #list == 0 and spec.area_fallback then
        list = panels.filtered(ENEMY_AREA.require, ENEMY_AREA.forbid, side)
    end
    if #list == 0 then
        -- (EXE6's keeps a register the panel search left as the row.)
        return 0
    end
    return list[battle.rng_positive() % #list + 1]
end

-- `sub_80E8C84`: the grid marks the 3x3 around each panel an enemy stands on (inside the field); whether there was
-- one.
local function mark_around_bodies(side: number, s: State, spec: Spec): boolean
    clear_grid(s)
    local cond = spec.body
    local list = panels.filtered(cond.require, cond.forbid, side)
    for _, p in list do
        local px, py = panels.x(p), panels.y(p)
        for i = #AROUND, 1, -1 do
            local x, y = px + AROUND[i][1], py + AROUND[i][2]
            if x >= 1 and x <= 6 and y >= 1 and y <= 3 then
                s.grid[grid_index(x, y)] = 1
            end
        end
    end
    return #list > 0
end

-- `sub_80E8CFA`: the grid marks every panel of the enemy's area.
local function mark_area(side: number, s: State)
    clear_grid(s)
    local cond = ENEMY_AREA
    for _, p in panels.filtered(cond.require, cond.forbid, side) do
        s.grid[grid_index(panels.x(p), panels.y(p))] = 1
    end
end

-- `sub_80E8BF8`: the marked panels of the enemy's area but the last target (`sub_80E8D92`: rows 4 to 1, columns 7 to
-- 1, past the field too, whose flags meet nothing), one at random (a `rng_positive` draw); 0 when none. With no enemy
-- standing: EXE6's marks the enemy's area; else none, at once.
function targets.next(side: number, s: State, spec: Spec): number
    if not mark_around_bodies(side, s, spec) then
        if not spec.area_fallback then
            return 0
        end
        mark_area(side, s)
    end
    if s.last ~= 0 then
        s.grid[grid_index(bit32.band(s.last, 7), bit32.rshift(s.last, 4))] = 0
    end
    local cond = ENEMY_AREA
    local list: { number } = {}
    for y = 4, 1, -1 do
        for x = 7, 1, -1 do
            -- (Its test asks the flags word for no more than its bits: off the field, where the word is 0, they are
            -- the same, as the area's names include `on_field`.)
            if field.check(x, y, cond.require, cond.forbid, side) and s.grid[grid_index(x, y)] ~= 0 then
                list[#list + 1] = panels.pack(x, y)
            end
        end
    end
    if #list == 0 then
        return 0
    end
    return list[battle.rng_positive() % #list + 1]
end

return targets
