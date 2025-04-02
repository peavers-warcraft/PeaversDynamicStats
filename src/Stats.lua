local _, PDS = ...
local Stats = PDS.Stats

-- Combat Rating constants
Stats.COMBAT_RATINGS = {
    CR_WEAPON_SKILL = 1,
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
    CR_HIT_TAKEN_MELEE = 12,
    CR_HIT_TAKEN_RANGED = 13,
    CR_HIT_TAKEN_SPELL = 14,
    CR_RESILIENCE_CRIT_TAKEN = 15,
    CR_RESILIENCE_PLAYER_DAMAGE_TAKEN = 16,
    CR_CRIT_TAKEN_SPELL = 17,
    CR_HASTE_MELEE = 18,
    CR_HASTE_RANGED = 19,
    CR_HASTE_SPELL = 20,
    CR_WEAPON_SKILL_MAINHAND = 21,
    CR_WEAPON_SKILL_OFFHAND = 22,
    CR_WEAPON_SKILL_RANGED = 23,
    CR_EXPERTISE = 24,
    CR_ARMOR_PENETRATION = 25,
    CR_MASTERY = 26,
    CR_VERSATILITY_DAMAGE_DONE = 29,
    CR_VERSATILITY_DAMAGE_TAKEN = 30,
    CR_SPEED = 31,
    CR_LIFESTEAL = 32
}

-- Stat types
Stats.STAT_TYPES = {
    HASTE = "HASTE",
    CRIT = "CRIT",
    MASTERY = "MASTERY",
    VERSATILITY = "VERSATILITY",
    SPEED = "SPEED",
    LEECH = "LEECH",
    AVOIDANCE = "AVOIDANCE"
}

-- Table of class/spec-specific stat bonuses
-- This table stores bonuses from talents or other class/spec-specific effects
-- that aren't automatically included in the WoW API stat functions.
--
-- Format: [className][specIndex][statType] = bonusValue
--
-- Example:
--   Stats.CLASS_SPEC_BONUSES["ROGUE"][2][Stats.STAT_TYPES.VERSATILITY] = 3
--   This adds a 3% versatility bonus for Outlaw Rogues (spec index 2)
--
-- Instead of directly modifying this table, use the provided API functions:
--   Stats:AddClassSpecBonus(className, specIndex, statType, bonusValue)
--   Stats:RemoveClassSpecBonus(className, specIndex, statType)
--   Stats:GetClassSpecBonus(className, specIndex, statType)
--   Stats:GetCurrentClassSpecBonuses()
Stats.CLASS_SPEC_BONUSES = {
    -- Rogue
    ["ROGUE"] = {
        -- Outlaw (spec index 2)
        [2] = {
            [Stats.STAT_TYPES.VERSATILITY] = 3 -- 3% versatility bonus from talent
        }
    }
    -- Add more classes and specs as needed using the AddClassSpecBonus function
}

-- Stat display names
Stats.STAT_NAMES = {
    [Stats.STAT_TYPES.HASTE] = "Haste",
    [Stats.STAT_TYPES.CRIT] = "Critical Strike",
    [Stats.STAT_TYPES.MASTERY] = "Mastery",
    [Stats.STAT_TYPES.VERSATILITY] = "Versatility",
    [Stats.STAT_TYPES.SPEED] = "Speed",
    [Stats.STAT_TYPES.LEECH] = "Leech",
    [Stats.STAT_TYPES.AVOIDANCE] = "Avoidance"
}

-- Stat colors (r, g, b)
Stats.STAT_COLORS = {
    [Stats.STAT_TYPES.HASTE] = { 0.0, 0.9, 0.9 }, -- Cyan
    [Stats.STAT_TYPES.CRIT] = { 0.9, 0.9, 0.0 }, -- Yellow
    [Stats.STAT_TYPES.MASTERY] = { 0.9, 0.4, 0.0 }, -- Orange
    [Stats.STAT_TYPES.VERSATILITY] = { 0.2, 0.6, 0.2 }, -- Green
    [Stats.STAT_TYPES.SPEED] = { 0.7, 0.3, 0.9 }, -- Purple
    [Stats.STAT_TYPES.LEECH] = { 0.9, 0.2, 0.2 }, -- Red
    [Stats.STAT_TYPES.AVOIDANCE] = { 0.2, 0.4, 0.9 } -- Blue
}

