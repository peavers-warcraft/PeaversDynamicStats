local _, PDS = ...

-- Initialize Stats namespace if needed
PDS.Stats = PDS.Stats or {}
local Stats = PDS.Stats

--------------------------------------------------------------------------------
-- 12.0 API Compatibility Layer
-- WoW 12.0 (Midnight) introduces "Secret Values" that restrict certain combat
-- data. Player stats are "fully non-secret" but we add defensive wrappers
-- for graceful degradation if APIs change or fail.
--------------------------------------------------------------------------------

-- Check if a value is a "secret value" (12.0+ feature)
local function IsSecretValue(value)
    -- issecretvalue is a new 12.0 API that returns true for restricted values
    if issecretvalue then
        return issecretvalue(value)
    end
    return false
end

-- Safely call an API function with error handling and secret value detection
-- 12.0.5+: Returns secret values as-is for pass-through to display APIs
-- (string.format, FontString:SetText, StatusBar:SetValue all accept secrets)
local function SafeGetValue(apiFunc, ...)
    if not apiFunc then return nil end

    local success, result = pcall(apiFunc, ...)
    if not success then
        -- API call failed (may happen if API is removed/changed)
        return nil
    end

    -- 12.0.5+: Stat APIs return secret values during combat.
    -- Return them as-is so callers can pass through to display widgets.
    if IsSecretValue(result) then
        return result
    end

    -- Ensure we return a number, not a table or other type
    if type(result) ~= "number" then
        return nil
    end

    return result
end

-- Safely call an API function that returns multiple values
-- 12.0.5+: Returns secret values as-is for pass-through
local function SafeGetMultiValue(apiFunc, ...)
    if not apiFunc then return nil end

    local results = {pcall(apiFunc, ...)}
    local success = table.remove(results, 1)

    if not success then
        return nil
    end

    -- 12.0.5+: Return secrets as-is (callers must check with IsSecretValue)
    return unpack(results)
end

-- Safe fallback helper: returns val if it's a secret or non-nil, otherwise returns default.
-- Unlike `val or default`, this doesn't boolean-test val (which errors on secrets).
local function DefaultIfNil(val, default)
    if IsSecretValue(val) then return val end
    if val ~= nil then return val end
    return default
end

--------------------------------------------------------------------------------
-- StatAPI Wrapper Layer
-- Provides safe, fallback-enabled access to all stat APIs
--------------------------------------------------------------------------------

local StatAPI = {}

