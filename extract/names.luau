--!strict
-- The asset names from a game's compat tables (docs/design/extraction-recipes.md §4.3): what assets.toml says, joined
-- by the game's recipe with the tables beside it. A number may belong to one name only, as the compat crates check
-- as they read the tables (with their messages).

local names = {}

-- The keys of a table, in order.
function names.sorted(t: { [string]: any }): { string }
    local out: { string } = {}
    for k in t do
        table.insert(out, k)
    end
    table.sort(out)
    return out
end

-- A number as the compat crates say one in a message.
local function said(v: any): string
    if type(v) == "number" then
        return string.format("0x%X", v)
    end
    return string.format("%q", tostring(v))
end

-- What a check says of two keys with one number: the earlier key (in key order), the later and the number.
export type Said = (earlier: string, later: string, v: any) -> string

-- Fail if two keys of `entries` (key to number, in key order; `number` gives an entry's) have one number, said by
-- `say` (a game's compat crate's wording), else as exe6-compat says it: `what: a and b are both 0x1A`.
function names.unique(what: string, entries: { [string]: any }, number: ((any) -> any)?, say: Said?)
    local seen: { [any]: string } = {}
    for _, key in names.sorted(entries) do
        local v = entries[key]
        if number then
            v = number(v)
        end
        local other = seen[v]
        if other ~= nil then
            error(if say then say(other, key, v) else string.format("%s: %s and %s are both %s", what, other, key, said(v)), 0)
        end
        seen[v] = key
    end
end

-- A table of name to number, turned round: number to name.
function names.by_number(t: { [string]: number }): { [number]: string }
    local out: { [number]: string } = {}
    for _, k in names.sorted(t) do
        out[t[k]] = k
    end
    return out
end

-- assets.toml's sprites ("cc-ii": the category's byte offset in the sprite list and the index, in hex) by category,
-- then index.
function names.sprites(t: { [string]: string }): { [number]: { [number]: string } }
    local out: { [number]: { [number]: string } } = {}
    for _, name in names.sorted(t) do
        local id = t[name]
        local c, i = string.match(id, "^(%x%x)%-(%x%x)$")
        if c == nil or i == nil then
            error(string.format("assets.toml: sprite %s is %q, not \"cc-ii\"", name, id), 0)
        end
        local category, index = tonumber(c, 16) :: number, tonumber(i, 16) :: number
        out[category] = out[category] or {}
        out[category][index] = name
    end
    return out
end

-- A key as the pack names an asset by it: its own part (`exe6:cannon` is `cannon`).
function names.key(k: string): string
    return string.match(k, "^[^:]*:(.*)$") or k
end

return names
