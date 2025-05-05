local addonName, PDS = ...

-- Initialize Utils namespace
PDS.Utils = {}
local Utils = PDS.Utils

-- Print a message to the chat frame with addon prefix
function Utils.Print(message)
    if not message then return end
    print("|cff3abdf7Peavers|rDynamicStats: " .. message)
end

-- Debug print only when debug mode is enabled
function Utils.Debug(message)
    if not message or not PDS.Config or not PDS.Config.DEBUG_ENABLED then return end
    print("|cffff9900[DEBUG]|r " .. message)
end

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

-- Format a change value with a + or - sign and 2 decimal places
function Utils:FormatChange(value)
    if value > 0 then
        return string.format("+%.2f%%", value)
    elseif value < 0 then
        return string.format("%.2f%%", value)
    else
        return ""
    end
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

-- Format a time duration in seconds into a human-readable string
function Utils:FormatTime(seconds)
    if not seconds or seconds <= 0 then
        return "0 seconds"
    end

    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400

    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600

    local minutes = math.floor(seconds / 60)
    seconds = math.floor(seconds % 60)

    local parts = {}

    if days > 0 then
        table.insert(parts, days .. (days == 1 and " day" or " days"))
    end

    if hours > 0 then
        table.insert(parts, hours .. (hours == 1 and " hour" or " hours"))
    end

    if minutes > 0 then
        table.insert(parts, minutes .. (minutes == 1 and " minute" or " minutes"))
    end

    if seconds > 0 and #parts < 2 then
        table.insert(parts, seconds .. (seconds == 1 and " second" or " seconds"))
    end

    -- Return at most 2 time units for readability
    if #parts > 2 then
        return table.concat({parts[1], parts[2]}, ", ")
    else
        return table.concat(parts, ", ")
    end
end