-- Primary stat wrappers (using UnitStat)
function StatAPI.GetUnitStat(statIndex)
    local base, stat, posBuff, negBuff = SafeGetMultiValue(UnitStat, "player", statIndex)
    -- 12.0.5+: If values are secret, return them as-is (can't do arithmetic)
    if IsSecretValue(base) then
        return base, stat, posBuff, negBuff
    end
    if base == nil then
        return 0, 0, 0, 0
    end
    return base, stat or base, posBuff or 0, negBuff or 0
end

-- Secondary stat wrappers (use DefaultIfNil instead of `or 0` to avoid boolean-testing secrets)
function StatAPI.GetHaste()
    return DefaultIfNil(SafeGetValue(GetHaste), 0)
end

function StatAPI.GetCritChance()
    -- Try spell crit first (most accurate for casters), then generic crit
    local val = SafeGetValue(GetSpellCritChance, 2)
    if IsSecretValue(val) or val ~= nil then return val end
    return DefaultIfNil(SafeGetValue(GetCritChance), 0)
end

function StatAPI.GetMastery()
    local val = SafeGetValue(GetMasteryEffect)
    if IsSecretValue(val) or val ~= nil then return val end
    return DefaultIfNil(SafeGetValue(GetMastery), 0)
end

function StatAPI.GetSpeed()
    return DefaultIfNil(SafeGetValue(GetSpeed), 0)
end

function StatAPI.GetLifesteal()
    return DefaultIfNil(SafeGetValue(GetLifesteal), 0)
end

function StatAPI.GetAvoidance()
    return DefaultIfNil(SafeGetValue(GetAvoidance), 0)
end

function StatAPI.GetDodgeChance()
    return DefaultIfNil(SafeGetValue(GetDodgeChance), 0)
end

function StatAPI.GetParryChance()
    return DefaultIfNil(SafeGetValue(GetParryChance), 0)
end

function StatAPI.GetBlockChance()
    return DefaultIfNil(SafeGetValue(GetBlockChance), 0)
end

-- Combat rating wrappers
function StatAPI.GetCombatRating(ratingIndex)
    return DefaultIfNil(SafeGetValue(GetCombatRating, ratingIndex), 0)
end

function StatAPI.GetCombatRatingBonus(ratingIndex)
    return DefaultIfNil(SafeGetValue(GetCombatRatingBonus, ratingIndex), 0)
end

-- Expose StatAPI and secret value helpers for other modules
Stats.StatAPI = StatAPI
Stats.IsSecretValue = IsSecretValue

--------------------------------------------------------------------------------
-- Combat State Caching
-- Cache values that may become unavailable during combat (like aura data)
--------------------------------------------------------------------------------

local combatCache = {
    talentAdjustments = {},
    lastUpdateTime = 0,
    CACHE_DURATION = 1.0, -- seconds
}

-- Update cache if stale and not in combat
local function UpdateCacheIfNeeded()
    local now = GetTime()
    if (now - combatCache.lastUpdateTime) > combatCache.CACHE_DURATION then
        if not InCombatLockdown() then
            combatCache.lastUpdateTime = now
            return true -- Cache should be updated
        end
    end
    return false
end

-- Expose cache functions
Stats.combatCache = combatCache
Stats.UpdateCacheIfNeeded = UpdateCacheIfNeeded

-- Combat Rating constants - updated for 11.0.0+
Stats.COMBAT_RATINGS = {
    CR_WEAPON_SKILL = 1,         -- Removed in patch 6.0.2
    CR_DEFENSE_SKILL = 2,
    CR_DODGE = 3,
    CR_PARRY = 4,
    CR_BLOCK = 5,
    CR_HIT_MELEE = 6,
    CR_HIT_RANGED = 7,
    CR_HIT_SPELL = 8,
    CR_CRIT_MELEE = 9,
    CR_CRIT_RANGED = 10,
    CR_CRIT_SPELL = 11,
    CR_MULTISTRIKE = 12,         -- Formerly CR_HIT_TAKEN_MELEE until patch 6.0.2
    CR_READINESS = 13,           -- Formerly CR_HIT_TAKEN_SPELL until patch 6.0.2
    CR_SPEED = 14,               -- Formerly CR_HIT_TAKEN_SPELL until patch 6.0.2
    CR_RESILIENCE_CRIT_TAKEN = 15,
    CR_RESILIENCE_PLAYER_DAMAGE_TAKEN = 16,
    CR_LIFESTEAL = 17,           -- Formerly CR_CRIT_TAKEN_SPELL until patch 6.0.2
    CR_HASTE_MELEE = 18,
    CR_HASTE_RANGED = 19,
    CR_HASTE_SPELL = 20,
    CR_AVOIDANCE = 21,           -- Formerly CR_WEAPON_SKILL_MAINHAND until patch 6.0.2
    -- CR_WEAPON_SKILL_OFFHAND = 22, -- Removed in patch 6.0.2
    -- CR_WEAPON_SKILL_RANGED = 23,  -- Removed in patch 6.0.2
    CR_EXPERTISE = 24,
    CR_ARMOR_PENETRATION = 25,
    CR_MASTERY = 26,
    -- CR_PVP_POWER = 27,           -- Removed in patch 6.0.2
    -- Index 28 is missing or unused
    CR_VERSATILITY_DAMAGE_DONE = 29,
    CR_VERSATILITY_DAMAGE_TAKEN = 30,
    -- CR_SPEED is now 14 instead of 31
    -- CR_LIFESTEAL is now 17 instead of 32
}

-- Stat types - updated for 11.0.0+
Stats.STAT_TYPES = {
    -- Primary stats
    STRENGTH = "STRENGTH",
    AGILITY = "AGILITY",
    INTELLECT = "INTELLECT",
    STAMINA = "STAMINA",
    -- Virtual primary stat that auto-resolves to the active spec's primary
    -- (Strength/Agility/Intellect). Lets one config profile work on every alt.
    PRIMARY_STAT = "PRIMARY_STAT",

    -- Secondary stats
    HASTE = "HASTE",
    CRIT = "CRIT",
    MASTERY = "MASTERY",
    VERSATILITY = "VERSATILITY",
    VERSATILITY_DAMAGE_DONE = "VERSATILITY_DAMAGE_DONE",
    VERSATILITY_DAMAGE_REDUCTION = "VERSATILITY_DAMAGE_REDUCTION",
    SPEED = "SPEED",
    LEECH = "LEECH",
    AVOIDANCE = "AVOIDANCE",

    -- Combat ratings
    DEFENSE = "DEFENSE",
    DODGE = "DODGE",
    PARRY = "PARRY",
    BLOCK = "BLOCK",
    ARMOR_PENETRATION = "ARMOR_PENETRATION"
}

-- Primary stat lookup for display/bar logic
Stats.PRIMARY_STATS = {
    [Stats.STAT_TYPES.STRENGTH] = true,
    [Stats.STAT_TYPES.AGILITY] = true,
    [Stats.STAT_TYPES.INTELLECT] = true,
    [Stats.STAT_TYPES.STAMINA] = true,
    [Stats.STAT_TYPES.PRIMARY_STAT] = true,
}

function Stats:IsPrimaryStat(statType)
    return Stats.PRIMARY_STATS[statType] == true
end

-- Spec ID → primary stat lookup. GetSpecializationInfo's first return (the
-- spec ID) is stable across WoW versions; the 6th return (primaryStat) is
-- not reliable in 12.0, so we map directly from the well-known spec IDs.
local SPEC_PRIMARY_STAT = {
    -- Death Knight
    [250] = "STRENGTH",  [251] = "STRENGTH",  [252] = "STRENGTH",
    -- Demon Hunter
    [577] = "AGILITY",   [581] = "AGILITY",
    -- Druid (Balance/Resto INT, Feral/Guardian AGI)
    [102] = "INTELLECT", [103] = "AGILITY",   [104] = "AGILITY",   [105] = "INTELLECT",
    -- Evoker
    [1467] = "INTELLECT", [1468] = "INTELLECT", [1473] = "INTELLECT",
    -- Hunter
    [253] = "AGILITY",   [254] = "AGILITY",   [255] = "AGILITY",
    -- Mage
    [62]  = "INTELLECT", [63]  = "INTELLECT", [64]  = "INTELLECT",
    -- Monk (Brewmaster/Windwalker AGI, Mistweaver INT)
    [268] = "AGILITY",   [269] = "AGILITY",   [270] = "INTELLECT",
    -- Paladin (Holy INT, Prot/Ret STR)
    [65]  = "INTELLECT", [66]  = "STRENGTH",  [70]  = "STRENGTH",
    -- Priest
    [256] = "INTELLECT", [257] = "INTELLECT", [258] = "INTELLECT",
    -- Rogue
    [259] = "AGILITY",   [260] = "AGILITY",   [261] = "AGILITY",
    -- Shaman (Ele/Resto INT, Enhance AGI)
    [262] = "INTELLECT", [263] = "AGILITY",   [264] = "INTELLECT",
    -- Warlock
    [265] = "INTELLECT", [266] = "INTELLECT", [267] = "INTELLECT",
    -- Warrior
    [71]  = "STRENGTH",  [72]  = "STRENGTH",  [73]  = "STRENGTH",
}

