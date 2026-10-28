--!strict
-- What the games' rules do to a navi, over its fields (docs/design/rules-in-luau.md §4.5): its invulnerability's end,
-- its charge's reset, its anger's end, and its side's mood raised or lowered.

local navi_status = {}

-- `sub_800EB08`: the invulnerability ends, its timer and its flag.
function navi_status.clear_invulnerable(navi: Object)
    navi:set_status_timer("invulnerable", 0)
    navi:set_status("invulnerable", false)
end

-- `sub_8012EA8`: the charge drops, its level, counter and source, and the hold requests.
function navi_status.reset_charge(navi: Object)
    navi.charge_level = 0
    navi.charge_counter = 0
    navi.charge_source = 0
    navi:set_request("a_held", false)
    navi:set_request("b_held", false)
end

-- `sub_80143A6`: the navi calms down: the anger status, its request, the ticks of anger left and the stun ticks end,
-- and its side's mood goes back to 0x80: whatever the mood (`"reset"`: EXE6's), or but a mood of 0 (`"unless_zero"`:
-- EXE4's and EXE5's, 0x08011A94, through their mood setter, which leaves a mood of 0).
function navi_status.end_anger(navi: Object, mood: "reset" | "unless_zero")
    local stats = battle.navi(navi.alliance)
    if mood == "reset" or stats.mood ~= 0 then
        stats.mood = 0x80
    end
    navi:set_status("anger", false)
    navi:set_request("anger", false)
    navi.anger_ticks = 0
    navi.stun_ticks = 0
end

-- EXE5's 0x08012802: the side's mood rises by `n`, to 254 at most; a mood of 0 or 0xFF (Full Synchro) stays (a
-- recovery's raise).
function navi_status.gain_mood(side: number, n: number)
    local stats = battle.navi(side)
    local mood = stats.mood
    if mood ~= 0 and mood ~= 0xFF then
        stats.mood = math.min(mood + n, 254)
    end
end

-- `sub_8015C12` (EXE5's 0x08012820): the side's mood falls by `n`, to 1 at least; a mood of 0 stays.
function navi_status.lose_mood(side: number, n: number)
    local stats = battle.navi(side)
    local mood = stats.mood
    if mood ~= 0 then
        stats.mood = math.max(mood - n, 1)
    end
end

return navi_status
