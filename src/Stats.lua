local _, PDS = ...
local Stats = PDS.Stats

-- Combat Rating constants - updated for 11.0.0+
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
    CR_LIFESTEAL = 32,
    CR_AVOIDANCE = 33
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
    [Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE] = "Versatility (Damage)",
    [Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION] = "Versatility (Defense)",
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
    Stats.STAT_TYPES.SPEED,
    Stats.STAT_TYPES.LEECH,
    Stats.STAT_TYPES.AVOIDANCE,
    Stats.STAT_TYPES.DODGE,
    Stats.STAT_TYPES.PARRY,
    Stats.STAT_TYPES.BLOCK
}

-- Class spec bonuses - Using Blizzard API directly when possible
Stats.CLASS_SPEC_BONUSES = {
    -- Rogue
    ["ROGUE"] = {
        -- Outlaw (spec index 2)
        [2] = {
            [Stats.STAT_TYPES.VERSATILITY] = 3 -- 3% versatility bonus from talent
        }
    }
}

-- Initialize base values for primary stats
function Stats:InitializeBaseValues()
    local baseStr, _, _, _ = UnitStat("player", 1)
    local baseAgi, _, _, _ = UnitStat("player", 2)
    local baseInt, _, _, _ = UnitStat("player", 4)
    local baseSta, _, _, _ = UnitStat("player", 3)

    Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH] = baseStr
    Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY] = baseAgi
    Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT] = baseInt
    Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA] = baseSta
end

-- Returns the buff value (positive and negative combined) for the specified stat
function Stats:GetBuffValue(statType)
    local buffValue = 0

    if statType == Stats.STAT_TYPES.STRENGTH then
        local _, _, posBuff, negBuff = UnitStat("player", 1)
        buffValue = posBuff + negBuff
    elseif statType == Stats.STAT_TYPES.AGILITY then
        local _, _, posBuff, negBuff = UnitStat("player", 2)
        buffValue = posBuff + negBuff
    elseif statType == Stats.STAT_TYPES.STAMINA then
        local _, _, posBuff, negBuff = UnitStat("player", 3)
        buffValue = posBuff + negBuff
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        local _, _, posBuff, negBuff = UnitStat("player", 4)
        buffValue = posBuff + negBuff
    end

    return buffValue
end

-- Returns the buff percentage for the specified stat
function Stats:GetBuffPercentage(statType)
    local buffPercentage = 0

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