-- Class-based fallback when no specialization is active (low-level characters
-- or hybrid classes before spec selection).
local CLASS_FALLBACK_PRIMARY = {
    WARRIOR = "STRENGTH", PALADIN = "STRENGTH", DEATHKNIGHT = "STRENGTH",
    HUNTER = "AGILITY", ROGUE = "AGILITY", MONK = "AGILITY",
    DEMONHUNTER = "AGILITY", DRUID = "AGILITY", SHAMAN = "AGILITY",
    MAGE = "INTELLECT", WARLOCK = "INTELLECT", PRIEST = "INTELLECT",
    EVOKER = "INTELLECT",
}

-- Resolves PRIMARY_STAT to the active spec's actual primary stat type.
-- Treats specID of 0 or nil as "spec API not ready" (happens during
-- ADDON_LOADED before PLAYER_ENTERING_WORLD); the PEW handler in Main.lua
-- recreates bars once the spec is known, so the class fallback is only a
-- safety net.
function Stats:ResolvePrimaryStatType()
    local function isValid(id) return id and id ~= 0 end
    local specID
    if PDS.Config and PDS.Config.GetSpecialization then
        local id = PDS.Config:GetSpecialization()
        if isValid(id) then
            specID = id
        elseif isValid(PDS.Config.currentSpec) then
            specID = PDS.Config.currentSpec
        end
    end
    if not specID then
        local specIndex = GetSpecialization and GetSpecialization()
        if specIndex and specIndex ~= 0 then
            local id = GetSpecializationInfo(specIndex)
            if isValid(id) then specID = id end
        end
    end
    if specID then
        local statName = SPEC_PRIMARY_STAT[specID]
        if statName then
            return Stats.STAT_TYPES[statName]
        end
    end
    local _, classToken = UnitClass("player")
    local fallback = CLASS_FALLBACK_PRIMARY[classToken or ""]
    return Stats.STAT_TYPES[fallback or "STRENGTH"] or Stats.STAT_TYPES.STRENGTH
end

-- Stat display names (will be populated from localization)
Stats.STAT_NAMES = {}

-- Stat colors for UI purposes
Stats.STAT_COLORS = {
    -- Primary stats
    [Stats.STAT_TYPES.STRENGTH] = { 0.77, 0.31, 0.23 },
    [Stats.STAT_TYPES.AGILITY] = { 0.56, 0.66, 0.46 },
    [Stats.STAT_TYPES.INTELLECT] = { 0.52, 0.62, 0.74 },
    [Stats.STAT_TYPES.STAMINA] = { 0.87, 0.57, 0.34 },
    -- Fallback for PRIMARY_STAT; Stats:GetColor delegates to the resolved
    -- primary stat at runtime, so this is only used if resolution fails.
    [Stats.STAT_TYPES.PRIMARY_STAT] = { 0.77, 0.31, 0.23 },

    -- Secondary stats
    [Stats.STAT_TYPES.HASTE] = { 0.42, 0.59, 0.59 },
    [Stats.STAT_TYPES.CRIT] = { 0.85, 0.76, 0.47 },
    [Stats.STAT_TYPES.MASTERY] = { 0.76, 0.52, 0.38 },
    [Stats.STAT_TYPES.VERSATILITY] = { 0.63, 0.69, 0.58 },
    [Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE] = { 0.63, 0.69, 0.58 },
    [Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION] = { 0.53, 0.75, 0.58 },
    [Stats.STAT_TYPES.SPEED] = { 0.67, 0.55, 0.67 },
    [Stats.STAT_TYPES.LEECH] = { 0.69, 0.47, 0.43 },
    [Stats.STAT_TYPES.AVOIDANCE] = { 0.59, 0.67, 0.76 },

    -- Combat ratings
    [Stats.STAT_TYPES.DEFENSE] = { 0.50, 0.50, 0.80 },
    [Stats.STAT_TYPES.DODGE] = { 0.40, 0.70, 0.40 },
    [Stats.STAT_TYPES.PARRY] = { 0.70, 0.40, 0.40 },
    [Stats.STAT_TYPES.BLOCK] = { 0.60, 0.60, 0.30 },
    [Stats.STAT_TYPES.ARMOR_PENETRATION] = { 0.75, 0.60, 0.30 }
}

-- Store base values for primary stats
Stats.BASE_VALUES = {
    [Stats.STAT_TYPES.STRENGTH] = 0,
    [Stats.STAT_TYPES.AGILITY] = 0,
    [Stats.STAT_TYPES.INTELLECT] = 0,
    [Stats.STAT_TYPES.STAMINA] = 0
}

-- Default stat order
Stats.STAT_ORDER = {
    Stats.STAT_TYPES.PRIMARY_STAT,
    Stats.STAT_TYPES.STRENGTH,
    Stats.STAT_TYPES.AGILITY,
    Stats.STAT_TYPES.INTELLECT,
    Stats.STAT_TYPES.STAMINA,
    Stats.STAT_TYPES.CRIT,
    Stats.STAT_TYPES.HASTE,
    Stats.STAT_TYPES.MASTERY,
    Stats.STAT_TYPES.VERSATILITY,
    Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION, -- Shows damage reduction % (half of damage %)
    Stats.STAT_TYPES.SPEED,
    Stats.STAT_TYPES.LEECH,
    Stats.STAT_TYPES.AVOIDANCE,
    Stats.STAT_TYPES.DODGE,
    Stats.STAT_TYPES.PARRY,
    Stats.STAT_TYPES.BLOCK
}

