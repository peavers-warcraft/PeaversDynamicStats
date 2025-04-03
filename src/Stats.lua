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
}

-- Stat display names
Stats.STAT_NAMES = {
    -- Primary stats
    [Stats.STAT_TYPES.STRENGTH] = "Strength",
    [Stats.STAT_TYPES.AGILITY] = "Agility",
    [Stats.STAT_TYPES.INTELLECT] = "Intellect",
    [Stats.STAT_TYPES.STAMINA] = "Stamina",

    -- Secondary stats
    [Stats.STAT_TYPES.HASTE] = "Haste",
    [Stats.STAT_TYPES.CRIT] = "Critical Strike",
    [Stats.STAT_TYPES.MASTERY] = "Mastery",
    [Stats.STAT_TYPES.VERSATILITY] = "Versatility",
    [Stats.STAT_TYPES.SPEED] = "Speed",
    [Stats.STAT_TYPES.LEECH] = "Leech",
    [Stats.STAT_TYPES.AVOIDANCE] = "Avoidance",

    -- Combat ratings
    [Stats.STAT_TYPES.DEFENSE] = "Defense",
    [Stats.STAT_TYPES.DODGE] = "Dodge",
    [Stats.STAT_TYPES.PARRY] = "Parry",
    [Stats.STAT_TYPES.BLOCK] = "Block",
    [Stats.STAT_TYPES.ARMOR_PENETRATION] = "Armor Penetration"
}

-- Stat colors (r, g, b)
Stats.STAT_COLORS = {
    -- Primary stats
    [Stats.STAT_TYPES.STRENGTH] = { 0.77, 0.31, 0.23 }, -- Terracotta
    [Stats.STAT_TYPES.AGILITY] = { 0.56, 0.66, 0.46 }, -- Sage Green
    [Stats.STAT_TYPES.INTELLECT] = { 0.52, 0.62, 0.74 }, -- Slate Blue
    [Stats.STAT_TYPES.STAMINA] = { 0.87, 0.57, 0.34 }, -- Amber

    -- Secondary stats
    [Stats.STAT_TYPES.HASTE] = { 0.42, 0.59, 0.59 }, -- Muted Teal
    [Stats.STAT_TYPES.CRIT] = { 0.85, 0.76, 0.47 }, -- Wheat
    [Stats.STAT_TYPES.MASTERY] = { 0.76, 0.52, 0.38 }, -- Sienna
    [Stats.STAT_TYPES.VERSATILITY] = { 0.63, 0.69, 0.58 }, -- Olive Green
    [Stats.STAT_TYPES.SPEED] = { 0.67, 0.55, 0.67 }, -- Muted Lavender
    [Stats.STAT_TYPES.LEECH] = { 0.69, 0.47, 0.43 }, -- Clay
    [Stats.STAT_TYPES.AVOIDANCE] = { 0.59, 0.67, 0.76 }, -- Dusty Blue

    -- Combat ratings
    [Stats.STAT_TYPES.DEFENSE] = { 0.50, 0.50, 0.80 }, -- Steel Blue
    [Stats.STAT_TYPES.DODGE] = { 0.40, 0.70, 0.40 }, -- Forest Green
    [Stats.STAT_TYPES.PARRY] = { 0.70, 0.40, 0.40 }, -- Rust Red
    [Stats.STAT_TYPES.BLOCK] = { 0.60, 0.60, 0.30 }, -- Olive
    [Stats.STAT_TYPES.ARMOR_PENETRATION] = { 0.75, 0.60, 0.30 } -- Bronze
}

-- Default stat order
Stats.STAT_ORDER = {
    -- Primary stats first
    Stats.STAT_TYPES.STRENGTH,
    Stats.STAT_TYPES.AGILITY,
    Stats.STAT_TYPES.INTELLECT,
    Stats.STAT_TYPES.STAMINA,

    -- Then secondary stats
    Stats.STAT_TYPES.CRIT,
    Stats.STAT_TYPES.HASTE,
    Stats.STAT_TYPES.MASTERY,
    Stats.STAT_TYPES.VERSATILITY,
    Stats.STAT_TYPES.SPEED,
    Stats.STAT_TYPES.LEECH,
    Stats.STAT_TYPES.AVOIDANCE,

    -- Then combat ratings
    Stats.STAT_TYPES.DEFENSE,
    Stats.STAT_TYPES.DODGE,
    Stats.STAT_TYPES.PARRY,
    Stats.STAT_TYPES.BLOCK,
    Stats.STAT_TYPES.ARMOR_PENETRATION
}

