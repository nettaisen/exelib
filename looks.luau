--!strict
-- A sprite's look on each console: the two consoles draw some fields their own way, where the original's consoles
-- decide a look by their own side (`sprite:get(field, side)`, `sprite:set(field, value, side)`). And the looks the
-- content's definitions give: a navi's sprite in a form, what an identity (the original's NameID) is drawn as, and an
-- object made to look as one.

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

-- An identity's actor type (its actor record's): its own, else its class's (a player's for a player's, a navi's for a
-- navi's), else a virus's, as the original's NameID 0 is for an object with none.
function looks.actor_type(identity: Identity?): ActorType
    if identity == nil then
        return "virus"
    end
    if identity.actor_type ~= nil then
        return identity.actor_type
    end
    if identity.class == "player" then
        return "player"
    elseif identity.class == "navi" then
        return "navi"
    end
    return "virus"
end

-- `sub_800FC9E`: the battle sprite of `navi` in `form`: its form's if it changes form (it has `forms`), else its own.
function looks.navi_sprite(navi: NaviDef, form: FormDef): SpriteAsset
    return if navi.forms ~= nil then form.sprite else navi.sprite
end

-- `sub_800F26C`: the sprite object `o`'s identity gives: a field object's look's (nil: none), a navi's or a form's own
-- sprite (its side's navi's, or the form it is in). An error for an identity the content has no look for (a virus's).
function looks.name_sprite(o: Object): SpriteAsset?
    local identity = o.identity
    if identity ~= nil and identity.class == "field_object" then
        local look = identity.look
        if look == nil then
            error(`identity {identity.id} has no look in the content (sub_800F26C)`)
        end
        return look.sprite
    end
    local stats = battle.navi(o.alliance)
    if identity ~= nil and identity == stats.form.identity then
        return stats.form.sprite
    elseif identity ~= nil and identity == stats.navi.identity then
        return stats.navi.sprite
    end
    error(`identity {identity and identity.id} has no look in the content (sub_800F26C)`)
end

-- `sub_800F29C` with `sub_800FC9E` or `sub_800F26C`, then `sprite:load`: the sprite `like` is drawn with, a stand-in
-- for a chip's user: a player's navi's by its side's navi and form; a field object's by its identity's look. (Other
-- identities' sprites, viruses' and bosses', aren't in the content: no netbattle object stands in for one.)
function looks.load_like(sprite: Sprite, like: Object)
    local identity = like.identity
    if looks.actor_type(identity) == "player" then
        local stats = battle.navi(like.alliance)
        sprite:load(looks.navi_sprite(stats.navi, stats.form))
        return
    end
    local look = if identity ~= nil then identity.look else nil
    local id = if look ~= nil then look.sprite else nil
    if id == nil then
        local key = identity and identity.id
        error(`sub_800F26C: identity {key} has no sprite in the content (a stand-in copies a player)`)
    end
    sprite:load(id)
end

-- `sub_800FC9E` and a form change's load: the navi's sprite in `form` (its side's navi's), its animation 0 from the
-- start, its shadow on the ground, facing its way, white.
function looks.load_form_sprite(me: Object, form: FormDef)
    local sprite = me.sprite
    sprite:load(looks.navi_sprite(battle.navi(me.alliance).navi, form))
    sprite.shadow = "ground"
    sprite:set_flip(bit32.bxor(me.alliance, me.flip))
    sprite.white = true
    me.anim, me.anim_loaded = 0, 0xFF
    sprite:set_animation(0)
end

-- MstrCros's Crosses (`sub_80BE7BC`), Darkness's Dark MegaMan (`sub_80BF710`): `me` takes the identity of `navi` in
-- `form` (the form's; in a form without one, as the base form, the navi's), its sprite (a ground shadow, animation 0
-- loaded by the next sprite update) and its palette.
function looks.wear_form_image(me: Object, navi: NaviDef, form: FormDef)
    local identity = form.identity or navi.identity
    me.sprite:load(form.sprite)
    me.identity = identity
    me.anim, me.anim_loaded = 0, 0xFF
    me.sprite.shadow = "ground"
    me.sprite.palette = form.palette or 0
end

-- DustMan's take (`sub_80BC100`): what field object `o` would look like thrown back as junk: its identity, which its
-- taker keeps (`looks.wear_absorbed`); nil for the objects it leaves (`sub_800F486`: an identity with `scrap = false`)
-- and an object with no identity.
function looks.absorbed(o: Object): Identity?
    local identity = o.identity
    if identity ~= nil and identity.scrap ~= false then
        return identity
    end
    return nil
end

-- `sub_80DBB64`: `me` wears an absorbed look (`looks.absorbed`): the sprite, shown, a shadow on the ground if the look
-- has one (else drawn with the sprite), its animation and palette, flipped by its side unless the look keeps its own;
-- false when the look has no sprite. An error for an identity that isn't a field object's with a look (the original
-- would take an actor's sprite, `enemy_getStruct1`, which no field object is).
function looks.wear_absorbed(me: Object, identity: Identity): boolean
    local look = identity.look
    if identity.class ~= "field_object" or look == nil then
        error(`identity {identity.id} has no absorbed look (enemy_getStruct1's sprite)`)
    end
    local id = look.sprite
    if id == nil then
        return false
    end
    local sprite = me.sprite
    sprite:load(id)
    me.visible = true
    local anim = look.anim or 0
    me.anim, me.anim_loaded = anim, anim
    sprite.shadow = if look.shadow then "ground" else "with_sprite"
    sprite:set_animation(anim)
    sprite.palette = look.palette or 0
    -- (The time bombs' looks keep their own flip, and the original sets a drawing bit instead: presentation.)
    if not look.keeps_flip then
        sprite:set_flip(me.alliance)
    end
    return true
end

return looks