-- Returns the current value of the specified stat using the latest APIs
function Stats:GetValue(statType)
    local value = 0

    -- Primary stats
    if statType == Stats.STAT_TYPES.STRENGTH then
        if C_Attributes and C_Attributes.GetAttribute then
            value = C_Attributes.GetAttribute("player", "Strength") or 0
        else
            local base, total, posBuff, negBuff = UnitStat("player", 1)
            if Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH] > 0 then
                value = 100
                if base > Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH] then
                    value = value + ((base - Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH]) / Stats.BASE_VALUES[Stats.STAT_TYPES.STRENGTH]) * 100
                end
                local buffPercentage = self:GetBuffPercentage(Stats.STAT_TYPES.STRENGTH)
                value = value + buffPercentage
            else
                self:InitializeBaseValues()
                value = 100
            end
        end
    elseif statType == Stats.STAT_TYPES.AGILITY then
        if C_Attributes and C_Attributes.GetAttribute then
            value = C_Attributes.GetAttribute("player", "Agility") or 0
        else
            local base, total, posBuff, negBuff = UnitStat("player", 2)
            if Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY] > 0 then
                value = 100
                if base > Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY] then
                    value = value + ((base - Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY]) / Stats.BASE_VALUES[Stats.STAT_TYPES.AGILITY]) * 100
                end
                local buffPercentage = self:GetBuffPercentage(Stats.STAT_TYPES.AGILITY)
                value = value + buffPercentage
            else
                self:InitializeBaseValues()
                value = 100
            end
        end
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        if C_Attributes and C_Attributes.GetAttribute then
            value = C_Attributes.GetAttribute("player", "Intellect") or 0
        else
            local base, total, posBuff, negBuff = UnitStat("player", 4)
            if Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT] > 0 then
                value = 100
                if base > Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT] then
                    value = value + ((base - Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT]) / Stats.BASE_VALUES[Stats.STAT_TYPES.INTELLECT]) * 100
                end
                local buffPercentage = self:GetBuffPercentage(Stats.STAT_TYPES.INTELLECT)
                value = value + buffPercentage
            else
                self:InitializeBaseValues()
                value = 100
            end
        end
    elseif statType == Stats.STAT_TYPES.STAMINA then
        if C_Attributes and C_Attributes.GetAttribute then
            value = C_Attributes.GetAttribute("player", "Stamina") or 0
        else
            local base, total, posBuff, negBuff = UnitStat("player", 3)
            if Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA] > 0 then
                value = 100
                if base > Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA] then
                    value = value + ((base - Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA]) / Stats.BASE_VALUES[Stats.STAT_TYPES.STAMINA]) * 100
                end
                local buffPercentage = self:GetBuffPercentage(Stats.STAT_TYPES.STAMINA)
                value = value + buffPercentage
            else
                self:InitializeBaseValues()
                value = 100
            end
        end
        -- Secondary stats - Using direct API calls
    elseif statType == Stats.STAT_TYPES.HASTE then
        value = GetHaste()
    elseif statType == Stats.STAT_TYPES.CRIT then
        value = GetCritChance()
    elseif statType == Stats.STAT_TYPES.MASTERY then
        value = GetMasteryEffect()
    elseif statType == Stats.STAT_TYPES.VERSATILITY then
        -- Fix for versatility stats
        value = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
    elseif statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE then
        value = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
    elseif statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION then
        value = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_TAKEN)
    elseif statType == Stats.STAT_TYPES.SPEED then
        value = GetSpeed()
    elseif statType == Stats.STAT_TYPES.LEECH then
        value = GetLifesteal()
    elseif statType == Stats.STAT_TYPES.AVOIDANCE then
        value = GetAvoidance()
    elseif statType == Stats.STAT_TYPES.DODGE then
        value = GetDodgeChance()
    elseif statType == Stats.STAT_TYPES.PARRY then
        value = GetParryChance()
    elseif statType == Stats.STAT_TYPES.BLOCK then
        value = GetBlockChance()
    end

    -- Apply class/spec-specific bonuses
    local _, playerClass = UnitClass("player")
    local specIndex = GetSpecialization()

    if Stats.CLASS_SPEC_BONUSES[playerClass] and
            Stats.CLASS_SPEC_BONUSES[playerClass][specIndex] and
            Stats.CLASS_SPEC_BONUSES[playerClass][specIndex][statType] then
        value = value + Stats.CLASS_SPEC_BONUSES[playerClass][specIndex][statType]
    end

    return value
end

-- Gets the raw rating value for the specified stat type
function Stats:GetRating(statType)
    local rating = 0

    -- Primary stats - return the total stat value
    if statType == Stats.STAT_TYPES.STRENGTH then
        if C_Stats and C_Stats.GetStatByID then
            rating = C_Stats.GetStatByID(1) or 0
        else
            local _, total = UnitStat("player", 1)
            rating = total or 0
        end
    elseif statType == Stats.STAT_TYPES.AGILITY then
        if C_Stats and C_Stats.GetStatByID then
            rating = C_Stats.GetStatByID(2) or 0
        else
            local _, total = UnitStat("player", 2)
            rating = total or 0
        end
    elseif statType == Stats.STAT_TYPES.INTELLECT then
        if C_Stats and C_Stats.GetStatByID then
            rating = C_Stats.GetStatByID(4) or 0
        else
            local _, total = UnitStat("player", 4)
            rating = total or 0
        end
    elseif statType == Stats.STAT_TYPES.STAMINA then
        if C_Stats and C_Stats.GetStatByID then
            rating = C_Stats.GetStatByID(3) or 0
        else
            local _, total = UnitStat("player", 3)
            rating = total or 0
        end
        -- Secondary stats - return the combat rating using direct API calls
    elseif statType == Stats.STAT_TYPES.HASTE then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_HASTE_MELEE)
    elseif statType == Stats.STAT_TYPES.CRIT then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_CRIT_MELEE)
    elseif statType == Stats.STAT_TYPES.MASTERY then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_MASTERY)
    elseif statType == Stats.STAT_TYPES.VERSATILITY or statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
    elseif statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_REDUCTION then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_TAKEN)
    elseif statType == Stats.STAT_TYPES.SPEED then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_SPEED)
    elseif statType == Stats.STAT_TYPES.LEECH then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_LIFESTEAL)
    elseif statType == Stats.STAT_TYPES.AVOIDANCE then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_AVOIDANCE)
    elseif statType == Stats.STAT_TYPES.DODGE then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_DODGE)
    elseif statType == Stats.STAT_TYPES.PARRY then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_PARRY)
    elseif statType == Stats.STAT_TYPES.BLOCK then
        rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_BLOCK)
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
function Stats:AddClassSpecBonus(className, specIndex, statType, bonusValue)
    if not Stats.CLASS_SPEC_BONUSES[className] then
        Stats.CLASS_SPEC_BONUSES[className] = {}
    end

    if not Stats.CLASS_SPEC_BONUSES[className][specIndex] then
        Stats.CLASS_SPEC_BONUSES[className][specIndex] = {}
    end

    Stats.CLASS_SPEC_BONUSES[className][specIndex][statType] = bonusValue
