--!strict
-- ElemTrap's counterattack, as EXE5 and EXE6 share it (EXE6's effect object
-- #0x2B, `sub_80E35A4`; EXE5's #0x2B, 0x080E3818; EXE4's #0x2B, 0x080E51BC, the
-- Anti chips', striking and bursting where its look says): a dimming controller its
-- trap (./trap) starts when it
-- springs, right after the trap in the update list (the Japanese games'
-- placement; see `strike.spawn`). The usual dimming phases
-- (@exelib/dimming; its telop names the trap's chip, ElemTrap, with its bonus),
-- with an effect that strikes every panel the enemy stands on in the
-- element that sprang the trap (the damage plus the bonus; elec and wood
-- hits carry a status too), sets off bursts over the whole field
-- (@exelib/panel_bursts, the game's kind), and waits 61 ticks. Each game
-- makes its kind with `strike.make_kind(id, look)`.

local dimming_chips = require("../dimming")
local panel_bursts = require("../panel_bursts")
local regions = require("../regions")

export type State = {
    -- The Atk+ / cross bonus (object +0x32), which adds to the damage.
    bonus: number,
}

local strike = {}

local WAIT = 0x3C

-- `byte_80E36E4`: the panels struck, by side: any with the enemy's navi,
-- other bodies or neutral objects.
local STRUCK: PanelFlags = { enemy_other_body = true, neutral = true, enemy_navi = true }

-- The bursts go over the whole field, one every 2 ticks.
local BURST_INTERVAL = 2

-- The panels struck (`byte_80E36E4`'s mask over the field, in its order).
local function struck(me: Object): { { x: number, y: number } }
    local list: { { x: number, y: number } } = {}
    for x = 1, 6 do
        for y = 1, 3 do
            if field.any(x, y, STRUCK, me.alliance) then
                table.insert(list, { x = x, y = y })
            end
        end
    end
    return list
end

-- `sub_80E362C`: strike the panels, from the list's last to its first (the
-- mask's: (6, 3) back to (1, 1)), the look's step after them, then the
-- bursts. (Nothing to strike: nothing happens.)
local function hit_panels(me: Object, look: ElemTrapStrikeLook)
    local list = (look.targets or struck)(me)
    if #list == 0 then
        return
    end
    local e = me.element
    local by_element = if e.primary then look.strikes[e.primary :: PrimaryElement] else nil
    if by_element == nil then
        error(string.format("ElemTrap's counterattack: element %s reads past its tables", tostring(e)))
    end
    local sound = by_element.sound
    if sound then
        battle.play_sound(sound)
    end
    local s = me.state :: State
    local word = damage_word.plus(me.damage_word, s.bonus)
    for i = #list, 1, -1 do
        local p = list[i]
        local box = battle.hitbox(me, {
            panel_x = p.x,
            panel_y = p.y,
            element = e,
            z = 0,
            region = regions.single,
            hit_effect = by_element.spark,
            target = look.target,
            self_type = look.self_type,
            damage = word,
            hit_mod = by_element.hit_mod,
            status = by_element.status,
        })
        if box then
            box.run_while_dimmed = true
        end
    end
    if look.after then
        look.after(me)
    end
    local over = if look.bursts_over then look.bursts_over(me) else regions.field
    panel_bursts.spawn(look.bursts, me, over, BURST_INTERVAL, 0, by_element.burst)
end

-- A counterattack kind (`id`) of `look`.
function strike.make_kind(id: string, look: ElemTrapStrikeLook): Kind
    -- `sub_80E35E8`: the strike, then 61 ticks.
    local function effect(me: Object)
        if me.phase_init == 0 then
            me.timer = WAIT
            hit_panels(me, look)
            me.phase_init = 4
        end
        local t = me.timer - 1
        me.timer = t
        if t < 0 then
            dimming_chips.done(me)
        end
    end

    return new.kind {
        id = id,
        pool = Pool.effect,
        state = { bonus = schema.u16 },
        -- `sub_80E35A4`.
        update = dimming_chips.phases { name = "ElemTrap's counterattack", effect = effect },
    }
end

-- `sub_80E360E`: the counterattack for `user`, of `element`, with the
-- trap's damage word and bonus. It goes right after the trap in the update
-- list, so it first runs later this tick: the Japanese games' routine (JP
-- Falzar 0x080E81E6, JP Gregar 0x080E9516) spawns it with
-- `object_spawnType4`, as `battle.spawn` does. The US games' spawns it at
-- the head of the list (`sub_80033E4`, US only), so it first runs next
-- tick; the content follows the Japanese games on every console (the
-- user's decision, 2026-10-02: docs/engine/jp-differences.md §8.1). (Its
-- position is the spawner's registers, which nothing reads.) Of `kind`, a
-- game's.
function strike.spawn(kind: Kind, user: Object, element: Element, damage: number, bonus: number): Object?
    local o = battle.spawn(kind, Vec3.new(0, element.byte, 0))
    if not o then
        return nil
    end
    o.element = element
    o.related1 = user
    o.alliance = user.alliance
    o.damage_word = damage
    local s = o.state :: State
    s.bonus = bonus
    return o
end

return strike
