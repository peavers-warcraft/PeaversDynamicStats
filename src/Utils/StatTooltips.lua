local addonName, PDS = ...

-- Initialize StatTooltips namespace
PDS.StatTooltips = {}
local StatTooltips = PDS.StatTooltips

-- Helper function to add a line to the tooltip
local function AddLine(tooltip, text, r, g, b, wrap)
    if not text or text == "" then return end

    r = r or 1
    g = g or 1
    b = b or 1

    tooltip:AddLine(text, r, g, b, wrap or false)
end

-- Helper function to add a header to the tooltip
local function AddHeader(tooltip, text)
    AddLine(tooltip, text, 1, 0.82, 0) -- Gold color for headers
end

-- Helper function to add a stat description to the tooltip
local function AddDescription(tooltip, text)
    AddLine(tooltip, text, 0.9, 0.9, 0.9, true) -- Light gray with text wrapping
end

-- Helper function to add a stat value to the tooltip
local function AddValue(tooltip, label, value, valueColor)
    local r, g, b = unpack(valueColor or {0.2, 0.8, 0.2}) -- Default to green
    tooltip:AddDoubleLine(label, value, 1, 1, 1, r, g, b)
end

-- Helper function to calculate rating needed for next percentage point
local function GetRatingForNextPercent(statType, currentRating, currentPercent)
    -- This is an approximation and would need to be adjusted for each stat type
    -- and character level in a real implementation
    local nextPercent = math.floor(currentPercent) + 1
    local ratingPerPercent = currentRating / currentPercent

    if ratingPerPercent <= 0 then return 0 end

    return math.ceil(nextPercent * ratingPerPercent - currentRating)
end

-- Generate tooltip content for Haste
function StatTooltips:GetHasteTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Haste")
    AddDescription(tooltip, "Increases attack speed, casting speed, and some resource generation rates.")

    -- Current values
    AddValue(tooltip, "Current Haste", PDS.Utils:FormatPercent(value), {0, 0.9, 0.9}) -- Cyan to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0, 0.9, 0.9})

        -- Rating needed for next percentage point
        local ratingForNext = GetRatingForNextPercent("HASTE", rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " faster casting speed", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " faster attack speed", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Reduces global cooldown", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Critical Strike
function StatTooltips:GetCritTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Critical Strike")
    AddDescription(tooltip, "Increases your chance to critically strike with attacks and spells, dealing increased damage or healing.")

    -- Current values
    AddValue(tooltip, "Current Crit Chance", PDS.Utils:FormatPercent(value), {0.9, 0.9, 0}) -- Yellow to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.9, 0.9, 0})

        -- Rating needed for next percentage point
        local ratingForNext = GetRatingForNextPercent("CRIT", rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " chance to critically strike", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Critical strikes deal 200% damage", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Critical heals provide 200% healing", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Mastery
function StatTooltips:GetMasteryTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Mastery")
    AddDescription(tooltip, "Improves a class-specific bonus determined by your specialization.")

    -- Current values
    AddValue(tooltip, "Current Mastery", PDS.Utils:FormatPercent(value), {0.9, 0.4, 0}) -- Orange to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.9, 0.4, 0})

        -- Rating needed for next percentage point
        local ratingForNext = GetRatingForNextPercent("MASTERY", rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Try to get player spec info
    local specID = GetSpecialization()
    local specName, specDescription

    if specID then
        _, specName = GetSpecializationInfo(specID)
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)

    if specName then
        AddLine(tooltip, "• " .. specName .. " Mastery bonus", 0.8, 0.8, 0.8, true)
    else
        AddLine(tooltip, "• Improves your specialization's unique bonus", 0.8, 0.8, 0.8, true)
    end
end

-- Generate tooltip content for Versatility
function StatTooltips:GetVersatilityTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Versatility")
    AddDescription(tooltip, "Increases damage and healing done, and reduces damage taken.")

    -- Current values
    AddValue(tooltip, "Damage/Healing Bonus", PDS.Utils:FormatPercent(value), {0.2, 0.6, 0.2}) -- Green to match bar color
    AddValue(tooltip, "Damage Reduction", PDS.Utils:FormatPercent(value / 2), {0.2, 0.6, 0.2})

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.2, 0.6, 0.2})

        -- Rating needed for next percentage point
        local ratingForNext = GetRatingForNextPercent("VERSATILITY", rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " increased damage and healing", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value / 2) .. " reduced damage taken", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Speed
function StatTooltips:GetSpeedTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Speed")
    AddDescription(tooltip, "Increases movement speed.")

    -- Current values
    AddValue(tooltip, "Movement Speed Bonus", PDS.Utils:FormatPercent(value), {0.7, 0.3, 0.9}) -- Purple to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.7, 0.3, 0.9})

        -- Rating needed for next percentage point
        local ratingForNext = GetRatingForNextPercent("SPEED", rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " increased movement speed", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Leech
function StatTooltips:GetLeechTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Leech")
    AddDescription(tooltip, "Heals you for a portion of all damage and healing done.")

    -- Current values
    AddValue(tooltip, "Leech Percentage", PDS.Utils:FormatPercent(value), {0.9, 0.2, 0.2}) -- Red to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.9, 0.2, 0.2})

        -- Rating needed for next percentage point
        local ratingForNext = GetRatingForNextPercent("LEECH", rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• Heals for " .. PDS.Utils:FormatPercent(value) .. " of all damage done", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Heals for " .. PDS.Utils:FormatPercent(value) .. " of all healing done", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Avoidance
function StatTooltips:GetAvoidanceTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Avoidance")
    AddDescription(tooltip, "Reduces area-of-effect damage taken.")

    -- Current values
    AddValue(tooltip, "AoE Damage Reduction", PDS.Utils:FormatPercent(value), {0.2, 0.4, 0.9}) -- Blue to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.2, 0.4, 0.9})

        -- Rating needed for next percentage point
        local ratingForNext = GetRatingForNextPercent("AVOIDANCE", rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " reduced area-of-effect damage taken", 0.8, 0.8, 0.8, true)
end

-- Main function to show tooltip for a specific stat type
function StatTooltips:ShowTooltip(tooltip, statType, value, rating)
    if not tooltip or not statType then return end

    -- Clear any existing tooltip content
    tooltip:ClearLines()

    -- Call the appropriate tooltip function based on stat type
    if statType == PDS.Stats.STAT_TYPES.HASTE then
        self:GetHasteTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.CRIT then
        self:GetCritTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.MASTERY then
        self:GetMasteryTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.VERSATILITY then
        self:GetVersatilityTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.SPEED then
        self:GetSpeedTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.LEECH then
        self:GetLeechTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.AVOIDANCE then
        self:GetAvoidanceTooltip(tooltip, value, rating)
    end

    -- Show the tooltip
    tooltip:Show()
end

return StatTooltips
