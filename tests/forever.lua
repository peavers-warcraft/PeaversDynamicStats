--------------------------------------------------------------------------------
-- src/Stats.lua on WoW Forever, driven against stand-in globals.
--
--   Run: lua tests/forever.lua        (from the addon root)
--
-- Forever runs retail's client with vanilla's stats, and nobody can open the
-- game from CI. What can be checked without it: that Forever is offered the
-- stats its character sheet has and not the ones it lacks, that Hit, Crit,
-- Haste and Expertise come out as the sheet's best-of-melee/ranged/spell figure,
-- and that once the client turns stats secret in combat nothing compares or adds
-- a secret value (which errors in game) - the bars keep reading the figure
-- chosen at the pull, or hold its total when it was a sum.
--
-- Not addon code, and not packaged. It overwrites globals on purpose to drive
-- the file under test.
--------------------------------------------------------------------------------

local failures = 0

local function check(label, got, want)
    if got ~= want then
        failures = failures + 1
        print(("  FAIL %s: got %s, want %s"):format(label, tostring(got), tostring(want)))
    end
end

-- A secret value: displayable, but any comparison or arithmetic is an error,
-- as in game. Each remembers which API produced it.
local SECRET = {}
local function refuse() error("arithmetic or comparison on a secret value", 2) end
SECRET.__add, SECRET.__sub, SECRET.__mul, SECRET.__div = refuse, refuse, refuse, refuse
SECRET.__lt, SECRET.__le, SECRET.__eq, SECRET.__unm = refuse, refuse, refuse, refuse
local function secret(source) return setmetatable({ source = source }, SECRET) end
local function isSecret(v) return getmetatable(v) == SECRET end

-- string.format is one of the few things the game lets a secret pass through.
local plainFormat = string.format
---@diagnostic disable-next-line: duplicate-set-field
string.format = function(fmt, ...) -- luacheck: ignore 122
    local args = { ... }
    for i = 1, select("#", ...) do
        if isSecret(args[i]) then args[i] = 0 end
    end
    return plainFormat(fmt, unpack(args, 1, select("#", ...)))
end

-- The character, as plain numbers. `inCombat` turns every stat read secret.
local sheet, inCombat, classToken

local function stat(name, value)
    return function(...)
        if inCombat then return secret(name) end
        return value(...)
    end
end

local function install(forever)
    _G.issecretvalue = isSecret
    ---@diagnostic disable-next-line: missing-fields
    _G.PeaversCommons = {
        Require = function() return forever ~= nil end,
        Client = { isForever = forever == true },
    }
    _G.UnitClass = function() return classToken, classToken end
    _G.GetCombatRatingBonus = stat("GetCombatRatingBonus", function(i) return sheet.bonus[i] or 0 end)
    _G.GetCombatRating = stat("GetCombatRating", function(i) return sheet.rating[i] or 0 end)
    _G.GetHitModifier = stat("GetHitModifier", function() return sheet.hitMod end)
    _G.GetOffhandHitModifier = stat("GetOffhandHitModifier", function() return sheet.offhandHitMod end)
    _G.GetRangedHitModifier = stat("GetRangedHitModifier", function() return sheet.rangedHitMod end)
    _G.GetSpellHitModifier = stat("GetSpellHitModifier", function() return sheet.spellHitMod end)
    _G.GetCritChance = stat("GetCritChance", function() return sheet.meleeCrit end)
    _G.GetRangedCritChance = stat("GetRangedCritChance", function() return sheet.rangedCrit end)
    _G.GetSpellCritChance = stat("GetSpellCritChance", function() return sheet.spellCrit end)
    _G.GetMeleeHaste = stat("GetMeleeHaste", function() return sheet.meleeHaste end)
    _G.GetRangedHaste = stat("GetRangedHaste", function() return sheet.rangedHaste, sheet.quiverHaste end)
    _G.UnitSpellHaste = stat("UnitSpellHaste", function() return sheet.spellHaste end)
    _G.GetExpertise = stat("GetExpertise", function() return sheet.mhExp, sheet.ohExp, sheet.rangedExp end)
    _G.UnitStat = stat("UnitStat", function(_, i)
        local v = sheet.attr[i] or 0
        return v, v, 0, 0
    end)
    _G.C_Attributes, _G.C_Stats = nil, nil
    _G.GetHaste = function() error("retail's GetHaste is not how Forever reads haste") end

    local PDS = { L = setmetatable({}, { __index = function(_, k) return k end }),
                  Config = {}, Utils = { FormatPercent = function(v) return ("%.2f%%"):format(v) end } }
    assert(loadfile("src/Stats.lua"))("PeaversDynamicStats", PDS)
    PDS.Stats:InitializeStatNames()
    return PDS.Stats
end

local function fresh(class)
    classToken = class
    inCombat = false
    sheet = {
        bonus = {}, rating = {}, attr = { [5] = 0 },
        hitMod = 0, offhandHitMod = 0, rangedHitMod = 0, spellHitMod = 0,
        meleeCrit = 0, rangedCrit = 0, spellCrit = 0,
        meleeHaste = 0, rangedHaste = 0, quiverHaste = 0, spellHaste = 0,
        mhExp = 0, ohExp = 0, rangedExp = 0,
    }
end

local function offers(Stats)
    local set = {}
    for _, s in ipairs(Stats.STAT_ORDER) do set[s] = true end
    return set
end