-- Default stat order
Stats.STAT_ORDER = {
    Stats.STAT_TYPES.CRIT,
    Stats.STAT_TYPES.HASTE,
    Stats.STAT_TYPES.MASTERY,
    Stats.STAT_TYPES.VERSATILITY,
    Stats.STAT_TYPES.SPEED,
    Stats.STAT_TYPES.LEECH,
    Stats.STAT_TYPES.AVOIDANCE
}

-- Returns the current value of the specified secondary stat
function Stats:GetValue(statType)
    local value = 0

    if statType == Stats.STAT_TYPES.HASTE then
        value = GetHaste()
    elseif statType == Stats.STAT_TYPES.CRIT then
        value = GetCritChance()
    elseif statType == Stats.STAT_TYPES.MASTERY then
        value = GetMasteryEffect()
    elseif statType == Stats.STAT_TYPES.VERSATILITY then
        value = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
    elseif statType == Stats.STAT_TYPES.SPEED then
        value = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_SPEED)
    elseif statType == Stats.STAT_TYPES.LEECH then
        value = GetLifesteal()
    elseif statType == Stats.STAT_TYPES.AVOIDANCE then
        value = GetAvoidance()
    end

    -- Apply class/spec-specific bonuses
    local _, playerClass = UnitClass("player")
    local specIndex = GetSpecialization()

    -- Check if there are any bonuses for this class/spec/stat combination
    if Stats.CLASS_SPEC_BONUSES[playerClass] and
       Stats.CLASS_SPEC_BONUSES[playerClass][specIndex] and
       Stats.CLASS_SPEC_BONUSES[playerClass][specIndex][statType] then
        -- Add the bonus to the value
        value = value + Stats.CLASS_SPEC_BONUSES[playerClass][specIndex][statType]
    end

    return value
end

-- Returns the raw combat rating value for the specified stat type
function Stats:GetRating(statType)
    local rating = 0

    if statType == Stats.STAT_TYPES.HASTE then
        -- Haste can be from melee, ranged, or spell, use the highest
        local hasteRatingMelee = GetCombatRating(Stats.COMBAT_RATINGS.CR_HASTE_MELEE)
        local hasteRatingRanged = GetCombatRating(Stats.COMBAT_RATINGS.CR_HASTE_RANGED)
        local hasteRatingSpell = GetCombatRating(Stats.COMBAT_RATINGS.CR_HASTE_SPELL)
        rating = math.max(hasteRatingMelee, hasteRatingRanged, hasteRatingSpell)
    elseif statType == Stats.STAT_TYPES.CRIT then
        -- Crit can be from melee, ranged, or spell, use the highest
        local critRatingMelee = GetCombatRating(Stats.COMBAT_RATINGS.CR_CRIT_MELEE)
        local critRatingRanged = GetCombatRating(Stats.COMBAT_RATINGS.CR_CRIT_RANGED)
        local critRatingSpell = GetCombatRating(Stats.COMBAT_RATINGS.CR_CRIT_SPELL)
        rating = math.max(critRatingMelee, critRatingRanged, critRatingSpell)
    elseif statType == Stats.STAT_TYPES.MASTERY then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_MASTERY)
    elseif statType == Stats.STAT_TYPES.VERSATILITY then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
    elseif statType == Stats.STAT_TYPES.SPEED then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_SPEED)
    elseif statType == Stats.STAT_TYPES.LEECH then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_LIFESTEAL)
    elseif statType == Stats.STAT_TYPES.AVOIDANCE then
        -- Avoidance rating is not directly accessible, return 0 to avoid errors
        rating = 0
    end

    return rating
end

-- Returns the color for a specific stat type
function Stats:GetColor(statType)
    if Stats.STAT_COLORS[statType] then
        return unpack(Stats.STAT_COLORS[statType])
    else
        return 0.8, 0.8, 0.8 -- Default to white/grey
    end