-- Combat Rating to Stat Type mapping for easier lookups
Stats.RATING_MAP = {
    [Stats.COMBAT_RATINGS.CR_DODGE] = Stats.STAT_TYPES.DODGE,
    [Stats.COMBAT_RATINGS.CR_PARRY] = Stats.STAT_TYPES.PARRY,
    [Stats.COMBAT_RATINGS.CR_BLOCK] = Stats.STAT_TYPES.BLOCK,
    [Stats.COMBAT_RATINGS.CR_CRIT_MELEE] = Stats.STAT_TYPES.CRIT,
    [Stats.COMBAT_RATINGS.CR_HASTE_MELEE] = Stats.STAT_TYPES.HASTE,
    [Stats.COMBAT_RATINGS.CR_MASTERY] = Stats.STAT_TYPES.MASTERY,
    [Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE] = Stats.STAT_TYPES.VERSATILITY,
    [Stats.COMBAT_RATINGS.CR_SPEED] = Stats.STAT_TYPES.SPEED,
    [Stats.COMBAT_RATINGS.CR_LIFESTEAL] = Stats.STAT_TYPES.LEECH,
    [Stats.COMBAT_RATINGS.CR_AVOIDANCE] = Stats.STAT_TYPES.AVOIDANCE
}


-- Initialize base values for primary stats
function Stats:InitializeBaseValues()
    -- Use StatAPI wrappers for 12.0 compatibility
    local baseStr = StatAPI.GetUnitStat(1)
    local baseAgi = StatAPI.GetUnitStat(2)
    local baseInt = StatAPI.GetUnitStat(4)
    local baseSta = StatAPI.GetUnitStat(3)

    Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH] = baseStr
    Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY] = baseAgi
    Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT] = baseInt
    Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA] = baseSta
end

-- Returns the buff value (positive and negative combined) for the specified stat
function Stats:GetBuffValue(statType)
    local buffValue = 0

    if statType == Stats.STAT_TYPES.PRIMARY_STAT then
        return self:GetBuffValue(self:ResolvePrimaryStatType())
    end

    -- Use StatAPI wrappers for 12.0 compatibility
    if statType == Stats.STAT_TYPES.STRENGTH then
        local _, _, posBuff, negBuff = StatAPI.GetUnitStat(1)
        buffValue = posBuff + negBuff
    elseif statType == Stats.STAT_TYPES.AGILITY then
        local _, _, posBuff, negBuff = StatAPI.GetUnitStat(2)
        buffValue = posBuff + negBuff
    elseif statType == Stats.STAT_TYPES.STAMINA then
        local _, _, posBuff, negBuff = StatAPI.GetUnitStat(3)
        buffValue = posBuff + negBuff
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        local _, _, posBuff, negBuff = StatAPI.GetUnitStat(4)
        buffValue = posBuff + negBuff
    end

    return buffValue
end

-- Returns the buff percentage for the specified stat
function Stats:GetBuffPercentage(statType)
    local buffPercentage = 0

    if statType == Stats.STAT_TYPES.PRIMARY_STAT then
        return self:GetBuffPercentage(self:ResolvePrimaryStatType())
    end

    -- Use StatAPI wrappers for 12.0 compatibility
    if statType == Stats.STAT_TYPES.STRENGTH then
        local base, _, posBuff, negBuff = StatAPI.GetUnitStat(1)
        if base > 0 then
            buffPercentage = ((posBuff + negBuff) / base) * 100
        end
    elseif statType == Stats.STAT_TYPES.AGILITY then
        local base, _, posBuff, negBuff = StatAPI.GetUnitStat(2)
        if base > 0 then
            buffPercentage = ((posBuff + negBuff) / base) * 100
        end
    elseif statType == Stats.STAT_TYPES.STAMINA then
        local base, _, posBuff, negBuff = StatAPI.GetUnitStat(3)
        if base > 0 then
            buffPercentage = ((posBuff + negBuff) / base) * 100
        end
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        local base, _, posBuff, negBuff = StatAPI.GetUnitStat(4)
        if base > 0 then
            buffPercentage = ((posBuff + negBuff) / base) * 100
        end
    end

    return buffPercentage
end

