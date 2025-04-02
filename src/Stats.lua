local _, PDS = ...
local Stats = PDS.Stats

-- Stat types
Stats.STAT_TYPES = {
    HASTE = "HASTE",
    CRIT = "CRIT",
    MASTERY = "MASTERY",
    VERSATILITY = "VERSATILITY"
}

-- Stat display names
Stats.STAT_NAMES = {
    [Stats.STAT_TYPES.HASTE] = "Haste",
    [Stats.STAT_TYPES.CRIT] = "Critical Strike",
    [Stats.STAT_TYPES.MASTERY] = "Mastery",
    [Stats.STAT_TYPES.VERSATILITY] = "Versatility"
}

-- Stat colors (r, g, b)
Stats.STAT_COLORS = {
    [Stats.STAT_TYPES.HASTE] = { 0.0, 0.9, 0.9 }, -- Cyan
    [Stats.STAT_TYPES.CRIT] = { 0.9, 0.9, 0.0 }, -- Yellow
    [Stats.STAT_TYPES.MASTERY] = { 0.9, 0.4, 0.0 }, -- Orange
    [Stats.STAT_TYPES.VERSATILITY] = { 0.2, 0.6, 0.2 } -- Green
}

-- Default stat order
Stats.STAT_ORDER = {
    Stats.STAT_TYPES.HASTE,
    Stats.STAT_TYPES.CRIT,
    Stats.STAT_TYPES.MASTERY,
    Stats.STAT_TYPES.VERSATILITY
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
        value = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
    end

    return value
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

return Stats
