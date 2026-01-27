local addonName, PDS = ...

-- Initialize BarManager namespace
PDS.BarManager = {}
local BarManager = PDS.BarManager

-- Collection to store all created bars
BarManager.bars = {}

-- Creates or recreates all stat bars based on current configuration
function BarManager:CreateBars(parent)
    -- Clear existing bars
    for _, bar in ipairs(self.bars) do
        bar.frame:Hide()
    end
    self.bars = {}

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
            -- yMult is -1 for growing down, 1 for growing up
            -- barSpacing can be negative to make bars overlap (compensating for borders)
            local barStep = PDS.Config.barHeight + PDS.Config.barSpacing
            yOffset = yOffset + (barStep * yMult)
        end
    end

    return math.abs(yOffset)
end

-- Updates all stat bars with latest values, only if they've changed
function BarManager:UpdateAllBars()
    if not self.previousValues then
        self.previousValues = {}
    end

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
    -- barSpacing can be negative to make bars overlap (compensating for borders)
    local totalHeight = #self.bars * PDS.Config.barHeight + (#self.bars - 1) * PDS.Config.barSpacing

    return totalHeight
end

-- Adjusts the frame height based on number of bars and title bar visibility
function BarManager:AdjustFrameHeight(frame, contentFrame, titleBarVisible)
    local barCount = #self.bars
    local contentHeight

    -- Calculate content height based on bars and spacing
    -- barSpacing can be negative to make bars overlap (compensating for borders)
    if barCount > 0 then
        contentHeight = barCount * PDS.Config.barHeight + (barCount - 1) * PDS.Config.barSpacing
    else
        contentHeight = 0
    end

    if contentHeight == 0 then
        if titleBarVisible then
            frame:SetHeight(20) -- Just title bar
        else
            frame:SetHeight(10) -- Minimal height
        end
    else
        if titleBarVisible then
            frame:SetHeight(contentHeight + 20) -- Add title bar height
        else
            frame:SetHeight(contentHeight) -- Just content
        end
    end

    -- Content frame position is managed by Core:UpdateTitleBarVisibility
    -- to avoid duplicate repositioning that could cause UI glitches
end

-- Gets a bar by its stat type
function BarManager:GetBar(statType)
    for _, bar in ipairs(self.bars) do
        if bar.statType == statType then
            return bar
        end
    end
    return nil
end

-- Gets the number of visible bars
function BarManager:GetBarCount()
    return #self.bars
end

return BarManager
