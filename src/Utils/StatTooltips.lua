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


-- Generate tooltip content for Haste
function StatTooltips:GetHasteTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Haste")
    AddDescription(tooltip, "Increases attack speed, casting speed, and some resource generation rates.")

    -- Current values
    AddValue(tooltip, "Current Haste", PDS.Utils:FormatPercent(value), {0.6, 0.95, 0.95}) -- Pastel Cyan to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.6, 0.95, 0.95})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.HASTE, rating, value)
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
    AddValue(tooltip, "Current Crit Chance", PDS.Utils:FormatPercent(value), {0.95, 0.95, 0.6}) -- Pastel Yellow to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.95, 0.95, 0.6})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.CRIT, rating, value)
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
    AddValue(tooltip, "Current Mastery", PDS.Utils:FormatPercent(value), {0.95, 0.7, 0.5}) -- Pastel Orange to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.95, 0.7, 0.5})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.MASTERY, rating, value)
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
    AddValue(tooltip, "Damage/Healing Bonus", PDS.Utils:FormatPercent(value), {0.7, 0.9, 0.7}) -- Pastel Green to match bar color
    AddValue(tooltip, "Damage Reduction", PDS.Utils:FormatPercent(value / 2), {0.7, 0.9, 0.7})

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.7, 0.9, 0.7})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.VERSATILITY, rating, value)
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
    AddValue(tooltip, "Current Speed Bonus", PDS.Utils:FormatPercent(value), {0.85, 0.7, 0.95}) -- Pastel Purple to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.85, 0.7, 0.95})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.SPEED, rating, value)
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
    AddValue(tooltip, "Current Leech", PDS.Utils:FormatPercent(value), {0.95, 0.7, 0.7}) -- Pastel Red to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.95, 0.7, 0.7})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.LEECH, rating, value)
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
    AddValue(tooltip, "AoE Damage Reduction", PDS.Utils:FormatPercent(value), {0.7, 0.8, 0.95}) -- Pastel Blue to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.7, 0.8, 0.95})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.AVOIDANCE, rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " reduced area-of-effect damage taken", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Strength
