local _, PDS = ...
local Config = PDS.Config

local ConfigUI = {}
PDS.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
if not PeaversCommons then
    print("|cffff0000Error:|r PeaversCommons not found.")
    return
end

local SettingsObjects = PeaversCommons.SettingsObjects
local W = PeaversCommons.Widgets
local C = W.Colors
local ConfigUIUtils = PeaversCommons.ConfigUIUtils

local function RefreshBars()
    if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
        PDS.BarManager:CreateBars(PDS.Core.contentFrame)
        PDS.Core:AdjustFrameHeight()
    end
end

local function OnSettingChanged(key, value)
    if key == "frameWidth" then
        Config.barWidth = value - 20
        if PDS.Core and PDS.Core.frame then
            PDS.Core.frame:SetWidth(value)
            if PDS.BarManager then PDS.BarManager:ResizeBars() end
        end
    elseif key == "bgAlpha" or key == "bgColor" then
        if PDS.Core and PDS.Core.frame then
            local color = Config.bgColor or { r = 0, g = 0, b = 0 }
            PDS.Core.frame:SetBackdropColor(color.r, color.g, color.b, Config.bgAlpha or 0.8)
            PDS.Core.frame:SetBackdropBorderColor(0, 0, 0, Config.bgAlpha or 0.8)
            if PDS.Core.titleBar then
                PDS.Core.titleBar:SetBackdropColor(color.r, color.g, color.b, Config.bgAlpha or 0.8)
                PDS.Core.titleBar:SetBackdropBorderColor(0, 0, 0, Config.bgAlpha or 0.8)
            end
        end
    elseif key == "lockPosition" then
        if PDS.Core then PDS.Core:UpdateFrameLock() end
    elseif key == "showTitleBar" then
        if PDS.Core then PDS.Core:UpdateTitleBarVisibility() end
    elseif key == "barAlpha" or key == "barBgAlpha" or key == "barTexture" then
        if PDS.BarManager then PDS.BarManager:ResizeBars() end
    elseif key == "barHeight" or key == "barSpacing" then
        RefreshBars()
    elseif key == "fontFace" or key == "fontSize" or key == "fontOutline" or key == "fontShadow" then
        RefreshBars()
    elseif key == "displayMode" or key == "hideOutOfCombat" or key == "showOnLogin" then
        if PDS.Core and PDS.Core.UpdateFrameVisibility then
            PDS.Core:UpdateFrameVisibility()
        end
    end
end

local pageOpts = {
    indent = 25,
    width = 360,
    onChanged = OnSettingChanged,
}

local function GetPageOpts(parentFrame)
    local opts = {}
    for k, v in pairs(pageOpts) do opts[k] = v end
    local frameWidth = parentFrame:GetWidth()
    if frameWidth and frameWidth > 100 then
        opts.width = frameWidth - (opts.indent * 2) - 10
    end
    return opts
end

--------------------------------------------------------------------------------
-- Page Builders
--------------------------------------------------------------------------------

