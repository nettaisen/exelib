--!strict
-- VarSwrd's and NeoVari's action (EXE5's actions 0x2A, 0x080ED4A2, and 0x31; EXE6's `sub_80EF62E`'s waiting, EXE5's
-- own picks; EXE4's actions 0x36, 0x080ED6BE, and 0x5A, 0x080EE1A2, from which EXE5's grew), made for a game
-- (`action.make`): the navi stands holding A and the chip becomes another sword by the direction sequence entered
-- (with A held, each step the whole joypad word). Letting go of A, or 48 ticks without a sequence, gives a Sword (chip
-- 0x30). The pick's action starts in place (`object_setAttack0`) as that chip's, with its subtype and parameters and
-- the original damage; a sequence's pick plays the game's sound. In the souls the game names (`waits`: EXE5's
-- ProtoSoul and ShadowSoul, EXE4's ProtoSoul) the navi waits while A is up. A navi in auto battle takes the side's
-- sword pick instead, where the game has one (`auto_pick`: EXE5's).
--
-- The sequences are by the navi's turn (EXE5's facing its side's way, then turned; EXE4 turns none: its one set), each
-- step the buttons held (the game's joypad words, each sequence ending in 0). The match (EXE5's `sub_8012792` counterpart, EXE4's 0x0800D486) advances every sequence whose
-- next step is the held word, last first; the first one already complete is the pick, so a sequence is picked the
-- tick after its last step. (EXE4's also tests, as a step matches, the word at the sequence's next step, 0x0800D4A6,
-- and picks at once at 0: an unaligned read with the steps before it, or an aligned one with the step after it,
-- never 0 in VarSwrd's and NeoVari's tables.)

local action = {}

export type State = {
    -- The navi turned (which set of sequences: EXE5's AIAttackVars+0x28, EXE4's +0x1C), and how far into each
    -- sequence the navi is, in bytes (EXE5's +0x30 up, EXE4's +0x20 up: the marker word and the next).
    flip: boolean,
    progress: { number },
}

action.STATE = { flip = schema.bool, progress = schema.array(schema.u8, 5) }

-- Ticks to enter a sequence.
local COUNTDOWN = 0x30
-- The phases, on the attack's step.
local START, PICK = 0, 4
-- The joypad's buttons (the game's JoypadHeld word, & 0x3FF).
local KEYS: { Key } = { "a", "b", "select", "start", "right", "left", "up", "down", "r", "l" }

-- The buttons held are the step's and no other (the game compares the whole joypad word).
local function holds(me: Object, step: KeySet): boolean
    for _, k in KEYS do
        if ((me.held :: any)[k] == true) ~= ((step :: any)[k] == true) then
            return false
        end
    end
    return true
end

-- Advance every sequence whose next step is held, last first; the first one already complete (past its last step:
-- the game's 0) is the pick.
local function advance(me: Object, s: State, sequences: { { KeySet } }): number?
    for i = #sequences, 1, -1 do
        local at = s.progress[i]
        local want = sequences[i][at // 2 + 1]
        if want == nil then
            return i
        end
        if holds(me, want) then
            s.progress[i] = at + 2
        end
    end
    return nil
end

-- The sequences for a navi turned or not.
local function by_turn(spec: VarSwordSpec, turned: boolean): { { KeySet } }?
    return if turned then spec.sequences.turned else spec.sequences.unturned
end

-- A sequence's steps are sets of buttons, each held (true) or not: a name not a button or a value not true or false
-- is an error.
local function check(spec: VarSwordSpec)
    for _, set in { spec.sequences.unturned, spec.sequences.turned or {} } do
        for _, sequence in set do
            for _, step in sequence do
                for k, v in step :: any do
                    if table.find(KEYS, k) == nil or type(v) ~= "boolean" then
                        error(string.format("%s: a sequence's step is buttons held (a = true), not %s = %s", spec.id or "VarSwrd", tostring(k), tostring(v)))
                    end
                end
            end
        end
    end
end

-- The attack becomes `chip` (its action, subtype and parameters; the damage stays).
local function become(me: Object, chip: Chip)
    local a = chip.action
    if a == nil then
        error(string.format("VarSwrd's pick %s has no action", chip.id :: string))
    end
    me.attack_chip = chip
    me:set_attack(a, AttackKind.plain)
end

-- A game's VarSwrd-like action: `spec`'s sequences and picks, `game`'s sound and souls.
function action.make(spec: VarSwordSpec, game: VarSwordGame): Action
    check(spec)
    -- EXE5's 0x080ED570 (NeoVari's 0x080EDF7C), EXE4's 0x080ED742 (NeoVari's 0x080EE20C): a tick of waiting for the
    -- pick.
    local function pick(me: Object, s: State)
        local auto_pick = game.auto_pick
        local chosen = if auto_pick then auto_pick(me) else nil
        if chosen ~= nil then
            if chosen == #spec.picks then
                return become(me, spec.sword)
            end
            local chip = spec.picks[chosen + 1]
            if chip == nil then
                error(string.format("the side's sword pick %d reads past the picks' table", chosen))
            end
            battle.play_sound(game.sound)
            return become(me, chip)
        end
        local left = me.attack_count - 1
        me.attack_count = left
        if left == 0 then
            return become(me, spec.sword)
        end
        if not me.held.a then
            if game.waits(me) then
                return
            end
            return become(me, spec.sword)
        end
        local i = advance(me, s, by_turn(spec, s.flip) :: { { KeySet } })
        if i == nil then
            return
        end
        battle.play_sound(game.sound)
        become(me, spec.picks[i])
    end

    -- EXE5's 0x080ED4BC, EXE4's 0x080ED6DC: 48 ticks, the sequences for the navi's flip, none begun; then the first
    -- pick.
    local function start(me: Object, s: State)
        me.attack_count = COUNTDOWN
        local flip = me.flip
        if by_turn(spec, flip) == nil then
            error("a turned navi's sequences read past the sequence tables")
        end
        s.flip = flip
        for i = 1, 5 do
            s.progress[i] = 0
        end
        me.marker = 0
        me.step = PICK
        me.step_init = 0
        pick(me, s)
    end

    -- EXE5's 0x080ED4A2, EXE4's 0x080ED6BE.
    local function update(me: Object, s: State)
        local step = me.step
        if step == START then
            start(me, s)
        elseif step == PICK then
            pick(me, s)
        else
            error(string.format("VarSwrd phase %#x reads past its phase table", step))
        end
    end

    return new.action { id = spec.id, state = action.STATE, args = spec, update = update }
end

return action