-- Returns the current value of the specified stat using the latest APIs
-- Updated for WoW 12.0 compatibility with StatAPI wrappers
function Stats:GetValue(statType)
    local value = 0

    if statType == Stats.STAT_TYPES.PRIMARY_STAT then
        return self:GetValue(self:ResolvePrimaryStatType())
    end

    -- Helper: get primary stat total via fallback chain, secret-safe
    -- C_Attributes/C_Stats return a single total; UnitStat's 2nd return is effectiveStat
    local function GetPrimaryStat(attrName, statIndex)
        local val = nil
        -- Try C_Attributes (returns total as single value)
        if C_Attributes then
            val = SafeGetValue(C_Attributes.GetAttribute, "player", attrName)
        end
        -- If unavailable, try C_Stats
        if not IsSecretValue(val) and val == nil then
            if C_Stats then
                val = SafeGetValue(C_Stats.GetStatByID, statIndex)
            end
        end
        -- If still unavailable, try UnitStat. Use the 2nd return (effectiveStat) —
        -- it's the value shown on the character pane. Do NOT add posBuff/negBuff:
        -- in modern WoW the 1st return already equals effectiveStat, so summing
        -- double-counts gear/buff bonuses.
        if not IsSecretValue(val) and val == nil then
            local _, effective = StatAPI.GetUnitStat(statIndex)
            val = effective
        end
        if IsSecretValue(val) then return val end
        return val or 0
    end

    -- Primary stats - use fallback chain with secret value support
    if statType == Stats.STAT_TYPES.STRENGTH then
        value = GetPrimaryStat("Strength", 1)
    elseif statType == Stats.STAT_TYPES.AGILITY then
        value = GetPrimaryStat("Agility", 2)
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        value = GetPrimaryStat("Intellect", 4)
    elseif statType == Stats.STAT_TYPES.STAMINA then
        value = GetPrimaryStat("Stamina", 3)

    -- Secondary stats - Using StatAPI wrappers for 12.0 compatibility
    elseif statType == Stats.STAT_TYPES.HASTE then
        value = StatAPI.GetHaste()
    elseif statType == Stats.STAT_TYPES.CRIT then
        value = StatAPI.GetCritChance()
    elseif statType == Stats.STAT_TYPES.MASTERY then
        value = StatAPI.GetMastery()
    elseif statType == Stats.STAT_TYPES.VERSATILITY or statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE then
        -- Get base value using StatAPI wrapper
        value = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)

        -- 12.0.5+: Skip talent adjustment for secret values (can't do arithmetic)
        -- Secret values from the API already include all combat bonuses
        if not IsSecretValue(value) then
            local adjustment = self:GetTalentAdjustment(statType)
            if PDS.Config.DEBUG_ENABLED then
                PDS.Utils.Debug("Versatility calculation - Base: " .. value .. ", Adjustment: " .. adjustment)
            end
            if value > 0 or adjustment > 0 then
                value = value + adjustment
                if PDS.Config.DEBUG_ENABLED and adjustment > 0 then
                    PDS.Utils.Debug("Applied talent adjustment. New value: " .. value)
                end
            end
        end
    elseif statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION then
        -- Damage reduction is always half of damage done bonus
        value = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)

        if not IsSecretValue(value) then
            value = value / 2
            local adjustment = self:GetTalentAdjustment(statType)
            if PDS.Config.DEBUG_ENABLED then
                PDS.Utils.Debug("Versatility Damage Reduction calculation - Base: " .. value .. ", Adjustment: " .. adjustment)
            end
            if value > 0 or adjustment > 0 then
                value = value + adjustment
                if PDS.Config.DEBUG_ENABLED and adjustment > 0 then
                    PDS.Utils.Debug("Applied talent adjustment. New value: " .. value)
                end
            end
        end
        -- When value is secret, pass through as-is (can't do arithmetic on secrets)
    elseif statType == Stats.STAT_TYPES.SPEED then
        value = StatAPI.GetSpeed()
    elseif statType == Stats.STAT_TYPES.LEECH then
        value = StatAPI.GetLifesteal()
    elseif statType == Stats.STAT_TYPES.AVOIDANCE then
        value = StatAPI.GetAvoidance()
    elseif statType == Stats.STAT_TYPES.DODGE then
        value = StatAPI.GetDodgeChance()
    elseif statType == Stats.STAT_TYPES.PARRY then
        value = StatAPI.GetParryChance()
    elseif statType == Stats.STAT_TYPES.BLOCK then
        value = StatAPI.GetBlockChance()
    end

    return value
end

-- Gets the raw rating value for the specified stat type
-- Updated for WoW 12.0 compatibility with StatAPI wrappers
function Stats:GetRating(statType)
    local rating = 0

    if statType == Stats.STAT_TYPES.PRIMARY_STAT then
        return self:GetRating(self:ResolvePrimaryStatType())
    end

    -- Primary stats - return the total stat value (reuses GetPrimaryStat pattern)
    -- Helper: get primary stat for rating display, secret-safe
    local function GetPrimaryStatRating(statIndex)
        local val = nil
        if C_Stats then
            val = SafeGetValue(C_Stats.GetStatByID, statIndex)
        end
        if not IsSecretValue(val) and val == nil then
            local _, effective = StatAPI.GetUnitStat(statIndex)
            val = effective
        end
        if IsSecretValue(val) then return val end
        return val or 0
    end

    if statType == Stats.STAT_TYPES.STRENGTH then
        rating = GetPrimaryStatRating(1)
    elseif statType == Stats.STAT_TYPES.AGILITY then
        rating = GetPrimaryStatRating(2)
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        rating = GetPrimaryStatRating(4)
    elseif statType == Stats.STAT_TYPES.STAMINA then
        rating = GetPrimaryStatRating(3)

    -- Secondary stats - return the combat rating using StatAPI wrappers
    elseif statType == Stats.STAT_TYPES.HASTE then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_HASTE_MELEE)
    elseif statType == Stats.STAT_TYPES.CRIT then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_CRIT_MELEE)
    elseif statType == Stats.STAT_TYPES.MASTERY then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_MASTERY)
    elseif statType == Stats.STAT_TYPES.VERSATILITY or statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
    elseif statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_TAKEN)
    elseif statType == Stats.STAT_TYPES.SPEED then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_SPEED)
    elseif statType == Stats.STAT_TYPES.LEECH then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_LIFESTEAL)
    elseif statType == Stats.STAT_TYPES.AVOIDANCE then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_AVOIDANCE)
    elseif statType == Stats.STAT_TYPES.DODGE then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_DODGE)
    elseif statType == Stats.STAT_TYPES.PARRY then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_PARRY)
    elseif statType == Stats.STAT_TYPES.BLOCK then
        rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_BLOCK)
    end

    return rating
end