function ConfigUI:BuildGeneralPage(parentFrame)
    local y = -10
    local opts = GetPageOpts(parentFrame)

    y = SettingsObjects.FrameSettings(parentFrame, Config, y, opts)
    y = SettingsObjects.Visibility(parentFrame, Config, y, opts)

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildStatsPage(parentFrame)
    local y = -10
    local opts = GetPageOpts(parentFrame)
    local indent = opts.indent
    local width = opts.width

    local _, newY = W:CreateSectionHeader(parentFrame, "Stat Visibility & Colors", indent, y)
    y = newY - 8

    local statGroups = {
        { label = "Primary Stats", stats = { "PRIMARY_STAT", "STRENGTH", "AGILITY", "INTELLECT", "STAMINA" } },
        { label = "Secondary Stats", stats = { "CRIT", "HASTE", "MASTERY", "VERSATILITY", "VERSATILITY_DAMAGE_REDUCTION" } },
        { label = "Tertiary Stats", stats = { "DODGE", "PARRY", "BLOCK", "LEECH", "AVOIDANCE", "SPEED" } },
    }

    if not Config.showStats then Config.showStats = {} end
    if not Config.customColors then Config.customColors = {} end
    if not Config.customTextColors then Config.customTextColors = {} end

    for _, group in ipairs(statGroups) do
        local groupLabel = parentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        groupLabel:SetPoint("TOPLEFT", indent, y)
        groupLabel:SetText(group.label)
        y = y - 20

        for _, statType in ipairs(group.stats) do
            local statName = (PDS.Stats and PDS.Stats.GetName) and PDS.Stats:GetName(statType) or statType
            local toggle = W:CreateToggle(parentFrame, statName, {
                checked = Config.showStats[statType] ~= false,
                width = width,
                onChange = function(checked)
                    Config.showStats[statType] = checked
                    Config:Save()
                    RefreshBars()
                end,
            })
            toggle:SetPoint("TOPLEFT", indent + 10, y)
            y = y - 26

            -- Bar color picker
            local barR, barG, barB = 1, 1, 1
            if Config.customColors[statType] then
                barR = Config.customColors[statType].r or 1
                barG = Config.customColors[statType].g or 1
                barB = Config.customColors[statType].b or 1
            elseif PDS.Stats and PDS.Stats.GetColor then
                barR, barG, barB = PDS.Stats:GetColor(statType)
            end

            local barColor = W:CreateColorPicker(parentFrame, "Bar Color", {
                r = barR, g = barG, b = barB,
                width = width - 20,
                onChange = function(r, g, b)
                    Config.customColors[statType] = { r = r, g = g, b = b }
                    Config:Save()
                    if PDS.BarManager and PDS.BarManager.bars then
                        for _, bar in ipairs(PDS.BarManager.bars) do
                            if bar.statType == statType then bar:UpdateColor() end
                        end
                    end
                end,
            })
            barColor:SetPoint("TOPLEFT", indent + 20, y)
            y = y - 28

            -- Text color picker
            local textR, textG, textB = 1, 1, 1
            if Config.customTextColors[statType] then
                textR = Config.customTextColors[statType].r or 1
                textG = Config.customTextColors[statType].g or 1
                textB = Config.customTextColors[statType].b or 1
            end

            local textColor = W:CreateColorPicker(parentFrame, "Text Color", {
                r = textR, g = textG, b = textB,
                width = width - 20,
                onChange = function(r, g, b)
                    Config.customTextColors[statType] = { r = r, g = g, b = b }
                    Config:Save()
                    if PDS.BarManager and PDS.BarManager.bars then
                        for _, bar in ipairs(PDS.BarManager.bars) do
                            if bar.statType == statType and bar.textManager then
                                bar.textManager:SetTextColor(r, g, b)
                            end
                        end
                    end
                end,
            })
            textColor:SetPoint("TOPLEFT", indent + 20, y)
            y = y - 30
        end

        y = y - 10
    end

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildBarsPage(parentFrame)
    local y = -10
    local opts = GetPageOpts(parentFrame)
    local indent = opts.indent
    local width = opts.width

    y = SettingsObjects.BarAppearance(parentFrame, Config, y, opts)

    -- Text opacity (PDS-specific)
    local _, newY = W:CreateSectionHeader(parentFrame, "Text & Bar Options", indent, y)
    y = newY - 8

    local textAlphaSlider = W:CreateSlider(parentFrame, "Text Opacity", {
        min = 0, max = 1, step = 0.05,
        value = Config.textAlpha or 1.0,
        width = width,
        onChange = function(value)
            Config.textAlpha = value
            Config:Save()
            if PDS.BarManager and PDS.BarManager.bars then
                for _, bar in ipairs(PDS.BarManager.bars) do
                    if bar.textManager then
                        bar.textManager:SetTextAlpha(value)
                    end
                end
            end
        end,
    })
    textAlphaSlider:SetPoint("TOPLEFT", indent, y)
    y = y - 52

    -- Show overflow bars
    local overflowToggle = W:CreateToggle(parentFrame, "Show Overflow Bars (values over 100%)", {
        checked = Config.showOverflowBars ~= false,
        width = width,
        onChange = function(checked)
            Config.showOverflowBars = checked
            Config:Save()
            RefreshBars()
        end,
    })
    overflowToggle:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    -- Show stat changes
    local statChangesToggle = W:CreateToggle(parentFrame, "Show Stat Changes", {
        checked = Config.showStatChanges ~= false,
        width = width,
        onChange = function(checked)
            Config.showStatChanges = checked
            Config:Save()
            RefreshBars()
        end,
    })
    statChangesToggle:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    -- Persist stat changes
    local persistToggle = W:CreateToggle(parentFrame, "Persist Stat Changes Between Sessions", {
        checked = Config.persistStatChanges or false,
        width = width,
        onChange = function(checked)
            Config.persistStatChanges = checked
            Config:Save()
        end,
    })
    persistToggle:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    -- Show ratings
    local ratingsToggle = W:CreateToggle(parentFrame, "Show Rating Values", {
        checked = Config.showRatings ~= false,
        width = width,
        onChange = function(checked)
            Config.showRatings = checked
            Config:Save()
            RefreshBars()
        end,
    })
    ratingsToggle:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    -- Auto-hide zero stats
    local autoHideToggle = W:CreateToggle(parentFrame, "Auto-Hide Zero Value Stats", {
        checked = Config.autoHideZeroStats ~= false,
        width = width,
        onChange = function(checked)
            Config.autoHideZeroStats = checked
            Config:Save()
            if PDS.BarManager then
                if checked then
                    PDS.BarManager:UpdateAllBars()
                else
                    if PDS.BarManager.ShowAllZeroHiddenBars then
                        PDS.BarManager:ShowAllZeroHiddenBars()
                    end
                end
            end
        end,
    })
    autoHideToggle:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    -- Highest stat highlight
    local _, hlY = W:CreateSectionHeader(parentFrame, "Highest Stat Highlight", indent, y)
    y = hlY - 8

    local L = PDS.L or {}
    local highlightToggle = W:CreateToggle(parentFrame, "Highlight Highest Secondary Stat", {
        checked = Config.highlightHighestRating == true,
        width = width,
        onChange = function(checked)
            Config.highlightHighestRating = checked
            Config:Save()
            if PDS.BarManager and PDS.BarManager.UpdateHighestRatingHighlight then
                PDS.BarManager:UpdateHighestRatingHighlight()
            end
        end,
    })
    highlightToggle:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    local styleDropdown = W:CreateDropdown(parentFrame, L["CONFIG_HIGHLIGHT_STYLE"] or "Highlight Style", {
        options = {
            { value = "STATIC", label = L["CONFIG_HIGHLIGHT_STYLE_STATIC"] or "Static Border" },
            { value = "SUBTLE", label = L["CONFIG_HIGHLIGHT_STYLE_SUBTLE"] or "Marching Dots (Subtle)" },
            { value = "GLOW",   label = L["CONFIG_HIGHLIGHT_STYLE_GLOW"]   or "Marching Dots (Glow)" },
            { value = "BRIGHT", label = L["CONFIG_HIGHLIGHT_STYLE_BRIGHT"] or "Marching Dots (Bright)" },
        },
        selected = Config.highlightStyle or "SUBTLE",
        width = width,
        onChange = function(value)
            Config.highlightStyle = value
            Config:Save()
            if PDS.BarManager and PDS.BarManager.UpdateHighestRatingHighlight then
                PDS.BarManager:UpdateHighestRatingHighlight()
            end
        end,
    })
    styleDropdown:SetPoint("TOPLEFT", indent, y)
    y = y - 58

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildTextPage(parentFrame)
    local y = -10
    local opts = GetPageOpts(parentFrame)

    y = SettingsObjects.FontSettings(parentFrame, Config, y, opts)

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildBehaviorPage(parentFrame)
    local y = -10
    local opts = GetPageOpts(parentFrame)
    local indent = opts.indent
    local width = opts.width

    -- Talent adjustments
    local _, newY = W:CreateSectionHeader(parentFrame, "Advanced", indent, y)
    y = newY - 8

    local talentToggle = W:CreateToggle(parentFrame, "Enable Talent Stat Adjustments", {
        checked = Config.enableTalentAdjustments ~= false,
        width = width,
        onChange = function(checked)
            Config.enableTalentAdjustments = checked
            Config:Save()
            if PDS.BarManager then
                PDS.BarManager:UpdateAllBars()
            end
        end,
    })
    talentToggle:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    y = SettingsObjects.UpdateInterval(parentFrame, Config, y, opts)

    -- Troubleshooting
    local _, newY = W:CreateSectionHeader(parentFrame, "Troubleshooting", indent, y)
    y = newY - 8

    local desc = parentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", indent, y)
    desc:SetWidth(width)
    desc:SetJustifyH("LEFT")
    desc:SetText("Reset the frame position to center of screen if it becomes lost or hidden.")
    y = y - 30

    local resetBtn = W:CreateButton(parentFrame, "Reset Position", {
        width = 140,
        onClick = function()
            Config.framePoint = "CENTER"
            Config.frameX = 0
            Config.frameY = 0
            Config.displayMode = "ALWAYS"
            Config.hideOutOfCombat = false
            Config:Save()
            if PDS.Core then
                PDS.Core:ApplyFramePosition()
                if PDS.Core.frame then PDS.Core.frame:Show() end
                if PDS.Core.UpdateFrameVisibility then
                    PDS.Core:UpdateFrameVisibility()
                end
            end
        end,
    })
    resetBtn:SetPoint("TOPLEFT", indent, y)
    y = y - 40

    parentFrame:SetHeight(math.abs(y) + 30)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function ConfigUI:GetPages()
    return {
        { key = "general", label = "General", builder = function(f) ConfigUI:BuildGeneralPage(f) end },
        { key = "stats", label = "Stats", builder = function(f) ConfigUI:BuildStatsPage(f) end },
        { key = "bars", label = "Bars", builder = function(f) ConfigUI:BuildBarsPage(f) end },
        { key = "text", label = "Text", builder = function(f) ConfigUI:BuildTextPage(f) end },
        { key = "behavior", label = "Behavior", builder = function(f) ConfigUI:BuildBehaviorPage(f) end },
    }