-- Reads a stat the way a bar does: value, rating and the text, all of which
-- must survive secret values without an error.
local function read(Stats, statType)
    local ok, value = pcall(Stats.GetValue, Stats, statType)
    if not ok then return "error: " .. tostring(value) end
    local okR, rating = pcall(Stats.GetRating, Stats, statType)
    if not okR then return "error: " .. tostring(rating) end
    local okT, text = pcall(Stats.GetDisplayValue, Stats, statType, value, true)
    if not okT then return "error: " .. tostring(text) end
    return value, rating, text
end

-- 1. Which stats each client is offered --------------------------------------

fresh("WARRIOR")
local Stats = install(true)
local set = offers(Stats)
for _, s in ipairs({ "HIT", "CRIT", "HASTE", "EXPERTISE", "SPIRIT", "DODGE", "PARRY", "BLOCK", "STRENGTH" }) do
    check("forever offers " .. s, set[s], true)
end
for _, s in ipairs({ "MASTERY", "VERSATILITY", "VERSATILITY_DAMAGE_REDUCTION", "LEECH", "AVOIDANCE", "SPEED" }) do
    check("forever does not offer " .. s, set[s], nil)
end
check("Spirit reads as an attribute, not a percent", Stats:IsPrimaryStat("SPIRIT"), true)
check("Hit has a name", Stats:GetName("HIT"), "STAT_HIT")

fresh("WARRIOR")
set = offers(install(false))
check("retail still offers MASTERY", set.MASTERY, true)
check("retail does not offer HIT", set.HIT, nil)
check("retail does not offer SPIRIT", set.SPIRIT, nil)

-- An older Commons (no revision 4): keep the retail set rather than guess.
fresh("WARRIOR")
set = offers(install(nil))
check("old Commons keeps the retail set", set.MASTERY, true)

-- 2. The character sheet's figure, out of combat ------------------------------

fresh("WARRIOR")
Stats = install(true)
sheet.meleeCrit, sheet.rangedCrit, sheet.spellCrit = 12.5, 8, 3
sheet.rating[9], sheet.rating[11] = 140, 0
local value, rating = read(Stats, "CRIT")
check("warrior crit is melee crit", value, 12.5)
check("warrior crit rating is melee", rating, 140)

fresh("MAGE")
Stats = install(true)
sheet.meleeCrit, sheet.rangedCrit, sheet.spellCrit = 5, 5, 9
sheet.rating[11] = 56
value, rating = read(Stats, "CRIT")
check("mage crit is spell crit", value, 9)
check("mage crit rating is spell", rating, 56)

-- Hit is rating plus talents, best of melee, offhand, ranged and spell.
fresh("ROGUE")
Stats = install(true)
sheet.bonus[6], sheet.hitMod, sheet.offhandHitMod = 3, 5, 2
sheet.bonus[8], sheet.spellHitMod = 1, 0
value = read(Stats, "HIT")
check("rogue hit is melee rating + Precision", value, 8)

-- 3. In combat, where every stat read is secret --------------------------------

-- Crit is one API per figure: keep reading the one chosen at the pull, live.
fresh("WARRIOR")
Stats = install(true)
sheet.meleeCrit, sheet.spellCrit = 12.5, 3
read(Stats, "CRIT")
inCombat = true
local _, text
value, _, text = read(Stats, "CRIT")
check("crit in combat does not error", type(text), "string")
check("crit in combat is live", isSecret(value), true)
check("crit in combat stays on melee", isSecret(value) and value.source, "GetCritChance")

-- Hit is a sum, so in combat it holds its total from the pull.
fresh("ROGUE")
Stats = install(true)
sheet.bonus[6], sheet.hitMod = 3, 5
read(Stats, "HIT")
inCombat = true
value, _, text = read(Stats, "HIT")
check("hit in combat does not error", type(text), "string")
check("hit in combat holds the pull's total", value, 8)

-- Ranged haste with a quiver is a sum too; without one it reads live.
fresh("HUNTER")
Stats = install(true)
sheet.rangedHaste, sheet.quiverHaste, sheet.meleeHaste = 10, 15, 0
read(Stats, "HASTE")
inCombat = true
value = read(Stats, "HASTE")
check("hunter haste with a quiver holds 25", value, 25)

fresh("HUNTER")
Stats = install(true)
sheet.rangedHaste, sheet.quiverHaste = 10, 0
read(Stats, "HASTE")
inCombat = true
value = read(Stats, "HASTE")
check("hunter haste without a quiver is live ranged haste", isSecret(value) and value.source, "GetRangedHaste")

-- A reload mid-fight: nothing was ever read plainly, so go by class.
fresh("MAGE")
Stats = install(true)
inCombat = true
value, _, text = read(Stats, "HASTE")
check("mage haste after a combat reload does not error", type(text), "string")
check("mage haste after a combat reload is spell haste", isSecret(value) and value.source, "UnitSpellHaste")

fresh("PRIEST")
Stats = install(true)
inCombat = true
_, _, text = read(Stats, "HIT")
check("priest hit after a combat reload does not error", type(text), "string")

-- Expertise in combat: one call, so live.
fresh("WARRIOR")
Stats = install(true)
sheet.mhExp, sheet.ohExp = 2, 1
check("expertise out of combat is main hand", (read(Stats, "EXPERTISE")), 2)
inCombat = true
value = read(Stats, "EXPERTISE")
check("expertise in combat is live", isSecret(value), true)

-- Spirit is UnitStat index 5.
fresh("PRIEST")
Stats = install(true)
sheet.attr[5] = 212
check("spirit", (read(Stats, "SPIRIT")), 212)
inCombat = true
_, _, text = read(Stats, "SPIRIT")
check("spirit in combat does not error", type(text), "string")

if failures == 0 then
    print("all Forever stat checks passed")
else
    print(failures .. " failure(s)")
    os.exit(1)
end