-- Handles talent-specific adjustments for stats
-- This addresses the issue where Rogue's "Thief's Versatility" talent
-- provides bonus versatility that isn't reflected in the combat rating API
-- Updated for WoW 12.0: Uses combat caching since aura APIs may be restricted in combat
function Stats:GetTalentAdjustment(statType)
    local adjustment = 0

    -- Check if talent adjustments are enabled
    if not PDS.Config.enableTalentAdjustments then
        return adjustment
    end

    -- WoW 12.0 Combat Caching:
    -- If we're in combat and have a cached value, use it (aura APIs may be restricted)
    if InCombatLockdown() and combatCache.talentAdjustments[statType] ~= nil then
        if PDS.Config.DEBUG_ENABLED then
            PDS.Utils.Debug("Using cached talent adjustment for " .. statType .. ": " .. combatCache.talentAdjustments[statType])
        end
        return combatCache.talentAdjustments[statType]
    end

    -- Check for Rogue's Thief's Versatility talent
    -- This talent provides a flat percentage bonus that the game doesn't report
    -- through the standard GetCombatRatingBonus API
    if statType == Stats.STAT_TYPES.VERSATILITY or
       statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE or
       statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION then
        local playerClass = select(2, UnitClass("player"))
        if playerClass == "ROGUE" then
            -- For The War Within, use the new talent API if available
            local hasTalent = false

            -- Try new talent API first (TWW+)
            if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
                local configID = C_ClassTalents.GetActiveConfigID()
                if configID then
                    -- Check for Thief's Versatility using talent search
                    -- Note: These APIs may vary, so we'll use a try-catch approach
                    hasTalent = self:HasSpecificTalent("Thief's Versatility")
                end
            else
                -- Fallback to older API
                local specID = GetSpecialization()
                if specID then
                    local specInfo = GetSpecializationInfo(specID)
                    -- Outlaw spec ID is 260
                    if specInfo == 260 then
                        -- Try to check for the talent
                        hasTalent = self:CheckForThiefsVersatilityLegacy()
                    end
                end
            end

            if hasTalent then
                -- Apply the talent bonus
                -- Thief's Versatility in TWW gives 4% Versatility to all abilities
                adjustment = 4

                -- If it's damage reduction, the bonus might be halved (typical WoW behavior)
                if statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION then
                    adjustment = adjustment / 2
                end

                -- Debug output if enabled
                if PDS.Config.DEBUG_ENABLED then
                    PDS.Utils.Debug("Thief's Versatility detected, applying +" .. adjustment .. "% to " .. statType)
                end
            elseif PDS.Config.DEBUG_ENABLED then
                PDS.Utils.Debug("Rogue detected but Thief's Versatility not found")
            end
        end
    end

    -- Cache the result for use during combat (12.0 compatibility)
    combatCache.talentAdjustments[statType] = adjustment

    return adjustment
end

