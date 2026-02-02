local addonName, PDS = ...

--------------------------------------------------------------------------------
-- PDS StatBar - Extends PeaversCommons.StatBar with overflow bars and tooltips
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons
local BaseStatBar = PeaversCommons.StatBar
local AnimatedStatusBar = PeaversCommons.AnimatedStatusBar

-- Initialize StatBar namespace
PDS.StatBar = {}
local StatBar = PDS.StatBar

-- Inherit from base StatBar
setmetatable(StatBar, { __index = BaseStatBar })

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

function StatBar:New(parent, name, statType)
    -- Create base instance with PDS config
    local obj = BaseStatBar.New(self, parent, name, statType, PDS.Config)

    -- Override metatable to use PDS.StatBar methods
    setmetatable(obj, { __index = StatBar })

    -- Create overflow bar for values > 100%
    obj:CreateOverflowBar()

    -- Initialize PDS-specific tooltip
    obj:InitTooltip()

    return obj
end

--------------------------------------------------------------------------------
-- Overflow Bar (PDS-specific feature)
--------------------------------------------------------------------------------

function StatBar:CreateOverflowBar()
    -- Create overflow bar on top of the main bar
    local mainBar = self.statusBar:GetStatusBar()

    self.overflowBar = AnimatedStatusBar:New(self.frame, {
        texture = PDS.Config.barTexture,
        bgAlpha = 0,  -- No background for overflow
        barAlpha = (PDS.Config.barAlpha or 1.0) * 0.7,
        showBackground = false,
    })
    self.overflowBar:SetAllPoints(mainBar)
    self.overflowBar:GetFrame():SetFrameLevel(mainBar:GetFrameLevel() + 1)
    self.overflowBar:Hide()

    -- Set overflow color (contrasting)
    local r, g, b = self:GetColorForStat(self.statType)
    local or_r, or_g, or_b = self:GetOverflowColor(r, g, b)
    self.overflowBar:SetColor(or_r, or_g, or_b, (PDS.Config.barAlpha or 1.0) * 0.7)
end

-- Returns a contrasting color for overflow
function StatBar:GetOverflowColor(r, g, b)
    local brightness = 0.299 * r + 0.587 * g + 0.114 * b

    if brightness > 0.5 then
        return r * 0.6, g * 0.6, b * 0.6
    else
        return math.min(r * 1.4, 1), math.min(g * 1.4, 1), math.min(b * 1.4, 1)
    end
end

-- Handle overflow bar visibility
function StatBar:HandleOverflow(overflowValue)
    if not self.overflowBar then return false end

    local showOverflow = PDS.Config.showOverflowBars
    local shouldShow = overflowValue and overflowValue > 0 and showOverflow
    local wasVisible = self.overflowBar:IsShown()

    if shouldShow then
        self.overflowBar:Show()
        self.overflowBar:SetValue(overflowValue)
    else
        self.overflowBar:Hide()
        self.overflowBar:SetValue(0, true)
    end

    -- Return true if visibility changed (for tooltip reinit)
    return wasVisible ~= shouldShow
end

--------------------------------------------------------------------------------
-- Color Management (PDS-specific)
--------------------------------------------------------------------------------

function StatBar:GetColorForStat(statType)
    -- Check if there's a custom color for this stat
    if PDS.Config.customColors and PDS.Config.customColors[statType] then
        local color = PDS.Config.customColors[statType]
        if color and color.r and color.g and color.b then
            return color.r, color.g, color.b
        end
    end

    -- Fall back to default colors from STAT_COLORS
    if PDS.Stats and PDS.Stats.STAT_COLORS and PDS.Stats.STAT_COLORS[statType] then
        return unpack(PDS.Stats.STAT_COLORS[statType])
    end

    return 0.8, 0.8, 0.8
end

-- Override UpdateColor to also update overflow bar
function StatBar:UpdateColor()
    local r, g, b = self:GetColorForStat(self.statType)
    r = r or 0.8
    g = g or 0.8
    b = b or 0.8

    self.statusBar:SetColor(r, g, b, PDS.Config.barAlpha or 1.0)

    if self.overflowBar then
        local or_r, or_g, or_b = self:GetOverflowColor(r, g, b)
        self.overflowBar:SetColor(or_r, or_g, or_b, (PDS.Config.barAlpha or 1.0) * 0.7)
    end
end

--------------------------------------------------------------------------------
-- Value Calculations (PDS-specific)
--------------------------------------------------------------------------------

function StatBar:CalculateBarValues(value, maxValue)
    if PDS.Stats and PDS.Stats.CalculateBarValues then
        return PDS.Stats:CalculateBarValues(value)
    end

    -- Fallback: simple percentage with overflow
    if maxValue <= 0 then return 0, 0 end

    local percent = (value / maxValue) * 100
    if percent <= 100 then
        return percent, 0
    else
        return 100, math.min(percent - 100, 100)
    end
end

function StatBar:GetDisplayValue(value)
    if PDS.Stats and PDS.Stats.GetDisplayValue then
        return PDS.Stats:GetDisplayValue(self.statType, value)
    end
    return tostring(math.floor(value + 0.5))
end

function StatBar:GetChangeDisplayValue(change)
    if PDS.Stats and PDS.Stats.GetChangeDisplayValue then
        return PDS.Stats:GetChangeDisplayValue(change)
    end
    return BaseStatBar.GetChangeDisplayValue(self, change)
