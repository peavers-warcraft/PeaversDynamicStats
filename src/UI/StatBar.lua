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

-- Returns the configured text color for a stat, or white if unset
function StatBar:GetTextColorForStat(statType)
    if PDS.Config.customTextColors and PDS.Config.customTextColors[statType] then
        local color = PDS.Config.customTextColors[statType]
        if color and color.r and color.g and color.b then
            return color.r, color.g, color.b
        end
    end
    return 1, 1, 1
end

-- Override UpdateColor to also update overflow bar and text color
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

    if self.textManager and self.textManager.SetTextColor then
        local tr, tg, tb = self:GetTextColorForStat(self.statType)
        self.textManager:SetTextColor(tr, tg, tb)
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
    local IsSecretValue = PDS.Stats.IsSecretValue
    local rawMode = PDS.Config.showRawValues and not PDS.Stats:IsPrimaryStat(self.statType)

    -- 12.0.5+: Secret values can't be compared, tested, or used in arithmetic.
    if IsSecretValue(value) then
        self.value = nil
        self:HandleOverflow(0)

        if rawMode then
            local rating = PDS.Stats:GetRating(self.statType) or 0
            local maxRating = PDS.BarManager.cachedMaxRating or PDS.BarManager.maxRating
            if not maxRating or maxRating < 1 then maxRating = 100 end
            self.statusBar:SetMinMaxValues(0, maxRating)
            self.statusBar:SetValue(rating, noAnimation)
            self.textManager:SetValue(string.format("%.0f", rating))
        else
            self.statusBar:SetMinMaxValues(0, 100)
            self.statusBar:SetValue(value, noAnimation)
            self.textManager:SetValue(self:GetDisplayValue(value))
        end
        return
    end

    -- Skip update when nothing changed (raw mode always re-evaluates since maxRating may shift)
    if self.value == value and not rawMode then return end

    self.value = value or 0

    if rawMode then
        local rating = PDS.Stats:GetRating(self.statType) or 0
        local maxRating = PDS.BarManager.maxRating
        if not maxRating or maxRating < 1 then maxRating = 100 end
        self:HandleOverflow(0)
        self.statusBar:SetMinMaxValues(0, maxRating)
        if not IsSecretValue(rating) then
            self.statusBar:SetValue(rating, noAnimation)
            self.textManager:SetValue(tostring(math.floor(rating + 0.5)))
        else
            self.statusBar:SetValue(rating, noAnimation)
            self.textManager:SetValue(string.format("%.0f", rating))
        end
    else
        local percentValue, overflowValue = self:CalculateBarValues(self.value, maxValue)

        if PDS.Stats:IsPrimaryStat(self.statType) then
            percentValue = 100
            overflowValue = 0
        end

        local visibilityChanged = self:HandleOverflow(overflowValue)
        if visibilityChanged then
            self.tooltipInitialized = false
            self:InitTooltip()
        end

        self.statusBar:SetMinMaxValues(0, 100)
        self.statusBar:SetValue(percentValue, noAnimation)
        self.textManager:SetValue(self:GetDisplayValue(self.value))
    end

    if PDS.Config.showStatChanges and change and change ~= 0 then
        self.textManager:ShowChange(change, function(c)
            return self:GetChangeDisplayValue(c)
        end, PDS.Config.persistStatChanges)
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
    elseif PDS.Stats:IsPrimaryStat(self.statType) then
        self.tooltip:SetText(PDS.Stats:GetName(self.statType))
        if not PDS.Stats.IsSecretValue(value) then
            self.tooltip:AddLine(tostring(math.floor(value + 0.5)), 1, 1, 1)
            local buffValue = PDS.Stats:GetBuffValue(self.statType)
            if buffValue ~= 0 then
                local color = buffValue > 0 and {0, 1, 0} or {1, 0, 0}
                local prefix = buffValue > 0 and "+" or ""
                self.tooltip:AddLine(prefix .. math.floor(buffValue + 0.5) .. " from buffs", color[1], color[2], color[3])
            end
        end
        self.tooltip:Show()
    else
        self.tooltip:SetText(PDS.Stats:GetName(self.statType))
        self.tooltip:AddLine(PDS.Utils.FormatPercent(value), 1, 1, 1)
        self.tooltip:Show()
    end
end

--------------------------------------------------------------------------------
-- Highest Rating Highlight
--------------------------------------------------------------------------------