-- Helper function to check for specific talent by name
-- Updated for WoW 12.0: Aura scanning may be restricted during combat
function Stats:HasSpecificTalent(talentName)
    -- Try multiple approaches to find the talent

    -- Method 1: Using spell aura to find the buff (may be restricted in 12.0 combat)
    -- Only try aura scanning when NOT in combat lockdown
    if not InCombatLockdown() then
        local i = 1
        while true do
            local auraData
            -- Wrap in pcall for 12.0 safety - aura APIs may fail
            local success, result = pcall(function()
                if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                    return C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
                end
                return nil
            end)

            if not success or not result then break end
            auraData = result

            local name = auraData.name
            local spellId = auraData.spellId

            -- Check if the aura name contains our talent name
            if name and (string.find(name, talentName) or name == "Thief's Versatility") then
                if PDS.Config.DEBUG_ENABLED then
                    PDS.Utils.Debug("Found Thief's Versatility aura: " .. name .. " (ID: " .. (spellId or "unknown") .. ")")
                end
                return true
            end
            i = i + 1
        end
    elseif PDS.Config.DEBUG_ENABLED then
        PDS.Utils.Debug("Skipping aura scan in combat (12.0 compatibility)")
    end

    -- Method 2: Check using IsPlayerSpell for known Thief's Versatility spell IDs
    -- This should always work even in combat (player's own spell knowledge)
    local thiefsVersatilitySpellIDs = {
        381990,  -- TWW potential ID
        382090,  -- DF potential ID
        381629,  -- Another potential ID
        196924,  -- Legion potential ID
        79096,   -- Another potential ID
    }

    for _, spellID in ipairs(thiefsVersatilitySpellIDs) do
        local hasSpell = SafeGetValue(IsPlayerSpell, spellID)
        if hasSpell then
            if PDS.Config.DEBUG_ENABLED then
                PDS.Utils.Debug("Found Thief's Versatility spell ID: " .. spellID)
            end
            return true
        end
    end

    -- Method 3: For Outlaw Rogues, assume they have the talent if they're over level 50
    local playerClass = select(2, UnitClass("player"))
    if playerClass == "ROGUE" then
        local specID = SafeGetValue(GetSpecialization)
        if specID then
            local specInfo = SafeGetValue(GetSpecializationInfo, specID)
            -- Outlaw spec ID is 260
            if specInfo == 260 then
                local level = SafeGetValue(UnitLevel, "player") or 0
                if level >= 50 then
                    -- Check for a specific Outlaw-only spell as an indirect way to verify spec
                    local hasBladeFlurry = SafeGetValue(IsSpellKnown, 13877) or
                                          SafeGetValue(IsSpellKnown, 315508) or
                                          SafeGetValue(IsSpellKnown, 385616)
                    if hasBladeFlurry then
                        if PDS.Config.DEBUG_ENABLED then
                            PDS.Utils.Debug("Detected high-level Outlaw Rogue, assuming Thief's Versatility")
                        end
                        return true
                    end
                end
            end
        end
    end

    -- Method 4: Legacy talent check (only when not in combat)
    if not InCombatLockdown() then
        return self:CheckForThiefsVersatilityLegacy()
    end

    return false
end

-- Legacy method for checking Thief's Versatility
-- Updated for WoW 12.0: Uses safe API wrappers and pcall for aura scanning
function Stats:CheckForThiefsVersatilityLegacy()
    -- Safe guard - if player is not a rogue, don't bother checking
    local playerClass = select(2, UnitClass("player"))
    if playerClass ~= "ROGUE" then
        return false
    end

    -- Attempt 1: Check talent tree using legacy API
    local foundTalent = false

    -- Try with GetTalentInfo (Legion/BFA style)
    for tier = 1, 7 do
        for column = 1, 3 do
            -- Try various talent interface functions as the API has changed over time
            local name, selected

            -- Try GetTalentInfo method 1
            pcall(function()
                local talentID, talentName, texture, isSelected = GetTalentInfo(tier, column, 1)
                name = talentName
                selected = isSelected
            end)

            -- Try GetTalentInfo method 2 (different parameter order)
            if not name then
                pcall(function()
                    local talentID, talentName, texture, isSelected = GetTalentInfo(1, tier, column)
                    name = talentName
                    selected = isSelected
                end)
            end

            if selected and name and (string.find(name:lower(), "thief's versatility") or
                                      string.find(name:lower(), "thiefs versatility") or
                                      string.find(name:lower(), "versatility")) then
                foundTalent = true
                break
            end
        end

        if foundTalent then break end
    end

    if foundTalent then
        if PDS.Config.DEBUG_ENABLED then
            PDS.Utils.Debug("Found Thief's Versatility via legacy talent API")
        end
        return true
    end

    -- Attempt 2: Check for increased versatility as evidence
    -- Compare base versatility with current - if there's a significant difference for a rogue,
    -- it might be due to Thief's Versatility
    local baseVers = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)

    -- Check if player has notably higher versatility than expected from gear alone
    -- Check through buffs for any other versatility increases (using safe aura scanning)
    local hasVersBuffs = false
    local i = 1
    while true do
        local auraData
        -- Wrap in pcall for 12.0 safety
        local success, result = pcall(function()
            if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                return C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            end
            return nil
        end)

        if not success or not result then break end
        auraData = result

        local name = auraData.name

        -- Exclude basic class/role buffs that give versatility
        if name ~= "Battle Shout" and name ~= "Power Word: Fortitude" and
           name ~= "Commanding Shout" and name ~= "Mark of the Wild" then
            -- Look for versatility in the aura description
            if auraData.description and string.find(auraData.description:lower(), "versatility") then
                hasVersBuffs = true
                break
            end
        end

        if hasVersBuffs then break end
        i = i + 1
    end

    -- If we're a high level outlaw rogue without other versatility buffs
    -- and significant versatility, assume it's from Thief's Versatility
    local specID = SafeGetValue(GetSpecialization)
    if specID then
        local specInfo = SafeGetValue(GetSpecializationInfo, specID)
        -- Outlaw spec ID is 260
        if specInfo == 260 and not hasVersBuffs and baseVers > 3 then
            if PDS.Config.DEBUG_ENABLED then
                PDS.Utils.Debug("Assumed Thief's Versatility based on higher vers rating")
            end
            return true
        end
    end
    
    -- Attempt 3: Check pvp talents
    local pvpTalents = C_SpecializationInfo and C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
    if pvpTalents then
        for _, talentID in ipairs(pvpTalents) do
            local talentInfo = C_PvP and C_PvP.GetPvpTalentInfoByID(talentID)
            if talentInfo and talentInfo.name and string.find(talentInfo.name:lower(), "versatility") then
                if PDS.Config.DEBUG_ENABLED then
                    PDS.Utils.Debug("Found Thief's Versatility in PvP talents")
                end
                return true
            end
        end
    end
    
    return false
end

-- Returns the color for a specific stat type
function Stats:GetColor(statType)
    if statType == Stats.STAT_TYPES.PRIMARY_STAT then
        return self:GetColor(self:ResolvePrimaryStatType())
    end
    if Stats.STAT_COLORS[statType] then
        return unpack(Stats.STAT_COLORS[statType])
    else
        return 0.8, 0.8, 0.8 -- Default to white/grey
    end
end

-- Initialize stat names from localization
function Stats:InitializeStatNames()
    if not PDS.L then return end
    
    Stats.STAT_NAMES = {
        -- Primary stats
        [Stats.STAT_TYPES.STRENGTH] = PDS.L["STAT_STRENGTH"],
        [Stats.STAT_TYPES.AGILITY] = PDS.L["STAT_AGILITY"],
        [Stats.STAT_TYPES.INTELLECT] = PDS.L["STAT_INTELLECT"],
        [Stats.STAT_TYPES.STAMINA] = PDS.L["STAT_STAMINA"],
        [Stats.STAT_TYPES.PRIMARY_STAT] = PDS.L["STAT_PRIMARY_STAT"],

        -- Secondary stats
        [Stats.STAT_TYPES.HASTE] = PDS.L["STAT_HASTE"],
        [Stats.STAT_TYPES.CRIT] = PDS.L["STAT_CRIT"],
        [Stats.STAT_TYPES.MASTERY] = PDS.L["STAT_MASTERY"],
        [Stats.STAT_TYPES.VERSATILITY] = PDS.L["STAT_VERSATILITY"],
        [Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE] = PDS.L["STAT_VERSATILITY_DAMAGE"],
        [Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION] = PDS.L["STAT_VERSATILITY_DAMAGE_REDUCTION"],
        [Stats.STAT_TYPES.SPEED] = PDS.L["STAT_SPEED"],
        [Stats.STAT_TYPES.LEECH] = PDS.L["STAT_LEECH"],
        [Stats.STAT_TYPES.AVOIDANCE] = PDS.L["STAT_AVOIDANCE"],

        -- Combat ratings
        [Stats.STAT_TYPES.DEFENSE] = PDS.L["STAT_DEFENSE"],
        [Stats.STAT_TYPES.DODGE] = PDS.L["STAT_DODGE"],
        [Stats.STAT_TYPES.PARRY] = PDS.L["STAT_PARRY"],
        [Stats.STAT_TYPES.BLOCK] = PDS.L["STAT_BLOCK"],
        [Stats.STAT_TYPES.ARMOR_PENETRATION] = PDS.L["STAT_ARMOR_PENETRATION"]
    }
