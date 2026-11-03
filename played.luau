--!strict
-- TEMPORARY, while actions move from their sprites' timing to step counts of their own: whether `sprite` has
-- stepped `steps` times since its animation started (`period`: and, for a looping animation, a whole number of
-- loops of `period` steps since), checked against the animation's end (`frame_flags` 0x80) on every call. A
-- difference is an error naming the animation and the step. Every call becomes `sprite.steps >= steps` once the
-- engine no longer times sprites, and this module goes.

local played = {}

function played.ended(sprite: Sprite, steps: number, period: number?): boolean
    local s = sprite.steps
    local ended = s >= steps and (period == nil or (s - steps) % period == 0)
    local flag = bit32.btest(sprite.frame_flags, 0x80)
    if ended ~= flag then
        error(
            string.format(
                "animation %d: %d steps%s say %s at step %d, the animation's end says %s",
                sprite.animation,
                steps,
                if period then string.format(" (looping every %d)", period) else "",
                tostring(ended),
                s,
                tostring(flag)
            ),
            2
        )
    end
    return ended
end

return played