end

function ConfigUI:BuildIntoFrame(parentFrame)
    local y = -10
    y = SettingsObjects.FrameSettings(parentFrame, Config, y, pageOpts)
    y = SettingsObjects.BarAppearance(parentFrame, Config, y, pageOpts)
    y = SettingsObjects.FontSettings(parentFrame, Config, y, pageOpts)
    y = SettingsObjects.Visibility(parentFrame, Config, y, pageOpts)
    parentFrame:SetHeight(math.abs(y) + 30)
    return parentFrame
end

function ConfigUI:InitializeOptions()
    local panel = ConfigUIUtils.CreateSettingsPanel(
        "Settings",
        "Configuration options for the stat display"
    )
    local content = panel.content
    self:BuildIntoFrame(content)
    panel:UpdateContentHeight(content:GetHeight())
    return panel
end

function ConfigUI:OpenOptions()
    PDS.Config:Save()

    if _G.PeaversConfig and _G.PeaversConfig.MainFrame then
        _G.PeaversConfig.MainFrame:Show()
        _G.PeaversConfig.MainFrame:SelectAddon("PeaversDynamicStats")
        return
    end

    if Settings and Settings.OpenToCategory then
        if PDS.directSettingsCategoryID then
            local success = pcall(Settings.OpenToCategory, PDS.directSettingsCategoryID)
            if success then return end
        end
        if PDS.directCategoryID then
            local success = pcall(Settings.OpenToCategory, PDS.directCategoryID)
            if success then return end
        end
    end

    if SettingsPanel then
        ShowUIPanel(SettingsPanel)
    end
end

PDS.Config.OpenOptionsCommand = function()
    ConfigUI:OpenOptions()
end

function ConfigUI:RefreshUI()
end

function ConfigUI:Initialize()
    self.panel = self:InitializeOptions()
end

return ConfigUI
