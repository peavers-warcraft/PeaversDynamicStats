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

    -- Pre-compute maxRating before creating bars so raw-mode scaling is correct on first draw
    if PDS.Config.showRawValues then
        local IsSecretValue = PDS.Stats.IsSecretValue
        local maxRating = 0
        for _, st in ipairs(PDS.Stats.STAT_ORDER) do
            if PDS.Config.showStats[st] and not PDS.Stats:IsPrimaryStat(st) then
                local rating = PDS.Stats:GetRating(st)
                if rating and not IsSecretValue(rating) and rating > maxRating then
                    maxRating = rating
                end
            end
        end
        self.maxRating = math.max(maxRating, 100)
        if self.maxRating > 100 then
            self.cachedMaxRating = self.maxRating
        end
    else
        self.maxRating = 0
    end

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

function BarManager:ComputeMaxRating()
    local IsSecretValue = PDS.Stats.IsSecretValue
    local maxRating = 0
    for _, bar in ipairs(self.bars) do
        if not PDS.Stats:IsPrimaryStat(bar.statType) and not bar.hiddenByZero then
            local rating = PDS.Stats:GetRating(bar.statType)
            if rating and not IsSecretValue(rating) and rating > maxRating then
                maxRating = rating
            end
        end
    end
    self.maxRating = math.max(maxRating, 100)
    if self.maxRating > 100 then
        self.cachedMaxRating = self.maxRating
    end
end

-- Updates all stat bars with latest values, only if they've changed.
-- StatBar reads self.maxRating directly for raw-mode bar fill scaling.
function BarManager:UpdateAllBars()
    local IsSecretValue = PDS.Stats.IsSecretValue
    local layoutDirty = false
    local rawMode = PDS.Config.showRawValues

    if rawMode then
        self:ComputeMaxRating()
    else
        self.maxRating = 0
    end

    for _, bar in ipairs(self.bars) do
        local value = PDS.Stats:GetValue(bar.statType)
        local statKey = bar.statType

        if IsSecretValue(value) then
            bar:Update(value)
            bar:UpdateColor()
        else
            if not self.previousValues[statKey] then
                self.previousValues[statKey] = 0
            end

            if value ~= self.previousValues[statKey] then
                local change = value - self.previousValues[statKey]
                bar:Update(value, nil, change)
                bar:UpdateColor()
                self.previousValues[statKey] = value
            elseif rawMode then
                bar:Update(value)
                bar:UpdateColor()
            end

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
        self.cachedHighestStatType = nil
        return
    end

    local IsSecretValue = PDS.Stats.IsSecretValue
    local highestRating = 0
    local highestStatType = nil
    local anySecret = false

    for _, bar in ipairs(self.bars) do
        if HIGHLIGHT_STATS[bar.statType] and not bar.hiddenByZero then
            local rating = PDS.Stats:GetRating(bar.statType)
            if IsSecretValue(rating) then
                anySecret = true
            elseif rating > highestRating then
                highestRating = rating
                highestStatType = bar.statType
            end
        end
    end

    -- 12.0.5+: in combat all ratings are secret and can't be compared, so the
    -- loop above produces no winner. Reuse the last known winner so the
    -- highlight (the whole point of this feature) persists through combat.
    if anySecret and highestStatType == nil then
        highestStatType = self.cachedHighestStatType
    else
        self.cachedHighestStatType = highestStatType
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
