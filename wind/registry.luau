--!strict
-- Each side's wind (EXE6's battle state +0xC0 + 4 × side, who placed it at +0xC8; EXE4's +0x88): the object blowing
-- for the side, one at a time (Wind and Fan's fan, @exelib/wind/fan; EXE4's WindSoul's own). Each game keeps the two
-- sides' slots in its rules' state and passes its accessor (`WindSlots`), the side's slot.

local registry = {}

-- `sub_80E541A`: `me` is `side`'s wind, placed by `source`. The wind there before is destroyed at once (`sub_80E5410`:
-- its state word goes to destroy, and its first variable, a fan's record, to 0, which nothing reads after). (The slot
-- keeps what it holds after its object is gone, until another takes it or it is cleared.)
function registry.set(slots: WindSlots, me: Object, side: number, source: WindSource)
    local slot = slots(side)
    local old = slot.object
    if old ~= nil then
        old:set_lifecycle("destroy")
    end
    slot.object, slot.source = me, source
end

-- `sub_80E544C`: `me` is no side's wind.
function registry.clear(slots: WindSlots, me: Object)
    for side = 0, 1 do
        local slot = slots(side)
        if slot.object == me then
            slot.object, slot.source = nil, "obstacle"
        end
    end
end

return registry
