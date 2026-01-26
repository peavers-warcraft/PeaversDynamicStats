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
local function SafeGetValue(apiFunc, ...)
    if not apiFunc then return nil end

    local success, result = pcall(apiFunc, ...)
    if not success then
        -- API call failed (may happen if API is removed/changed)
        return nil
    end

    -- Check if result is a secret value (would return true for restricted combat data)
    if IsSecretValue(result) then
        return nil
    end

    return result
end

-- Safely call an API function that returns multiple values
local function SafeGetMultiValue(apiFunc, ...)
    if not apiFunc then return nil end

    local results = {pcall(apiFunc, ...)}
    local success = table.remove(results, 1)

    if not success then
        return nil
    end

    -- Check first result for secret value
    if #results > 0 and IsSecretValue(results[1]) then
        return nil
    end

    return unpack(results)
end

--------------------------------------------------------------------------------
-- StatAPI Wrapper Layer
-- Provides safe, fallback-enabled access to all stat APIs
--------------------------------------------------------------------------------

local StatAPI = {}

-- Primary stat wrappers (using UnitStat)
function StatAPI.GetUnitStat(statIndex)
    local base, stat, posBuff, negBuff = SafeGetMultiValue(UnitStat, "player", statIndex)
    if base == nil then
        return 0, 0, 0, 0
    end
    return base, stat or base, posBuff or 0, negBuff or 0
end

-- Secondary stat wrappers
function StatAPI.GetHaste()
    return SafeGetValue(GetHaste) or 0
end

function StatAPI.GetCritChance()
    -- Try spell crit first (most accurate for casters), then generic crit
    return SafeGetValue(GetSpellCritChance, 2) or SafeGetValue(GetCritChance) or 0
end

function StatAPI.GetMastery()
    return SafeGetValue(GetMasteryEffect) or SafeGetValue(GetMastery) or 0
end

function StatAPI.GetSpeed()
    return SafeGetValue(GetSpeed) or 0
end

function StatAPI.GetLifesteal()
    return SafeGetValue(GetLifesteal) or 0
end

function StatAPI.GetAvoidance()
    return SafeGetValue(GetAvoidance) or 0
end

function StatAPI.GetDodgeChance()
    return SafeGetValue(GetDodgeChance) or 0
end

function StatAPI.GetParryChance()
    return SafeGetValue(GetParryChance) or 0
end

function StatAPI.GetBlockChance()
    return SafeGetValue(GetBlockChance) or 0
end

-- Combat rating wrappers
function StatAPI.GetCombatRating(ratingIndex)
    return SafeGetValue(GetCombatRating, ratingIndex) or 0
end

function StatAPI.GetCombatRatingBonus(ratingIndex)
    return SafeGetValue(GetCombatRatingBonus, ratingIndex) or 0
end

-- Expose StatAPI for other modules and testing
Stats.StatAPI = StatAPI

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

-- Stat display names (will be populated from localization)
Stats.STAT_NAMES = {}