end

--------------------------------------------------------------------------------
-- Update Override (PDS-specific with overflow handling)
--------------------------------------------------------------------------------

function StatBar:Update(value, maxValue, change, noAnimation)
    if self.value == value then return end

    self.value = value or 0

    -- Get bar values including overflow
    local percentValue, overflowValue = self:CalculateBarValues(self.value, maxValue)

    -- Handle overflow bar visibility
    local visibilityChanged = self:HandleOverflow(overflowValue)
    if visibilityChanged then
        self.tooltipInitialized = false
        self:InitTooltip()
    end

    -- Update main bar
    self.statusBar:SetMinMaxValues(0, 100)
    self.statusBar:SetValue(percentValue, noAnimation)

    -- Update value text
    local displayValue = self:GetDisplayValue(self.value)
    self.textManager:SetValue(displayValue)

    -- Show change indicator if enabled
    if PDS.Config.showStatChanges and change and change ~= 0 then
        self.textManager:ShowChange(change, function(c)
            return self:GetChangeDisplayValue(c)
        end)
    end
end

--------------------------------------------------------------------------------
-- Tooltip System (PDS-specific)
--------------------------------------------------------------------------------

function StatBar:InitTooltip()
    -- Always destroy existing tooltip to prevent memory leaks
    if self.tooltip then
        self.tooltip:Hide()
        self.tooltip:ClearLines()
        self.tooltip = nil
    end

    -- Create a new tooltip
    local tooltipName = "PDS_StatTooltip_" .. self.statType .. "_" .. tostring(self):gsub("table:", "")
    self.tooltip = CreateFrame("GameTooltip", tooltipName, UIParent, "GameTooltipTemplate")

    -- Set up mouse event handlers for main frame
    self.frame:SetScript("OnEnter", function()
        self:ShowTooltip()
    end)

    self.frame:SetScript("OnLeave", function()
        self:HideTooltip()
    end)

    -- Drag support through bar
    self.frame:SetScript("OnMouseDown", function(frame, button)
        if button == "LeftButton" and not PDS.Config.lockPosition then
            local parentFrame = PDS.Core.frame
            if parentFrame then
                parentFrame:StartMoving()
            end
        end
    end)

    self.frame:SetScript("OnMouseUp", function(frame, button)
        if button == "LeftButton" and not PDS.Config.lockPosition then
            local parentFrame = PDS.Core.frame
            if parentFrame then
                parentFrame:StopMovingOrSizing()
                local point, _, _, x, y = parentFrame:GetPoint()
                PDS.Config.framePoint = point
                PDS.Config.frameX = x
                PDS.Config.frameY = y
                PDS.Config:Save()
            end
        end
    end)

    -- Set up handlers for overflow bar too
    if self.overflowBar then
        local overflowFrame = self.overflowBar:GetFrame()
        overflowFrame:SetScript("OnEnter", function()
            self:ShowTooltip()
        end)
        overflowFrame:SetScript("OnLeave", function()
            self:HideTooltip()
        end)
        overflowFrame:SetScript("OnMouseDown", function(frame, button)
            if button == "LeftButton" and not PDS.Config.lockPosition then
                local parentFrame = PDS.Core.frame
                if parentFrame then
                    parentFrame:StartMoving()
                end
            end
        end)
        overflowFrame:SetScript("OnMouseUp", function(frame, button)
            if button == "LeftButton" and not PDS.Config.lockPosition then
                local parentFrame = PDS.Core.frame
                if parentFrame then
                    parentFrame:StopMovingOrSizing()
                    local point, _, _, x, y = parentFrame:GetPoint()
                    PDS.Config.framePoint = point
                    PDS.Config.frameX = x
                    PDS.Config.frameY = y
                    PDS.Config:Save()
                end
            end
        end)
    end

    self.tooltipInitialized = true
end

function StatBar:ShowTooltip()
    if not PDS.Config.showTooltips then return end

    if not self.tooltipInitialized or not self.tooltip then
        self:InitTooltip()
    end

    self.tooltip:ClearLines()
    self.tooltip:SetOwner(self.frame, "ANCHOR_RIGHT")

    local value = PDS.Stats:GetValue(self.statType)
    local rating = PDS.Stats:GetRating(self.statType)

    if PDS.StatTooltips then
        PDS.StatTooltips:ShowTooltip(self.tooltip, self.statType, value, rating)
    else
        self.tooltip:SetText(PDS.Stats:GetName(self.statType))
        self.tooltip:AddLine(PDS.Utils.FormatPercent(value))
        self.tooltip:Show()
    end
end

--------------------------------------------------------------------------------
-- Appearance Updates (override to handle overflow bar)
--------------------------------------------------------------------------------

function StatBar:UpdateTexture()
    BaseStatBar.UpdateTexture(self)

    if self.overflowBar then
        self.overflowBar:SetTexture(PDS.Config.barTexture)
        self:UpdateColor()
    end

    self.tooltipInitialized = false
    self:InitTooltip()
end

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------

function StatBar:Destroy()
    if self.overflowBar then
        self.overflowBar:Destroy()
    end

    BaseStatBar.Destroy(self)
end

return StatBar