end

-- Returns the display name for a specific stat type
function Stats:GetName(statType)
    return Stats.STAT_NAMES[statType] or statType
end


-- Gets the rating needed for 1% of a stat using StatAPI wrappers
-- 12.0.5+: Returns 0 when values are secret (can't do arithmetic on secrets)
function Stats:GetRatingPer1Percent(statType)
    local ratingPer1Percent = 0

    local function CalcRatingPer1Pct(ratingIndex)
        local bonus = StatAPI.GetCombatRatingBonus(ratingIndex)
        local rating = StatAPI.GetCombatRating(ratingIndex)
        -- Can't divide secret values
        if IsSecretValue(bonus) or IsSecretValue(rating) then return 0 end
        if rating > 0 then return bonus / rating end
        return 0
    end

    if statType == Stats.STAT_TYPES.HASTE then
        ratingPer1Percent = CalcRatingPer1Pct(Stats.COMBAT_RATINGS.CR_HASTE_MELEE)
    elseif statType == Stats.STAT_TYPES.CRIT then
        ratingPer1Percent = CalcRatingPer1Pct(Stats.COMBAT_RATINGS.CR_CRIT_MELEE)
    elseif statType == Stats.STAT_TYPES.MASTERY then
        ratingPer1Percent = CalcRatingPer1Pct(Stats.COMBAT_RATINGS.CR_MASTERY)
    elseif statType == Stats.STAT_TYPES.VERSATILITY or statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE then
        ratingPer1Percent = CalcRatingPer1Pct(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
    end

    if ratingPer1Percent > 0 then
        ratingPer1Percent = 1 / ratingPer1Percent
    else
        ratingPer1Percent = 0
    end

    return ratingPer1Percent
end

-- Calculates the rating needed for the next percentage point of a stat
function Stats:GetRatingForNextPercent(statType, currentRating, currentPercent)
    local ratingPer1Percent = self:GetRatingPer1Percent(statType)

    if ratingPer1Percent <= 0 then return 0 end

    local nextPercent = math.floor(currentPercent) + 1
    local ratingNeeded = nextPercent * ratingPer1Percent - currentRating

    return math.max(0, math.ceil(ratingNeeded))
end

-- Calculates the bar values for display
-- 12.0.5+: Secret values pass through directly (no overflow support)
function Stats:CalculateBarValues(value)
    if IsSecretValue(value) then
        return value, 0
    end

    local percentValue = math.min(value, 100)
    local overflowValue = 0

    if value > 100 then
        overflowValue = math.min(value - 100, 100)
    end

    return percentValue, overflowValue
end

-- Gets the formatted display value for a stat
-- Updated for WoW 12.0.5 compatibility with secret value pass-through
function Stats:GetDisplayValue(statType, value, showRating)
    -- 12.0.5+: Secret values work with string.format for display
    if IsSecretValue(value) then
        local fmt = self:IsPrimaryStat(statType) and "%.0f" or "%.2f%%"
        if showRating == nil then
            showRating = PDS.Config.showRatings
        end
        if showRating then
            local rating = self:GetRating(statType)
            if IsSecretValue(rating) then
                return string.format(fmt .. " | %.0f", value, rating)
            elseif rating > 0 then
                return string.format(fmt .. " | %d", value, math.floor(rating + 0.5))
            end
        end
        return string.format(fmt, value)
    end

    -- Primary stats display as raw numbers, not percentages
    local displayValue
    if self:IsPrimaryStat(statType) then
        displayValue = tostring(math.floor(value + 0.5))
    else
        displayValue = PDS.Utils.FormatPercent(value)
    end

    -- If showRating is not specified, use the config setting
    if showRating == nil then
        showRating = PDS.Config.showRatings
    end

    -- If showRatings is enabled, get the rating and add it to the display value
    if showRating then
        local rating = self:GetRating(statType)

        -- 12.0.5+: Secret ratings use string.format pass-through
        if IsSecretValue(rating) then
            displayValue = string.format("%s | %.0f", displayValue, rating)
        elseif rating and rating > 0 then
            displayValue = displayValue .. " | " .. math.floor(rating + 0.5)
        end
    end

    return displayValue
end

-- Gets the formatted change display value and color for a stat change
function Stats:GetChangeDisplayValue(change)
    local changeDisplay = PDS.Utils.FormatChange(change)
    local r, g, b = 1, 1, 1

    if change > 0 then
        r, g, b = 0, 1, 0
    elseif change < 0 then
        r, g, b = 1, 0, 0
    end

    return changeDisplay, r, g, b
end

return Stats