-- Stat colors for UI purposes
Stats.STAT_COLORS = {
    -- Primary stats
    [Stats.STAT_TYPES.STRENGTH] = { 0.77, 0.31, 0.23 },
    [Stats.STAT_TYPES.AGILITY] = { 0.56, 0.66, 0.46 },
    [Stats.STAT_TYPES.INTELLECT] = { 0.52, 0.62, 0.74 },
    [Stats.STAT_TYPES.STAMINA] = { 0.87, 0.57, 0.34 },

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

    -- Primary stats - use StatAPI wrapper with fallback chain
    if statType == Stats.STAT_TYPES.STRENGTH then
        -- Try to use C_Attributes if available, otherwise fall back to C_Stats, then StatAPI
        if C_Attributes then
            value = SafeGetValue(C_Attributes.GetAttribute, "player", "Strength") or 0
        elseif C_Stats then
            value = SafeGetValue(C_Stats.GetStatByID, 1) or 0
        end
        -- Fallback to StatAPI wrapper (uses UnitStat with safety)
        if value == 0 then
            local base, _, posBuff, negBuff = StatAPI.GetUnitStat(1)
            value = base + posBuff + negBuff
        end
    elseif statType == Stats.STAT_TYPES.AGILITY then
        if C_Attributes then
            value = SafeGetValue(C_Attributes.GetAttribute, "player", "Agility") or 0
        elseif C_Stats then
            value = SafeGetValue(C_Stats.GetStatByID, 2) or 0
        end
        if value == 0 then
            local base, _, posBuff, negBuff = StatAPI.GetUnitStat(2)
            value = base + posBuff + negBuff
        end
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        if C_Attributes then
            value = SafeGetValue(C_Attributes.GetAttribute, "player", "Intellect") or 0
        elseif C_Stats then
            value = SafeGetValue(C_Stats.GetStatByID, 4) or 0
        end
        if value == 0 then
            local base, _, posBuff, negBuff = StatAPI.GetUnitStat(4)
            value = base + posBuff + negBuff
        end
    elseif statType == Stats.STAT_TYPES.STAMINA then
        if C_Attributes then
            value = SafeGetValue(C_Attributes.GetAttribute, "player", "Stamina") or 0
        elseif C_Stats then
            value = SafeGetValue(C_Stats.GetStatByID, 3) or 0
        end
        if value == 0 then
            local base, _, posBuff, negBuff = StatAPI.GetUnitStat(3)
            value = base + posBuff + negBuff
        end

    -- Secondary stats - Using StatAPI wrappers for 12.0 compatibility
    elseif statType == Stats.STAT_TYPES.HASTE then
        value = StatAPI.GetHaste()
    elseif statType == Stats.STAT_TYPES.CRIT then
        value = StatAPI.GetCritChance()
    elseif statType == Stats.STAT_TYPES.MASTERY then
        value = StatAPI.GetMastery()
    elseif statType == Stats.STAT_TYPES.VERSATILITY then
        -- Get base value using StatAPI wrapper
        value = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)

        -- Only apply talent adjustments if value is valid (non-zero)
        local adjustment = self:GetTalentAdjustment(statType)

        -- Debug output
        if PDS.Config.DEBUG_ENABLED then
            PDS.Utils.Debug("Versatility calculation - Base: " .. value .. ", Adjustment: " .. adjustment)
        end

        if value > 0 or adjustment > 0 then
            value = value + adjustment

            -- Debug output
            if PDS.Config.DEBUG_ENABLED and adjustment > 0 then
                PDS.Utils.Debug("Applied talent adjustment. New value: " .. value)
            end
        end
    elseif statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE then
        -- Get base value using StatAPI wrapper
        value = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)

        -- Only apply talent adjustments if value is valid (non-zero)
        local adjustment = self:GetTalentAdjustment(statType)

        -- Debug output
        if PDS.Config.DEBUG_ENABLED then
            PDS.Utils.Debug("Versatility Damage calculation - Base: " .. value .. ", Adjustment: " .. adjustment)
        end

        if value > 0 or adjustment > 0 then
            value = value + adjustment

            -- Debug output
            if PDS.Config.DEBUG_ENABLED and adjustment > 0 then
                PDS.Utils.Debug("Applied talent adjustment. New value: " .. value)
            end
        end
    elseif statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION then
        -- Get base value using StatAPI wrapper
        value = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_TAKEN)

        -- Only apply talent adjustments if value is valid (non-zero)
        local adjustment = self:GetTalentAdjustment(statType)

        -- Debug output
        if PDS.Config.DEBUG_ENABLED then
            PDS.Utils.Debug("Versatility Damage Reduction calculation - Base: " .. value .. ", Adjustment: " .. adjustment)
        end

        if value > 0 or adjustment > 0 then
            value = value + adjustment

            -- Debug output
            if PDS.Config.DEBUG_ENABLED and adjustment > 0 then
                PDS.Utils.Debug("Applied talent adjustment. New value: " .. value)
            end
        end
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

    -- Primary stats - return the total stat value using StatAPI wrappers
    if statType == Stats.STAT_TYPES.STRENGTH then
        if C_Stats then
            rating = SafeGetValue(C_Stats.GetStatByID, 1) or 0
        end
        if rating == 0 then
            local base, _, posBuff, negBuff = StatAPI.GetUnitStat(1)
            rating = base + posBuff + negBuff
        end
    elseif statType == Stats.STAT_TYPES.AGILITY then
        if C_Stats then
            rating = SafeGetValue(C_Stats.GetStatByID, 2) or 0
        end
        if rating == 0 then
            local base, _, posBuff, negBuff = StatAPI.GetUnitStat(2)
            rating = base + posBuff + negBuff
        end
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        if C_Stats then
            rating = SafeGetValue(C_Stats.GetStatByID, 4) or 0
        end
        if rating == 0 then
            local base, _, posBuff, negBuff = StatAPI.GetUnitStat(4)
            rating = base + posBuff + negBuff
        end
    elseif statType == Stats.STAT_TYPES.STAMINA then
        if C_Stats then
            rating = SafeGetValue(C_Stats.GetStatByID, 3) or 0
        end
        if rating == 0 then
            local base, _, posBuff, negBuff = StatAPI.GetUnitStat(3)
            rating = base + posBuff + negBuff
        end

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
function Stats:GetRatingPer1Percent(statType)
    local ratingPer1Percent = 0

    if statType == Stats.STAT_TYPES.HASTE then
        local bonus = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_HASTE_MELEE)
        local rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_HASTE_MELEE)
        if rating > 0 then
            ratingPer1Percent = bonus / rating
        end
    elseif statType == Stats.STAT_TYPES.CRIT then
        local bonus = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_CRIT_MELEE)
        local rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_CRIT_MELEE)
        if rating > 0 then
            ratingPer1Percent = bonus / rating
        end
    elseif statType == Stats.STAT_TYPES.MASTERY then
        local bonus = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_MASTERY)
        local rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_MASTERY)
        if rating > 0 then
            ratingPer1Percent = bonus / rating
        end
    elseif statType == Stats.STAT_TYPES.VERSATILITY or statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE then
        local bonus = StatAPI.GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
        local rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
        if rating > 0 then
            ratingPer1Percent = bonus / rating
        end
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
function Stats:CalculateBarValues(value)
    local percentValue = math.min(value, 100)
    local overflowValue = 0

    if value > 100 then
        overflowValue = math.min(value - 100, 100)
    end

    return percentValue, overflowValue