end

-- Returns the display name for a specific stat type
function Stats:GetName(statType)
    return Stats.STAT_NAMES[statType] or statType
end

-- Adds a class/spec-specific stat bonus to the table
-- Parameters:
--   className: The class name (e.g., "ROGUE", "MAGE", etc.)
--   specIndex: The specialization index (e.g., 1 for first spec, 2 for second spec, etc.)
--   statType: The stat type (e.g., Stats.STAT_TYPES.VERSATILITY)
--   bonusValue: The bonus value to add (e.g., 3 for 3%)
function Stats:AddClassSpecBonus(className, specIndex, statType, bonusValue)
    -- Initialize the class table if it doesn't exist
    if not Stats.CLASS_SPEC_BONUSES[className] then
        Stats.CLASS_SPEC_BONUSES[className] = {}
    end

    -- Initialize the spec table if it doesn't exist
    if not Stats.CLASS_SPEC_BONUSES[className][specIndex] then
        Stats.CLASS_SPEC_BONUSES[className][specIndex] = {}
    end

    -- Add the bonus
    Stats.CLASS_SPEC_BONUSES[className][specIndex][statType] = bonusValue
end

-- Removes a class/spec-specific stat bonus from the table
-- Parameters:
--   className: The class name (e.g., "ROGUE", "MAGE", etc.)
--   specIndex: The specialization index (e.g., 1 for first spec, 2 for second spec, etc.)
--   statType: The stat type (e.g., Stats.STAT_TYPES.VERSATILITY)
function Stats:RemoveClassSpecBonus(className, specIndex, statType)
    -- Check if the tables exist
    if Stats.CLASS_SPEC_BONUSES[className] and
       Stats.CLASS_SPEC_BONUSES[className][specIndex] then
        -- Remove the bonus
        Stats.CLASS_SPEC_BONUSES[className][specIndex][statType] = nil

        -- Clean up empty tables
        if next(Stats.CLASS_SPEC_BONUSES[className][specIndex]) == nil then
            Stats.CLASS_SPEC_BONUSES[className][specIndex] = nil
        end

        if next(Stats.CLASS_SPEC_BONUSES[className]) == nil then
            Stats.CLASS_SPEC_BONUSES[className] = nil
        end
    end
end

-- Gets the class/spec-specific stat bonus for a given combination
-- Parameters:
--   className: The class name (e.g., "ROGUE", "MAGE", etc.)
--   specIndex: The specialization index (e.g., 1 for first spec, 2 for second spec, etc.)
--   statType: The stat type (e.g., Stats.STAT_TYPES.VERSATILITY)
-- Returns:
--   The bonus value, or 0 if no bonus exists
function Stats:GetClassSpecBonus(className, specIndex, statType)
    -- Check if the tables exist and return the bonus if it exists
    if Stats.CLASS_SPEC_BONUSES[className] and
       Stats.CLASS_SPEC_BONUSES[className][specIndex] and
       Stats.CLASS_SPEC_BONUSES[className][specIndex][statType] then
        return Stats.CLASS_SPEC_BONUSES[className][specIndex][statType]
    end

    -- Return 0 if no bonus exists
    return 0
end

-- Gets all stat bonuses for the current player's class and spec
-- Returns:
--   A table of stat bonuses, where the keys are stat types and the values are bonus values
function Stats:GetCurrentClassSpecBonuses()
    local bonuses = {}
    local _, playerClass = UnitClass("player")
    local specIndex = GetSpecialization()

    -- Check if there are any bonuses for this class/spec combination
    if Stats.CLASS_SPEC_BONUSES[playerClass] and
       Stats.CLASS_SPEC_BONUSES[playerClass][specIndex] then
        -- Copy the bonuses to the result table
        for statType, bonusValue in pairs(Stats.CLASS_SPEC_BONUSES[playerClass][specIndex]) do
            bonuses[statType] = bonusValue
        end
    end

    return bonuses
end

return Stats
