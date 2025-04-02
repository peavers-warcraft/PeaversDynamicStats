local addonName, PDS = ...

-- Initialize Utils namespace
PDS.Utils = {}
local Utils = PDS.Utils

-- Safely access global variables by name
function Utils:GetGlobal(name)
    if name and type(name) == "string" then
        return _G[name]
    end
    return nil
end

-- Format a number as a percentage with 2 decimal places
function Utils:FormatPercent(value)
    return string.format("%.2f%%", value or 0)
end

-- Round a number to the nearest decimal place
function Utils:Round(value, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

-- Check if a table contains a value
function Utils:TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end