end

-- Removes a class/spec-specific stat bonus from the table
function Stats:RemoveClassSpecBonus(className, specIndex, statType)
    if Stats.CLASS_SPEC_BONUSES[className] and Stats.CLASS_SPEC_BONUSES[className][specIndex] then
        Stats.CLASS_SPEC_BONUSES[className][specIndex][statType] = nil

        if next(Stats.CLASS_SPEC_BONUSES[className][specIndex]) == nil then
            Stats.CLASS_SPEC_BONUSES[className][specIndex] = nil
        end

        if next(Stats.CLASS_SPEC_BONUSES[className]) == nil then
            Stats.CLASS_SPEC_BONUSES[className] = nil
        end
    end
end

-- Gets the class/spec-specific stat bonus for a given combination
function Stats:GetClassSpecBonus(className, specIndex, statType)
    if Stats.CLASS_SPEC_BONUSES[className] and
            Stats.CLASS_SPEC_BONUSES[className][specIndex] and
            Stats.CLASS_SPEC_BONUSES[className][specIndex][statType] then
        return Stats.CLASS_SPEC_BONUSES[className][specIndex][statType]
    end

    return 0
end

-- Gets all stat bonuses for the current player's class and spec
function Stats:GetCurrentClassSpecBonuses()
    local bonuses = {}
    local _, playerClass = UnitClass("player")
    local specIndex = GetSpecialization()

    if Stats.CLASS_SPEC_BONUSES[playerClass] and
            Stats.CLASS_SPEC_BONUSES[playerClass][specIndex] then
        for statType, bonusValue in pairs(Stats.CLASS_SPEC_BONUSES[playerClass][specIndex]) do
            bonuses[statType] = bonusValue
        end
    end

    return bonuses
end

-- Gets the rating needed for 1% of a stat using the API directly
function Stats:GetRatingPer1Percent(statType)
    local ratingPer1Percent = 0

    if statType == Stats.STAT_TYPES.HASTE then
        local bonus = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_HASTE_MELEE)
        local rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_HASTE_MELEE)
        if rating > 0 then
            ratingPer1Percent = bonus / rating
        end
    elseif statType == Stats.STAT_TYPES.CRIT then
        local bonus = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_CRIT_MELEE)
        local rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_CRIT_MELEE)
        if rating > 0 then
            ratingPer1Percent = bonus / rating
        end
    elseif statType == Stats.STAT_TYPES.MASTERY then
        local bonus = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_MASTERY)
        local rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_MASTERY)
        if rating > 0 then
            ratingPer1Percent = bonus / rating
        end
    elseif statType == Stats.STAT_TYPES.VERSATILITY or statType == Stats.STAT_TYPES.VERSATILITY_DAMAGE_DONE then
        local bonus = GetCombatRatingBonus(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
        local rating = GetCombatRating(Stats.COMBAT_RATINGS.CR_VERSATILITY_DAMAGE_DONE)
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
function Stats:GetDisplayValue(statType, value, showRating)
    local displayValue = PDS.Utils:FormatPercent(value)

    if showRating == nil then
        showRating = PDS.Config.showRatings
    end

    if showRating then
        local rating = self:GetRating(statType)
        displayValue = displayValue .. " | " .. math.floor(rating + 0.5)
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