-- Store base values for primary stats
Stats.BASE_VALUES = {
    [Stats.STAT_TYPES.STRENGTH] = 0,
    [Stats.STAT_TYPES.AGILITY] = 0,
    [Stats.STAT_TYPES.INTELLECT] = 0,
    [Stats.STAT_TYPES.STAMINA] = 0
}

-- Initialize base values for primary stats
function Stats:InitializeBaseValues()
    local _, class = UnitClass("player")

    -- Get base values for primary stats (excluding buffs)
    -- UnitStat returns: base, stat, posBuff, negBuff
    local baseStr, _, _, _ = UnitStat("player", 1)
    local baseAgi, _, _, _ = UnitStat("player", 2)
    local baseInt, _, _, _ = UnitStat("player", 4)
    local baseSta, _, _, _ = UnitStat("player", 3)

    -- Store the base values
    Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH] = baseStr
    Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY] = baseAgi
    Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT] = baseInt
    Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA] = baseSta
end

-- Returns the current value of the specified stat
function Stats:GetValue(statType)
    local value = 0

    -- Primary stats
    if statType == Stats.STAT_TYPES.STRENGTH then
        -- Get current strength values (base, total, posBuff, negBuff)
        local base, total, posBuff, negBuff = UnitStat("player", 1)
        -- Calculate percentage increase from base
        if Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH] > 0 then
            -- Calculate percentage based on base (excluding buffs)
            -- Start with 100% (base value)
            value = 100
            -- Add percentage from base stat growth (if any)
            if base > Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH] then
                value = value + ((base - Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH]) / Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH]) * 100
            end
            -- Add buff percentage (if any)
            local buffPercentage = self:GetBuffPercentage(Stats.STAT_TYPES.STRENGTH)
            value = value + buffPercentage
        else
            -- Initialize base values if not set
            self:InitializeBaseValues()
            value = 100
        end
    elseif statType == Stats.STAT_TYPES.AGILITY then
        -- Get current agility values (base, total, posBuff, negBuff)
        local base, total, posBuff, negBuff = UnitStat("player", 2)
        -- Calculate percentage increase from base
        if Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY] > 0 then
            -- Calculate percentage based on base (excluding buffs)
            -- Start with 100% (base value)
            value = 100
            -- Add percentage from base stat growth (if any)
            if base > Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY] then
                value = value + ((base - Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY]) / Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY]) * 100
            end
            -- Add buff percentage (if any)
            local buffPercentage = self:GetBuffPercentage(Stats.STAT_TYPES.AGILITY)
            value = value + buffPercentage
        else
            -- Initialize base values if not set
            self:InitializeBaseValues()
            value = 100
        end
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        -- Get current intellect values (base, total, posBuff, negBuff)
        local base, total, posBuff, negBuff = UnitStat("player", 4)
        -- Calculate percentage increase from base
        if Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT] > 0 then
            -- Calculate percentage based on base (excluding buffs)
            -- Start with 100% (base value)
            value = 100
            -- Add percentage from base stat growth (if any)
            if base > Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT] then
                value = value + ((base - Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT]) / Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT]) * 100
            end
            -- Add buff percentage (if any)
            local buffPercentage = self:GetBuffPercentage(Stats.STAT_TYPES.INTELLECT)
            value = value + buffPercentage
        else
            -- Initialize base values if not set
            self:InitializeBaseValues()
            value = 100
        end
    elseif statType == Stats.STAT_TYPES.STAMINA then
        -- Get current stamina values (base, total, posBuff, negBuff)
        local base, total, posBuff, negBuff = UnitStat("player", 3)
        -- Calculate percentage increase from base
        if Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA] > 0 then
            -- Calculate percentage based on base (excluding buffs)
            -- Start with 100% (base value)
            value = 100
            -- Add percentage from base stat growth (if any)
            if base > Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA] then
                value = value + ((base - Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA]) / Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA]) * 100
            end
            -- Add buff percentage (if any)
            local buffPercentage = self:GetBuffPercentage(Stats.STAT_TYPES.STAMINA)
            value = value + buffPercentage
        else
            -- Initialize base values if not set
            self:InitializeBaseValues()
            value = 100
        end
    -- Secondary stats
    elseif statType == Stats.STAT_TYPES.HASTE then
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
    elseif statType == Stats.STAT_TYPES.DEFENSE then
        value = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_DEFENSE_SKILL)
    elseif statType == Stats.STAT_TYPES.DODGE then
        value = GetDodgeChance()
    elseif statType == Stats.STAT_TYPES.PARRY then
        value = GetParryChance()
    elseif statType == Stats.STAT_TYPES.BLOCK then
        value = GetBlockChance()
    elseif statType == Stats.STAT_TYPES.ARMOR_PENETRATION then
        value = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_ARMOR_PENETRATION)
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

