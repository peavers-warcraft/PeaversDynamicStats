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

-- Should this bar be hidden because its value is 0 and auto-hide is enabled?
-- Returns false for secret values so we never compare them against 0.
local function ShouldHideForZero(value)
    if not PDS.Config.autoHideZeroStats then return false end
    if PDS.Stats.IsSecretValue(value) then return false end
    return value == 0
end

-- Creates or recreates all stat bars based on current configuration
function BarManager:CreateBars(parent)
    -- Clear existing bars using base method
    self:Clear()

    -- Get growth direction from config
    local yMult, xMult, anchorPoint = PDS.Config:GetGrowthDirection()
    local barStep = PDS.Config.barHeight + PDS.Config.barSpacing

    local yOffset = 0
    for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
        if PDS.Config.showStats[statType] then
            local statName = PDS.Stats:GetName(statType)
            local bar = PDS.StatBar:New(parent, statName, statType)

            local value = PDS.Stats:GetValue(statType)
            bar:Update(value)
            bar:UpdateColor()

            bar.hiddenByZero = ShouldHideForZero(value)
            if bar.hiddenByZero then
                bar.frame:Hide()
            else
                bar:SetPosition(0, yOffset, anchorPoint)
                yOffset = yOffset + (barStep * yMult)
            end

            table.insert(self.bars, bar)
        end
    end

    self:UpdateHighestRatingHighlight()

    return math.abs(yOffset)
end

-- Re-positions visible bars to remove gaps left by hidden ones.
-- Call after toggling bar.hiddenByZero on any bar.
function BarManager:RelayoutVisibleBars()
    local yMult, xMult, anchorPoint = PDS.Config:GetGrowthDirection()
    local barStep = PDS.Config.barHeight + PDS.Config.barSpacing

    local yOffset = 0
    for _, bar in ipairs(self.bars) do
        if bar.hiddenByZero then
            bar.frame:Hide()
        else
            bar.frame:Show()
            bar:SetPosition(0, yOffset, anchorPoint)
            yOffset = yOffset + (barStep * yMult)
        end
    end
end

-- Override total-height calculation so hidden bars don't reserve space
function BarManager:CalculateTotalHeight(config)
    config = config or PDS.Config
    local barCount = 0
    for _, bar in ipairs(self.bars) do
        if not bar.hiddenByZero then
            barCount = barCount + 1
        end
    end
    if barCount == 0 then return 0 end

    local barHeight = config.barHeight or 20
    local barSpacing = config.barSpacing or 0
    return barCount * barHeight + (barCount - 1) * barSpacing
end

--------------------------------------------------------------------------------
-- Bar Updates (PDS-specific with change tracking)
--------------------------------------------------------------------------------

-- Updates all stat bars with latest values, only if they've changed
-- 12.0.5+: Secret values can't be compared or subtracted, so skip change tracking
function BarManager:UpdateAllBars()
    local IsSecretValue = PDS.Stats.IsSecretValue
    local layoutDirty = false

    for _, bar in ipairs(self.bars) do
        local value = PDS.Stats:GetValue(bar.statType)
        local statKey = bar.statType

        if IsSecretValue(value) then
            -- Secret value: can't compare or do math, always update, no change tracking
            bar:Update(value)
            bar:UpdateColor()
        else
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

            -- Re-evaluate auto-hide visibility against the latest value
            local shouldHide = ShouldHideForZero(value)
            if shouldHide ~= (bar.hiddenByZero == true) then
                bar.hiddenByZero = shouldHide
                layoutDirty = true
            end
        end
    end

    if layoutDirty then
        self:RelayoutVisibleBars()
        if PDS.Core and PDS.Core.AdjustFrameHeight then
            PDS.Core:AdjustFrameHeight()
        end
    end

    self:UpdateHighestRatingHighlight()
end

-- Clears all hiddenByZero flags and relays out (called when user disables autoHideZeroStats)
function BarManager:ShowAllZeroHiddenBars()
    for _, bar in ipairs(self.bars) do
        bar.hiddenByZero = false
    end
    self:RelayoutVisibleBars()
    if PDS.Core and PDS.Core.AdjustFrameHeight then
        PDS.Core:AdjustFrameHeight()
    end
end

--------------------------------------------------------------------------------
-- Highest Rating Highlight
--------------------------------------------------------------------------------

local HIGHLIGHT_STATS = {
    [PDS.Stats.STAT_TYPES.CRIT] = true,
    [PDS.Stats.STAT_TYPES.HASTE] = true,
    [PDS.Stats.STAT_TYPES.MASTERY] = true,
    [PDS.Stats.STAT_TYPES.VERSATILITY] = true,
}

function BarManager:UpdateHighestRatingHighlight()
    if not PDS.Config.highlightHighestRating then
        for _, bar in ipairs(self.bars) do
            if bar.SetHighestRating then
                bar:SetHighestRating(false)
            end
        end
        return
    end

    local IsSecretValue = PDS.Stats.IsSecretValue
    local highestRating = 0
    local highestStatType = nil

    for _, bar in ipairs(self.bars) do
        if HIGHLIGHT_STATS[bar.statType] and not bar.hiddenByZero then
            local rating = PDS.Stats:GetRating(bar.statType)
            if not IsSecretValue(rating) and rating > highestRating then
                highestRating = rating
                highestStatType = bar.statType
            end
        end
    end

    for _, bar in ipairs(self.bars) do
        if bar.SetHighestRating then
            bar:SetHighestRating(bar.statType == highestStatType)
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
