--!strict
-- What a soul does at the custom screen, as EXE5 and EXE4 name it: a soul's form's `custom`, a record of this type
-- (each game's own `SoulCustom`, its types.d.luau), which the game's soul forms make and its rules' custom screen asks
-- while the side's navi is in the soul (the game's rules/souls/custom).

local custom = {}

local SOUL_CUSTOM = schema.record_type("soul-custom")
custom.SOUL_CUSTOM = SOUL_CUSTOM

return custom
