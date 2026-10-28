--!strict
-- Attachments, as EXE5 and EXE6 share them (EXE6's actor object #5,
-- `sub_80B8CD8`; EXE5's #5): each game makes its own kind
-- (`attachment.make_kind`). A sprite a navi holds during an attack, such as
-- a bomb before it's thrown or the
-- buster's arm. Visual only, but it takes an actor slot and a place in the
-- update order. It follows its owner's position and visibility, and ends
-- itself once the owner clears the slot it was stored in. See
-- objects-and-player.md §A.2.
--
-- What it shows is a look (`attachment.look { ... }`), a record its user
-- defines; how it animates is the user's too (`attachment.attach(kind,
-- owner, look, slot, { anim = ... })`).

local slot = require("./slot")

local attachment = {}

export type State = {
    slot: Slot,
    look: AttachmentLook,
    anim: number,
    while_dimmed: boolean,
    palette_add: number,
}

-- An attachment's look (see AttachmentLook in types.d.luau).
function attachment.look(spec: AttachmentLook): AttachmentLook
    return new.record("attachment-look", spec)
end

-- (How it animates is an `AttachmentOptions`: its animation, whether it
-- animates while dimmed too, and what is added to its palette, drawn only.)

-- `sub_80B8DA6`, each tick from its init's: at the owner's position less the lift; the owner's visibility, color
-- shader, white flash, alpha and flip; animating, except while paused (or dimmed, unless it animates then too);
-- ended once the slot is cleared (the engine's follow: `Object:follow`).
local WORN = { "color_shader", "white", "alpha", "hflip", "vflip" }

-- What a game's attachments are raised by for who holds them, over their look's (`lifted(owner, side)`; nil: the
-- look's).
export type Lifted = (owner: Object, side: number) -> number?

-- `sub_80B8CF8`.
local function init(me: Object, lifted: Lifted?)
    local s = me.state :: State
    local k = s.look
    local owner = me.related1 :: Object
    local sprite = me.sprite
    sprite:load(k.sprite)
    sprite.shadow = "with_sprite"
    sprite.palette = k.palette + s.palette_add
    me.no_sprite_update = false
    local identity = owner.identity
    -- (Pixels raised by: subtracted from Y and Z.)
    local lift = ((lifted and lifted(owner, me.alliance)) or k.lift or 0) * 0x10000
    local anim = s.anim
    me.anim = anim
    me.anim_loaded = anim
    me.visible = true
    sprite:set_animation(anim)
    local x, z = 0, 0
    if k.by_owner then
        -- It sits at a fixed offset by its owner's identity, not at an
        -- attach point, and not mirrored: where the identity says a held
        -- thing sits (none on base MegaMan, (11, -7) on Gregar Beast Out),
        -- else (0, 13).
        local held = identity and identity.held_offset
        if held then
            x, z = held[1], held[2]
        else
            x, z = 0, 0xD
        end
    elseif k.attach_point then
        x, z = owner:attach_point(k.attach_point)
    end
    me:set_lifecycle("update")
    slot.follow(me, owner, s.slot, {
        offset = Vec3.new(x * 0x10000, -lift, z * 0x10000 - lift),
        looks = WORN,
        visibility = true,
        while_dimmed = s.while_dimmed,
    })
end

-- A game's attachment kind, keyed `id`, raised by its rule (`lifted`; none: by the look's alone).
function attachment.make_kind(id: string, lifted: Lifted?): Kind
    return new.kind {
        id = id,
        pool = "actor",
        state = {
            slot = slot.TYPE,
            look = "record:attachment-look",
            anim = "u8",
            while_dimmed = "bool",
            palette_add = "u8",
        },
        update = function(me: Object)
            if me.lifecycle == "init" then
                init(me, lifted)
            else
                me:free()
            end
        end,
    }
end

-- `sub_80B8E30`: attach `look` (an attachment of `kind`, a game's) to
-- `owner`, stored in `which` (which gets nil if the pool is full). It takes
-- the owner's panel and side; its init places it.
function attachment.attach(kind: Kind, owner: Object, look: AttachmentLook, which: Slot, options: AttachmentOptions?): Object?
    local o = battle.spawn(kind, Vec3.zero)
    if o then
        o.related1 = owner
        o.panel_x, o.panel_y = owner.panel_x, owner.panel_y
        o.alliance, o.flip = owner.alliance, owner.flip
        o.run_while_paused = true
        o.run_while_dimmed = true
        local s = o.state :: State
        s.slot = which
        s.look = look
        local opt: AttachmentOptions = options or {}
        s.anim = opt.anim or 0
        s.while_dimmed = opt.while_dimmed or false
        s.palette_add = opt.palette_add or 0
    end
    slot.fill(owner, which, o)
    return o
end

-- A shooting chip's `hold` (a ShooterLook's) with attachments of `kind`: the navi holds the look in the slot, its
-- animation by the holder's AI index from `arm_anims` (from 0: the action's table, where a navi a player operates may
-- hold its own: EXE6's cannon's `off_80EBD80`, its AirShot's `off_80EC944`). With `players_only`, anyone but a player
-- holds the plain one, 0 (the cannon's `sub_80EBD68`; AirShot's `sub_80EC934` asks no such thing).
function attachment.holder(kind: Kind, arm_anims: { number }, players_only: boolean?): (me: Object, look: AttachmentLook, which: Slot) -> ()
    return function(me: Object, look: AttachmentLook, which: Slot)
        local anim = 0
        if not players_only or me.actor_type == "player" then
            local a = arm_anims[me.ai_index + 1]
            if a == nil then
                error(string.format("AI index %d reads past the arms' table", me.ai_index))
            end
            anim = a
        end
        attachment.attach(kind, me, look, which, { anim = anim })
    end
end

return attachment