end

-- Gets the formatted display value for a stat
-- Updated for WoW 12.0 compatibility with StatAPI wrappers
function Stats:GetDisplayValue(statType, value, showRating)
    local displayValue = PDS.Utils:FormatPercent(value)

    -- If showRating is not specified, use the config setting
    if showRating == nil then
        showRating = PDS.Config.showRatings
    end

    -- If showRatings is enabled, get the rating and add it to the display value
    if showRating then
        -- Get raw rating value using StatAPI wrappers or GetRating for primary stats
        local rating = nil

        -- Map stat types to combat ratings or get primary stat values
        if statType == Stats.STAT_TYPES.STRENGTH then
            rating = self:GetRating(statType)
        elseif statType == Stats.STAT_TYPES.AGILITY then
            rating = self:GetRating(statType)
        elseif statType == Stats.STAT_TYPES.INTELLECT then
            rating = self:GetRating(statType)
        elseif statType == Stats.STAT_TYPES.STAMINA then
            rating = self:GetRating(statType)
        elseif statType == Stats.STAT_TYPES.DODGE then
            rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_DODGE)
        elseif statType == Stats.STAT_TYPES.PARRY then
            rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_PARRY)
        elseif statType == Stats.STAT_TYPES.BLOCK then
            rating = StatAPI.GetCombatRating(Stats.COMBAT_RATINGS.CR_BLOCK)
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
        else
            -- Fallback to using GetRating method
            rating = self:GetRating(statType)
        end

        -- If we have a rating value, add it to the display value
        if rating and rating > 0 then
            displayValue = displayValue .. " | " .. math.floor(rating + 0.5)
        end
    end

    return displayValue
end

-- Gets the formatted change display value and color for a stat change
function Stats:GetChangeDisplayValue(change)
    local changeDisplay = PDS.Utils:FormatChange(change)
    local r, g, b = 1, 1, 1

    if change > 0 then
        r, g, b = 0, 1, 0
    elseif change < 0 then
        r, g, b = 1, 0, 0
    end

    return changeDisplay, r, g, b
end

return Stats
