--!strict
-- Who sees an object, on each console: the original's consoles each clear an object's `VISIBLE` by rules of their own
-- side (`object:get("visible", side)`, `object:set("visible", on, side)`).

local visibility = {}

-- `sub_800EB6C` on each console: hidden from a player whose navi is blind if it is the other side's, on top of what
-- each console shows of it now (`battle.sees`).
function visibility.hide_from_blind(o: Object)
    for side = 0, 1 do
        o:set("visible", o:get("visible", side) and battle.sees(side, o.alliance), side)
    end
end

-- Seen by whoever sees `owner`: what follows its owner's visibility.
function visibility.copy(o: Object, owner: Object)
    for side = 0, 1 do
        o:set("visible", owner:get("visible", side), side)
    end
end

-- `sub_80169BE`: shown unless the battle is dimmed, then hidden from a player whose navi is blind if it is the other
-- side's. (It reads the navi's status through its collision data alone: a navi with none sees, unlike
-- `battle.sees`.)
function visibility.update(o: Object)
    if not battle.dimmed() then
        o.visible = true
    end
    local own = bit32.band(o.alliance, 1)
    for side = 0, 1 do
        local navi = battle.player(side)
        local blind = side ~= own and navi ~= nil and navi.has_collision and navi:status("blind")
        o:set("visible", o:get("visible", side) and not blind, side)
    end
end

return visibility