-- dotSpacing = pixels between dot centers; lower = denser dashes
local HIGHLIGHT_CONFIGS = {
    STATIC = { dotSpacing = 0, dotSize = 0, speed = 0,  alpha = 0,   border = true },
    SUBTLE = { dotSpacing = 8, dotSize = 2, speed = 25, alpha = 0.7, border = false },
    GLOW   = { dotSpacing = 6, dotSize = 2, speed = 35, alpha = 0.9, border = false },
    BRIGHT = { dotSpacing = 4, dotSize = 2, speed = 45, alpha = 1.0, border = true },
}

local function GetPerimeterPos(pos, w, h)
    if pos < w then
        return pos, 0
    elseif pos < w + h then
        return w, pos - w
    elseif pos < w + h + w then
        return w - (pos - w - h), h
    else
        return 0, h - (pos - w - w - h)
    end
end

function StatBar:ClearHighlight()
    if self.highlightFrame then
        self.highlightFrame:SetScript("OnUpdate", nil)
        self.highlightFrame:Hide()
    end
    if self.highlightBorder then
        self.highlightBorder:Hide()
    end
    if self.highlightIcon then
        self.highlightIcon:Hide()
    end
end

function StatBar:ShowHighlightBorder()
    local r, g, b = 1, 0.84, 0
    if not self.highlightBorder then
        self.highlightBorder = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
        self.highlightBorder:SetAllPoints()
        self.highlightBorder:SetFrameLevel(self.frame:GetFrameLevel() + 9)
        self.highlightBorder:SetBackdrop({
            edgeFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeSize = 1,
        })
    end
    self.highlightBorder:SetBackdropBorderColor(r, g, b, 0.8)
    self.highlightBorder:Show()
end

function StatBar:ShowHighlightDots(cfg)
    local r, g, b = 1, 0.84, 0

    if not self.highlightFrame then
        self.highlightFrame = CreateFrame("Frame", nil, self.frame)
        self.highlightFrame:SetAllPoints()
        self.highlightFrame:SetFrameLevel(self.frame:GetFrameLevel() + 10)
        self.highlightFrame.dots = {}
    end

    local dots = self.highlightFrame.dots
    local w = self.frame:GetWidth()
    local h = self.frame:GetHeight()
    local perimeter = 2 * (w + h)
    local numDots = math.floor(perimeter / cfg.dotSpacing)

    for i = 1, math.max(#dots, numDots) do
        if i <= numDots then
            if not dots[i] then
                dots[i] = self.highlightFrame:CreateTexture(nil, "OVERLAY")
            end
            dots[i]:SetSize(cfg.dotSize, cfg.dotSize)
            dots[i]:SetColorTexture(r, g, b, cfg.alpha)
            dots[i]:Show()
        elseif dots[i] then
            dots[i]:Hide()
        end
    end

    local elapsed = 0
    self.highlightFrame:SetScript("OnUpdate", function(frame, dt)
        elapsed = elapsed + dt
        local fw = frame:GetWidth()
        local fh = frame:GetHeight()
        local perim = 2 * (fw + fh)
        local spacing = perim / numDots
        local shift = elapsed * cfg.speed

        for i = 1, numDots do
            local pos = ((i - 1) * spacing + shift) % perim
            local x, y = GetPerimeterPos(pos, fw, fh)
            dots[i]:ClearAllPoints()
            dots[i]:SetPoint("CENTER", frame, "TOPLEFT", x, -y)
        end
    end)

    self.highlightFrame:Show()
end

function StatBar:ShowHighlightIcon()
    if not PDS.Config.highlightShowIcon then return end

    if not self.highlightIcon then
        self.highlightIcon = self.frame:CreateTexture(nil, "OVERLAY")
        self.highlightIcon:SetSize(14, 14)
        self.highlightIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        self.highlightIcon:SetPoint("RIGHT", self.frame, "LEFT", -2, 0)
    end
    self.highlightIcon:Show()
end

function StatBar:SetHighestRating(isHighest)
    self:ClearHighlight()

    if not isHighest then return end

    local cfg = HIGHLIGHT_CONFIGS[PDS.Config.highlightStyle] or HIGHLIGHT_CONFIGS.SUBTLE

    if cfg.border then
        self:ShowHighlightBorder()
    end

    if cfg.dotSpacing > 0 then
        self:ShowHighlightDots(cfg)
    end

    self:ShowHighlightIcon()
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
    self:ClearHighlight()
    self.highlightFrame = nil
    self.highlightBorder = nil

    if self.overflowBar then
        self.overflowBar:Destroy()
    end

    BaseStatBar.Destroy(self)
end

return StatBar
