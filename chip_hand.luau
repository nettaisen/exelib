--!strict
-- A side's chip hand, over its entries (`battle.hand_entry`, `battle.set_hand_entry`): what the games' chips and forms
-- read of it and add to it.

local chip_hand = {}

-- The chip of the entry at i of the side's hand, if any.
function chip_hand.chip(side: number, i: number): Chip?
    return battle.hand_entry(side, i, "chip")
end

-- The side's hand has a chip at i and it does damage (its record's "has_damage" flag).
function chip_hand.damages(side: number, i: number): boolean
    local chip = chip_hand.chip(side, i)
    return chip ~= nil and chip.flags ~= nil and table.find(chip.flags, "has_damage") ~= nil
end

-- A bonus of the entry at i of the side's hand raised by `n`, wrapping as its halfword does: its Atk+ bonus (Otenko,
-- ColorPt, EXE5's NapalmSoul and NumberMan's dice) or its charge bonus (EXE4's souls' status resets, 0x0800E1CA).
function chip_hand.add_bonus(side: number, i: number, field: "attack_bonus" | "charge_bonus", n: number)
    battle.set_hand_entry(side, i, field, int.u16(battle.hand_entry(side, i, field) + n))
end

-- EXE5's Jealousy (0x080E4596): the chips left in the side's hand, from its cursor to its first empty entry.
function chip_hand.left(side: number): number
    local i = battle.hand_cursor(side)
    local n = 0
    while chip_hand.chip(side, i + n) ~= nil do
        n += 1
    end
    return n
end

return chip_hand
