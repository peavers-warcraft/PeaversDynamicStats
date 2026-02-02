local addonName, PDS = ...

--------------------------------------------------------------------------------
-- PDS BarManager - Manages stat bars for dynamic stats display
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons
local BaseBarManager = PeaversCommons.BarManager

-- Initialize BarManager namespace
PDS.BarManager = {}
local BarManager = PDS.BarManager

-- Inherit from base BarManager
setmetatable(BarManager, { __index = BaseBarManager })

-- Collection to store all created bars
BarManager.bars = {}
BarManager.previousValues = {}

--------------------------------------------------------------------------------
-- Bar Creation (PDS-specific)
--------------------------------------------------------------------------------

-- Creates or recreates all stat bars based on current configuration
function BarManager:CreateBars(parent)
    -- Clear existing bars using base method
    self:Clear()

    -- Get growth direction from config
    local yMult, xMult, anchorPoint = PDS.Config:GetGrowthDirection()

    local yOffset = 0
    for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
        if PDS.Config.showStats[statType] then
            local statName = PDS.Stats:GetName(statType)
            local bar = PDS.StatBar:New(parent, statName, statType)
            bar:SetPosition(0, yOffset, anchorPoint)

            local value = PDS.Stats:GetValue(statType)
            bar:Update(value)

            -- Ensure the color is properly applied
            bar:UpdateColor()

            table.insert(self.bars, bar)

            -- Calculate offset based on growth direction
            local barStep = PDS.Config.barHeight + PDS.Config.barSpacing
            yOffset = yOffset + (barStep * yMult)
        end
    end

    return math.abs(yOffset)
end

--------------------------------------------------------------------------------
-- Bar Updates (PDS-specific with change tracking)
--------------------------------------------------------------------------------

-- Updates all stat bars with latest values, only if they've changed
function BarManager:UpdateAllBars()
    for _, bar in ipairs(self.bars) do
        local value = PDS.Stats:GetValue(bar.statType)
        local statKey = bar.statType

        if not self.previousValues[statKey] then
            self.previousValues[statKey] = 0
        end

        if value ~= self.previousValues[statKey] then
            -- Calculate the change in value
            local change = value - self.previousValues[statKey]

            -- Update the bar with the new value and change
            bar:Update(value, nil, change)

            -- Ensure the color is properly applied when updating
            bar:UpdateColor()

            -- Store the new value for next comparison
            self.previousValues[statKey] = value
        end
    end
end

--------------------------------------------------------------------------------
-- Bar Resizing
--------------------------------------------------------------------------------

-- Resizes all bars based on current configuration
function BarManager:ResizeBars()
    for _, bar in ipairs(self.bars) do
        bar:UpdateHeight()
        bar:UpdateWidth()
        bar:UpdateTexture()
        bar:UpdateFont()
        bar:UpdateBackgroundOpacity()
    end

    -- Return the total height of all bars for frame adjustment
    return self:CalculateTotalHeight(PDS.Config)
end

--------------------------------------------------------------------------------
-- Frame Height Adjustment
--------------------------------------------------------------------------------

-- Adjusts the frame height based on number of bars and title bar visibility
function BarManager:AdjustFrameHeight(frame, contentFrame, titleBarVisible)
    BaseBarManager.AdjustFrameHeight(self, frame, contentFrame, titleBarVisible, PDS.Config, 0)
end

--------------------------------------------------------------------------------
-- Bar Lookups
--------------------------------------------------------------------------------

-- Gets a bar by its stat type
function BarManager:GetBar(statType)
    for _, bar in ipairs(self.bars) do
        if bar.statType == statType then
            return bar
        end
    end
    return nil
end

return BarManager
