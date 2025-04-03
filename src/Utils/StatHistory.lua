local addonName, PDS = ...

-- Initialize StatHistory namespace
PDS.StatHistory = {}
local StatHistory = PDS.StatHistory

-- Configuration
local MAX_HISTORY_POINTS = 20  -- Store up to 20 data points per stat
local HISTORY_INTERVAL = 60    -- Record a data point every 60 seconds

-- Data structure to store historical stat values
StatHistory.data = {}
StatHistory.lastRecordTime = 0

-- Initialize the history data structure
function StatHistory:Initialize()
    -- Create empty history for each stat type
    for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
        self.data[statType] = {}
    end

    -- Initialize the last record time
    self.lastRecordTime = GetTime()

    -- Load saved history data if available
    self:Load()
end

-- Record current stat values if enough time has passed
function StatHistory:RecordStats()
    local currentTime = GetTime()

    -- Only record stats if history tracking is enabled and enough time has passed
    if PDS.Config.enableStatHistory and (currentTime - self.lastRecordTime) >= HISTORY_INTERVAL then
        for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
            -- Only record stats that are being displayed
            if PDS.Config.showStats[statType] then
                local value = PDS.Stats:GetValue(statType)
                local timestamp = time()  -- Current time in seconds since epoch

                -- Add new data point
                table.insert(self.data[statType], { value = value, timestamp = timestamp })

                -- Trim history if it exceeds the maximum number of points
                if #self.data[statType] > MAX_HISTORY_POINTS then
                    table.remove(self.data[statType], 1)  -- Remove oldest entry
                end
            end
        end

        -- Update the last record time
        self.lastRecordTime = currentTime

        -- Save the history data
        self:Save()
    end
end

-- Get the history data for a specific stat
function StatHistory:GetHistory(statType)
    return self.data[statType] or {}
end

-- Calculate the change over time for a specific stat
function StatHistory:GetChangeOverTime(statType, timeFrame)
    local history = self.data[statType]
    if not history or #history < 2 then
        return 0, 0  -- No change if we don't have enough data points
    end

    local currentValue = history[#history].value
    local oldestValue = history[1].value
    local totalChange = currentValue - oldestValue
    local percentChange = (oldestValue > 0) and (totalChange / oldestValue * 100) or 0

    return totalChange, percentChange
end

-- Get the min, max, and average values for a specific stat
function StatHistory:GetStatistics(statType)
    local history = self.data[statType]
    if not history or #history == 0 then
        return 0, 0, 0  -- No statistics if we don't have data
    end

    local min = history[1].value
    local max = history[1].value
    local sum = history[1].value

    for i = 2, #history do
        local value = history[i].value
        min = math.min(min, value)
        max = math.max(max, value)
        sum = sum + value
    end

    local avg = sum / #history

    return min, max, avg
end

-- Save history data to the SavedVariables database
function StatHistory:Save()
    if not PeaversDynamicStatsDB then
        PeaversDynamicStatsDB = {}
    end

    PeaversDynamicStatsDB.statHistory = self.data
end

-- Load history data from the SavedVariables database
function StatHistory:Load()
    if PeaversDynamicStatsDB and PeaversDynamicStatsDB.statHistory then
        self.data = PeaversDynamicStatsDB.statHistory
    end
end

-- Clear all history data
function StatHistory:Clear()
    for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
        self.data[statType] = {}
    end

    self:Save()
end

-- Add history information to a tooltip
function StatHistory:AddHistoryToTooltip(tooltip, statType)
    if not PDS.Config.enableStatHistory then return end

    local history = self.data[statType]
    if not history or #history < 2 then
        -- Not enough data to show history
        return
    end

    -- Add a separator
    tooltip:AddLine(" ")
    tooltip:AddLine("Stat History:", 1, 0.82, 0)  -- Gold color for header

    -- Calculate change over time
    local totalChange, percentChange = self:GetChangeOverTime(statType)
    local changeText = PDS.Utils:FormatChange(totalChange)
    local changeColor = {0.7, 0.7, 0.7}  -- Default gray

    if totalChange > 0 then
        changeColor = {0.0, 0.8, 0.0}  -- Green for positive change
    elseif totalChange < 0 then
        changeColor = {0.8, 0.0, 0.0}  -- Red for negative change
    end

    -- Add change information
    tooltip:AddDoubleLine("Change over time:", changeText, 0.9, 0.9, 0.9, changeColor[1], changeColor[2], changeColor[3])

    -- Calculate min, max, average
    local min, max, avg = self:GetStatistics(statType)
    tooltip:AddDoubleLine("Minimum:", PDS.Utils:FormatPercent(min), 0.9, 0.9, 0.9, 0.7, 0.7, 0.7)
    tooltip:AddDoubleLine("Maximum:", PDS.Utils:FormatPercent(max), 0.9, 0.9, 0.9, 0.7, 0.7, 0.7)
    tooltip:AddDoubleLine("Average:", PDS.Utils:FormatPercent(avg), 0.9, 0.9, 0.9, 0.7, 0.7, 0.7)

    -- Add time range information
    local oldestTime = history[1].timestamp
    local newestTime = history[#history].timestamp
    local timeRange = newestTime - oldestTime
    local timeText = PDS.Utils:FormatTime(timeRange)

    tooltip:AddDoubleLine("Time range:", timeText, 0.9, 0.9, 0.9, 0.7, 0.7, 0.7)
end

return StatHistory