function StatTooltips:GetStrengthTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Strength")
    AddDescription(tooltip, "Increases attack power for Paladins, Warriors, and Death Knights.")

    -- Current values
    AddValue(tooltip, "Percent Increase", PDS.Utils:FormatPercent(value), {0.95, 0.6, 0.6}) -- Pastel Red to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Strength", math.floor(rating + 0.5), {0.95, 0.6, 0.6})
        AddValue(tooltip, "Base Strength", math.floor(PDS.Stats.BASE_VALUES[PDS.Stats.STAT_TYPES.STRENGTH] + 0.5), {0.7, 0.7, 0.7})

        -- Show buff information if there are any buffs
        local buffValue = PDS.Stats:GetBuffValue(PDS.Stats.STAT_TYPES.STRENGTH)
        if buffValue ~= 0 then
            local buffColor = buffValue > 0 and {0.0, 0.8, 0.0} or {0.8, 0.0, 0.0} -- Green for positive, red for negative
            AddValue(tooltip, "Strength from Buffs", math.floor(buffValue + 0.5) .. " (" .. PDS.Utils:FormatPercent(PDS.Stats:GetBuffPercentage(PDS.Stats.STAT_TYPES.STRENGTH)) .. ")", buffColor)
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• Increases attack power", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Increases parry rating for some classes", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Agility
function StatTooltips:GetAgilityTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Agility")
    AddDescription(tooltip, "Increases attack power for Hunters, Rogues, Shamans, Monks, and Druids.")

    -- Current values
    AddValue(tooltip, "Percent Increase", PDS.Utils:FormatPercent(value), {0.6, 0.95, 0.6}) -- Pastel Green to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Agility", math.floor(rating + 0.5), {0.6, 0.95, 0.6})
        AddValue(tooltip, "Base Agility", math.floor(PDS.Stats.BASE_VALUES[PDS.Stats.STAT_TYPES.AGILITY] + 0.5), {0.7, 0.7, 0.7})

        -- Show buff information if there are any buffs
        local buffValue = PDS.Stats:GetBuffValue(PDS.Stats.STAT_TYPES.AGILITY)
        if buffValue ~= 0 then
            local buffColor = buffValue > 0 and {0.0, 0.8, 0.0} or {0.8, 0.0, 0.0} -- Green for positive, red for negative
            AddValue(tooltip, "Agility from Buffs", math.floor(buffValue + 0.5) .. " (" .. PDS.Utils:FormatPercent(PDS.Stats:GetBuffPercentage(PDS.Stats.STAT_TYPES.AGILITY)) .. ")", buffColor)
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• Increases attack power", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Increases critical strike chance", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Increases dodge rating for some classes", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Intellect
function StatTooltips:GetIntellectTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Intellect")
    AddDescription(tooltip, "Increases spell power for Priests, Mages, Warlocks, Druids, Shamans, Monks, and Paladins.")

    -- Current values
    AddValue(tooltip, "Percent Increase", PDS.Utils:FormatPercent(value), {0.6, 0.6, 0.95}) -- Pastel Blue to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Intellect", math.floor(rating + 0.5), {0.6, 0.6, 0.95})
        AddValue(tooltip, "Base Intellect", math.floor(PDS.Stats.BASE_VALUES[PDS.Stats.STAT_TYPES.INTELLECT] + 0.5), {0.7, 0.7, 0.7})

        -- Show buff information if there are any buffs
        local buffValue = PDS.Stats:GetBuffValue(PDS.Stats.STAT_TYPES.INTELLECT)
        if buffValue ~= 0 then
            local buffColor = buffValue > 0 and {0.0, 0.8, 0.0} or {0.8, 0.0, 0.0} -- Green for positive, red for negative
            AddValue(tooltip, "Intellect from Buffs", math.floor(buffValue + 0.5) .. " (" .. PDS.Utils:FormatPercent(PDS.Stats:GetBuffPercentage(PDS.Stats.STAT_TYPES.INTELLECT)) .. ")", buffColor)
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• Increases spell power", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Increases critical strike chance", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Stamina
function StatTooltips:GetStaminaTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Stamina")
    AddDescription(tooltip, "Increases health points for all classes.")

    -- Current values
    AddValue(tooltip, "Percent Increase", PDS.Utils:FormatPercent(value), {0.95, 0.8, 0.6}) -- Pastel Orange to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Stamina", math.floor(rating + 0.5), {0.95, 0.8, 0.6})
        AddValue(tooltip, "Base Stamina", math.floor(PDS.Stats.BASE_VALUES[PDS.Stats.STAT_TYPES.STAMINA] + 0.5), {0.7, 0.7, 0.7})

        -- Show buff information if there are any buffs
        local buffValue = PDS.Stats:GetBuffValue(PDS.Stats.STAT_TYPES.STAMINA)
        if buffValue ~= 0 then
            local buffColor = buffValue > 0 and {0.0, 0.8, 0.0} or {0.8, 0.0, 0.0} -- Green for positive, red for negative
            AddValue(tooltip, "Stamina from Buffs", math.floor(buffValue + 0.5) .. " (" .. PDS.Utils:FormatPercent(PDS.Stats:GetBuffPercentage(PDS.Stats.STAT_TYPES.STAMINA)) .. ")", buffColor)
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• Increases maximum health", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Defense
function StatTooltips:GetDefenseTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Defense")
    AddDescription(tooltip, "Increases your defense skill, reducing the chance to be hit by attacks.")

    -- Current values
    AddValue(tooltip, "Defense Bonus", PDS.Utils:FormatPercent(value), {0.50, 0.50, 0.80}) -- Steel Blue to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.50, 0.50, 0.80})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.DEFENSE, rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• Reduces chance to be hit", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Reduces chance to be critically hit", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Dodge