-- Returns the buff value (positive and negative combined) for the specified stat
function Stats:GetBuffValue(statType)
    local buffValue = 0

    -- Primary stats
    if statType == Stats.STAT_TYPES.STRENGTH then
        local _, total, posBuff, negBuff = UnitStat("player", 1)
        buffValue = posBuff + negBuff -- negBuff is usually negative, so this is correct
    elseif statType == Stats.STAT_TYPES.AGILITY then
        local _, total, posBuff, negBuff = UnitStat("player", 2)
        buffValue = posBuff + negBuff
    elseif statType == Stats.STAT_TYPES.STAMINA then
        local _, total, posBuff, negBuff = UnitStat("player", 3)
        buffValue = posBuff + negBuff
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        local _, total, posBuff, negBuff = UnitStat("player", 4)
        buffValue = posBuff + negBuff
    end

    return buffValue
end

-- Returns the buff percentage for the specified stat
function Stats:GetBuffPercentage(statType)
    local buffPercentage = 0

    -- Primary stats
    if statType == Stats.STAT_TYPES.STRENGTH then
        local base, _, posBuff, negBuff = UnitStat("player", 1)
        if base > 0 then
            buffPercentage = ((posBuff + negBuff) / base) * 100
        end
    elseif statType == Stats.STAT_TYPES.AGILITY then
        local base, _, posBuff, negBuff = UnitStat("player", 2)
        if base > 0 then
            buffPercentage = ((posBuff + negBuff) / base) * 100
        end
    elseif statType == Stats.STAT_TYPES.STAMINA then
        local base, _, posBuff, negBuff = UnitStat("player", 3)
        if base > 0 then
            buffPercentage = ((posBuff + negBuff) / base) * 100
        end
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        local base, _, posBuff, negBuff = UnitStat("player", 4)
        if base > 0 then
            buffPercentage = ((posBuff + negBuff) / base) * 100
        end
    end

    return buffPercentage
end

-- Returns the raw combat rating value for the specified stat type
function Stats:GetRating(statType)
    local rating = 0

    -- Primary stats - return the base stat value (excluding buffs)
    if statType == Stats.STAT_TYPES.STRENGTH then
        local base, _, _, _ = UnitStat("player", 1)
        rating = base
    elseif statType == Stats.STAT_TYPES.AGILITY then
        local base, _, _, _ = UnitStat("player", 2)
        rating = base
    elseif statType == Stats.STAT_TYPES.STAMINA then
        local base, _, _, _ = UnitStat("player", 3)
        rating = base
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        local base, _, _, _ = UnitStat("player", 4)
        rating = base
    -- Secondary stats - return the combat rating
    elseif statType == Stats.STAT_TYPES.HASTE then
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
    elseif statType == Stats.STAT_TYPES.DEFENSE then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_DEFENSE_SKILL)
    elseif statType == Stats.STAT_TYPES.DODGE then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_DODGE)
    elseif statType == Stats.STAT_TYPES.PARRY then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_PARRY)
    elseif statType == Stats.STAT_TYPES.BLOCK then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_BLOCK)
    elseif statType == Stats.STAT_TYPES.ARMOR_PENETRATION then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_ARMOR_PENETRATION)
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
