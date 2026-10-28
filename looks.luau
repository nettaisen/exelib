--!strict
-- A sprite's look on each console: the two consoles draw some fields their own way, where the original's consoles
-- decide a look by their own side (`sprite:get(field, side)`, `sprite:set(field, value, side)`).

local looks = {}

-- `field` as side 0's console draws it (`side0`) and as side 1's does (`side1`): a palette by whose panel it is, the
-- parts a console hides. Alike, it is every console's.
function looks.by_console(sprite: Sprite, field: string, side0: any, side1: any)
    if side0 == side1 then
        sprite:set(field, side0)
    else
        sprite:set(field, side0, 0)
        sprite:set(field, side1, 1)
    end
end

-- `from`'s `fields` onto `to` as each console draws them: what is drawn as its owner is copies them so (reading a
-- field and setting it would make the local side's console's every console's).
function looks.copy(to: Sprite, from: Sprite, ...: string)
    for _, field in { ... } do
        looks.by_console(to, field, from:get(field, 0), from:get(field, 1))
    end
end

return looks
