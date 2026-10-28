--!strict
-- What a navi, or an object drawn as one, wears: the parts its identity's actor record puts on and takes off
-- (`object:add_parts`, `object:remove_parts`), what a form wears, and how it steps (the overlay's `stepping`).

local overlays = {}

-- Param3 1 and flags 0x14 on what `o` wears (its related2: `sub_80C0E24`, the form changes' first step): it keeps
-- running through pauses and dimming, and steps its sprite through them.
function overlays.keep_stepping(o: Object)
    local part = o.related2
    if part then
        part.run_while_paused = true
        part.run_while_dimmed = true
        part.stepping = "while_dimmed"
    end
end

-- What `o` wears, if anything, steps `stepping`'s way (its Param3 alone: "while_dimmed" the DS's 0x02202064, "normal"
-- Beast Out's emergence).
function overlays.set_stepping(o: Object, stepping: FormOverlayStepping)
    local part = o.related2
    if part then
        part.stepping = stepping
    end
end

-- `sub_8010DF6` with `owner`'s identity: the parts its actor record puts on, on `o` (kept in its related2), r2 the
-- record's first byte (its `version`), or 1 with `paused_stepping` (the dimming chips' stand-ins: the parts step
-- even while paused); with `keep_stepping`, what `o` wears then keeps stepping through pauses and dimming.
function overlays.add_parts_of(o: Object, owner: Object, keep_stepping: boolean?, paused_stepping: boolean?)
    local identity = owner.identity
    if identity then
        o:add_parts(identity, if paused_stepping then 1 else identity.version or 0)
    end
    if keep_stepping then
        overlays.keep_stepping(o)
    end
end

-- `sub_8011044` with `owner`'s identity: what its death hook takes off `o`.
function overlays.remove_parts_of(o: Object, owner: Object)
    local identity = owner.identity
    if identity then
        o:remove_parts(identity)
    end
end

-- `sub_8011268(form)`: the form's put-on routine (EXE6's by form, EXE5's 0x0800F024 by soul): its `put_on`, else
-- what its identity wears (r2 0; the base form, which has no identity of its own, puts on nothing).
function overlays.put_on_form(o: Object, form: FormDef)
    local put_on, identity = form.put_on, form.identity
    if put_on then
        put_on(o)
    elseif identity then
        o:add_parts(identity, 0)
    end
end

-- `sub_8011384(form)`: the form's take-off routine (EXE5's 0x0800F088 by soul): its `take_off`, else its identity's
-- death hook (`sub_80113FC`, `sub_801140E`); the base form's takes down whatever is there (`sub_80111B8`, EXE5's
-- 0x0800EFCC).
function overlays.take_off_form(o: Object, form: FormDef)
    local take_off, identity = form.take_off, form.identity
    if take_off then
        take_off(o)
    elseif identity then
        o:remove_parts(identity)
    else
        local part = o.related2
        o.related2 = nil
        if part then
            part:set_lifecycle("destroy")
        end
    end
end

-- `sub_8011420` with Param3 1 (EXE5's 0x0800F0EC: its stand-ins'): what `owner`'s navi wears, put on `o` as on an
-- image of it: a navi that changes form its form's `put_on` (EXE5's NumberSoul's layer, the base form's Hub Style
-- shade), else the parts its form's identity wears; any other navi its identity's parts. Their sprites step even
-- while paused.
function overlays.add_overlay_of(o: Object, owner: Object)
    local stats = battle.navi(owner.alliance)
    if stats.navi.forms == nil then
        local identity = owner.identity
        if identity then
            o:add_parts(identity, 1)
        end
        return
    end
    local form = stats.form
    local put_on, identity = form.put_on, form.identity
    if put_on then
        put_on(o)
    elseif identity then
        o:add_parts(identity, 1)
    end
end

return overlays