function StatTooltips:GetDodgeTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Dodge")
    AddDescription(tooltip, "Increases your chance to dodge attacks, avoiding all damage.")

    -- Current values
    AddValue(tooltip, "Dodge Chance", PDS.Utils:FormatPercent(value), {0.40, 0.70, 0.40}) -- Forest Green to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.40, 0.70, 0.40})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.DODGE, rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " chance to dodge attacks", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Dodged attacks deal no damage", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Parry
function StatTooltips:GetParryTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Parry")
    AddDescription(tooltip, "Increases your chance to parry attacks, avoiding all damage and enabling a quick counter-attack.")

    -- Current values
    AddValue(tooltip, "Parry Chance", PDS.Utils:FormatPercent(value), {0.70, 0.40, 0.40}) -- Rust Red to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.70, 0.40, 0.40})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.PARRY, rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " chance to parry attacks", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Parried attacks deal no damage", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Enables counter-attack opportunities", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Block
function StatTooltips:GetBlockTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Block")
    AddDescription(tooltip, "Increases your chance to block attacks with a shield, reducing damage taken.")

    -- Current values
    AddValue(tooltip, "Block Chance", PDS.Utils:FormatPercent(value), {0.60, 0.60, 0.30}) -- Olive to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.60, 0.60, 0.30})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.BLOCK, rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• " .. PDS.Utils:FormatPercent(value) .. " chance to block attacks", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Blocked attacks deal reduced damage", 0.8, 0.8, 0.8, true)
end

-- Generate tooltip content for Armor Penetration
function StatTooltips:GetArmorPenetrationTooltip(tooltip, value, rating)
    AddHeader(tooltip, "Armor Penetration")
    AddDescription(tooltip, "Allows your physical attacks to ignore a portion of the target's armor.")

    -- Current values
    AddValue(tooltip, "Armor Ignored", PDS.Utils:FormatPercent(value), {0.75, 0.60, 0.30}) -- Bronze to match bar color

    if rating and rating > 0 then
        AddValue(tooltip, "Current Rating", math.floor(rating + 0.5), {0.75, 0.60, 0.30})

        -- Rating needed for next percentage point
        local ratingForNext = PDS.Stats:GetRatingForNextPercent(PDS.Stats.STAT_TYPES.ARMOR_PENETRATION, rating, value)
        if ratingForNext > 0 then
            AddValue(tooltip, "Rating for +1%", ratingForNext, {0.7, 0.7, 0.7})
        end
    end

    -- Game impact examples
    tooltip:AddLine(" ")
    AddLine(tooltip, "Effects:", 0.9, 0.9, 0.9)
    AddLine(tooltip, "• Ignores " .. PDS.Utils:FormatPercent(value) .. " of target's armor", 0.8, 0.8, 0.8, true)
    AddLine(tooltip, "• Increases physical damage against armored targets", 0.8, 0.8, 0.8, true)
end

-- Main function to show tooltip for a specific stat type
function StatTooltips:ShowTooltip(tooltip, statType, value, rating)
    if not tooltip or not statType then return end

    -- Ensure value is not nil to prevent crashes
    value = value or 0

    -- Clear any existing tooltip content
    tooltip:ClearLines()

    -- Call the appropriate tooltip function based on stat type
    -- Primary stats
    if statType == PDS.Stats.STAT_TYPES.STRENGTH then
        self:GetStrengthTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.AGILITY then
        self:GetAgilityTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.INTELLECT then
        self:GetIntellectTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.STAMINA then
        self:GetStaminaTooltip(tooltip, value, rating)
    -- Secondary stats
    elseif statType == PDS.Stats.STAT_TYPES.HASTE then
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
    -- Combat ratings
    elseif statType == PDS.Stats.STAT_TYPES.DEFENSE then
        self:GetDefenseTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.DODGE then
        self:GetDodgeTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.PARRY then
        self:GetParryTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.BLOCK then
        self:GetBlockTooltip(tooltip, value, rating)
    elseif statType == PDS.Stats.STAT_TYPES.ARMOR_PENETRATION then
        self:GetArmorPenetrationTooltip(tooltip, value, rating)
    end

    -- Show the tooltip
    tooltip:Show()
end

return StatTooltips
