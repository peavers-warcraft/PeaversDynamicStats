local _, PDS = ...
local Config = PDS.Config
local UI = PDS.UI

-- Initialize ConfigUI.lua namespace
local ConfigUI = {}
PDS.ConfigUI = ConfigUI

-- Storage for UI elements that need refreshing when profile changes
ConfigUI.uiElements = {}

-- Access PeaversCommons utilities
local PeaversCommons = _G.PeaversCommons
-- Ensure PeaversCommons is loaded
if not PeaversCommons then
    print("|cffff0000Error:|r PeaversCommons not found. Please ensure it is installed and enabled.")
    return
end

-- Access required utilities
local ConfigUIUtils = PeaversCommons.ConfigUIUtils

-- Verify dependencies are loaded
if not ConfigUIUtils then
    print("|cffff0000Error:|r PeaversCommons.ConfigUIUtils not found. Please ensure PeaversCommons is up to date.")
    return
end

-- Localization helper - uses PDS.L:Get() from Localization.lua
local function L(key, ...)
    if PDS.L and PDS.L.Get then
        return PDS.L:Get(key, ...)
    end
    return key
end

-- Utility functions to reduce code duplication (now using PeaversCommons.ConfigUIUtils)
local Utils = {}

-- Creates a slider with standardized formatting
function Utils:CreateSlider(parent, name, label, min, max, step, defaultVal, width, callback)
    return ConfigUIUtils.CreateSlider(parent, name, label, min, max, step, defaultVal, width, callback)
end

-- Creates a dropdown with standardized formatting
function Utils:CreateDropdown(parent, name, label, options, defaultOption, width, callback)
    return ConfigUIUtils.CreateDropdown(parent, name, label, options, defaultOption, width, callback)
end

-- Creates a checkbox with standardized formatting
function Utils:CreateCheckbox(parent, name, label, x, y, checked, callback)
    return ConfigUIUtils.CreateCheckbox(parent, name, label, x, y, checked, callback)
end

-- Creates a section header with standardized formatting
function Utils:CreateSectionHeader(parent, text, indent, yPos, fontSize)
    return ConfigUIUtils.CreateSectionHeader(parent, text, indent, yPos, fontSize)
end

-- Creates a subsection label with standardized formatting
function Utils:CreateSubsectionLabel(parent, text, indent, y)
    return ConfigUIUtils.CreateSubsectionLabel(parent, text, indent, y)
end

-- Creates a color picker for a stat
function Utils:CreateStatColorPicker(parent, statType, y, indent)
    local r, g, b
    -- Use custom color if available, otherwise use default
    if Config.customColors[statType] then
        local color = Config.customColors[statType]
        r, g, b = color.r, color.g, color.b
    else
        r, g, b = PDS.Stats:GetColor(statType)
    end

    -- Use the ConfigUIUtils for creating a color picker with reset functionality
    local colorContainer, colorPicker, resetButton, newY = ConfigUIUtils.CreateColorPicker(
        parent,
        "PeaversStat" .. statType .. "ColorPicker",
        L("CONFIG_BAR_COLOR"),
        indent,
        y,
        {r = r, g = g, b = b},
        -- Color change handler
        function(newR, newG, newB)
            -- Save the custom color
            Config.customColors[statType] = { r = newR, g = newG, b = newB }
            Config:Save()

            -- Update the bar if it exists
            if PDS.BarManager then
                local bar = PDS.BarManager:GetBar(statType)
                if bar then
                    bar:UpdateColor()
                end
            end
        end,
        -- Reset handler
        function()
            -- Remove custom color
            Config.customColors[statType] = nil
            Config:Save()

            -- Get default color
            local defaultR, defaultG, defaultB = PDS.Stats:GetColor(statType)

            -- Update color picker appearance
            colorPicker:SetBackdropColor(defaultR, defaultG, defaultB)

            -- Update the bar if it exists
            if PDS.BarManager then
                local bar = PDS.BarManager:GetBar(statType)
                if bar then
                    bar:UpdateColor()
                end
            end
        end
    )

    return newY
end

-- Creates and initializes the options panel
function ConfigUI:InitializeOptions()
    if not UI then
        print("ERROR: UI module not loaded. Cannot initialize options.")
        return
    end

    -- Use ConfigUIUtils to create a standard settings panel
    local panel = ConfigUIUtils.CreateSettingsPanel(
        "Settings",
        "Configuration options for the dynamic stats display"
    )

    local content = panel.content
    local yPos = panel.yPos
    local baseSpacing = panel.baseSpacing
    local sectionSpacing = panel.sectionSpacing

    -- 1. DISPLAY SETTINGS SECTION
    yPos = self:CreateDisplayOptions(content, yPos, baseSpacing, sectionSpacing)

    -- Add a separator between major sections
    local _, newY = UI:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - baseSpacing

    -- 2. STAT OPTIONS SECTION
    yPos = self:CreateStatOptions(content, yPos, baseSpacing, sectionSpacing)

    -- Add a separator between major sections
    local _, newY = UI:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - baseSpacing

    -- 3. BAR APPEARANCE SECTION
    yPos = self:CreateBarAppearanceOptions(content, yPos, baseSpacing, sectionSpacing)

    -- Add a separator between major sections
    local _, newY = UI:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - baseSpacing

    -- 4. TEMPLATE MANAGEMENT SECTION
    yPos = self:CreateTemplateManagementSection(content, yPos, baseSpacing, sectionSpacing)

    -- Add a separator between major sections
    local _, newY = UI:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - baseSpacing

    -- 5. TEXT SETTINGS SECTION
    yPos = self:CreateTextOptions(content, yPos, baseSpacing, sectionSpacing)

    -- Add a separator between major sections
    local _, newY = UI:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - baseSpacing

    -- Update content height based on the last element position
    panel:UpdateContentHeight(yPos)

    -- Note: Settings registration is handled by PeaversCommons.SettingsUI:CreateSettingsPages
    -- in Main.lua to avoid duplicate panels

    return panel
end

-- 1. DISPLAY SETTINGS - Frame positioning, visibility, and main dimensions
function ConfigUI:CreateDisplayOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local subControlIndent = controlIndent + 15
    local sliderWidth = 400

    -- Display Settings section header
    local header, newY = Utils:CreateSectionHeader(content, L("CONFIG_DISPLAY_SETTINGS"), baseSpacing, yPos)
    yPos = newY - 10

    -- Frame dimensions subsection
    local dimensionsLabel, newY = Utils:CreateSubsectionLabel(content, L("CONFIG_FRAME_DIMENSIONS"), controlIndent, yPos)
    yPos = newY - 8

    -- Frame width slider
    local widthContainer, widthSlider = Utils:CreateSlider(
        content, "PeaversWidthSlider",
        L("CONFIG_FRAME_WIDTH"), 50, 400, 10,
        Config.frameWidth or 300, sliderWidth,
        function(value)
            Config.frameWidth = value
            Config.barWidth = value - 20
            Config:Save()
            if PDS.Core and PDS.Core.frame then
                PDS.Core.frame:SetWidth(value)
                if PDS.BarManager then
                    PDS.BarManager:ResizeBars()
                end
            end
        end
    )
    widthContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    self.uiElements.widthSlider = widthSlider
    yPos = yPos - 55

    -- Background opacity slider
    local opacityContainer, opacitySlider = Utils:CreateSlider(
        content, "PeaversOpacitySlider",
        L("CONFIG_BG_OPACITY"), 0, 1, 0.05,
        Config.bgAlpha or 0.5, sliderWidth,
        function(value)
            Config.bgAlpha = value
            Config:Save()
            if PDS.Core and PDS.Core.frame then
                PDS.Core.frame:SetBackdropColor(
                    Config.bgColor.r,
                    Config.bgColor.g,
                    Config.bgColor.b,
                    Config.bgAlpha
                )
                PDS.Core.frame:SetBackdropBorderColor(0, 0, 0, Config.bgAlpha)
                if PDS.Core.titleBar then
                    PDS.Core.titleBar:SetBackdropColor(
                        Config.bgColor.r,
                        Config.bgColor.g,
                        Config.bgColor.b,
                        Config.bgAlpha
                    )
                    PDS.Core.titleBar:SetBackdropBorderColor(0, 0, 0, Config.bgAlpha)
                end
            end
        end
    )
    opacityContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    self.uiElements.opacitySlider = opacitySlider
    yPos = yPos - 65

    -- Add a thin separator with more spacing
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 15

    -- Visibility options subsection
    local visibilityLabel, newY = Utils:CreateSubsectionLabel(content, L("CONFIG_VISIBILITY_OPTIONS"), controlIndent, yPos)
    yPos = newY - 8

    -- Show title bar checkbox
    local titleBarCheckbox, newY = Utils:CreateCheckbox(
        content, "PeaversTitleBarCheckbox",
        L("CONFIG_SHOW_TITLE_BAR"), controlIndent, yPos,
        Config.showTitleBar or true,
        function(checked)
            Config.showTitleBar = checked
            Config:Save()
            if PDS.Core then
                PDS.Core:UpdateTitleBarVisibility()
            end
        end
    )
    self.uiElements.titleBarCheckbox = titleBarCheckbox
    yPos = newY - 8 -- Update yPos for the next element

    -- Lock position checkbox
    local lockPositionCheckbox, newY = Utils:CreateCheckbox(
        content, "PeaversLockPositionCheckbox",
        L("CONFIG_LOCK_POSITION"), controlIndent, yPos,
        Config.lockPosition or false,
        function(checked)
            Config.lockPosition = checked
            Config:Save()
            if PDS.Core then
                PDS.Core:UpdateFrameLock()
            end
        end
    )
    self.uiElements.lockPositionCheckbox = lockPositionCheckbox
    yPos = newY - 8 -- Update yPos for the next element

    -- Hide out of combat checkbox
    local hideOutOfCombatCheckbox, newY = Utils:CreateCheckbox(
        content, "PeaversHideOutOfCombatCheckbox",
        L("CONFIG_HIDE_OUT_OF_COMBAT"), controlIndent, yPos,
        Config.hideOutOfCombat or false,
        function(checked)
            Config.hideOutOfCombat = checked
            Config:Save()
            -- Apply the change immediately if out of combat
            if PDS.Core and PDS.Core.frame then
                local inCombat = InCombatLockdown()
                if checked and not inCombat then
                    PDS.Core.frame:Hide()
                elseif not checked and not PDS.Core.frame:IsShown() then
                    PDS.Core.frame:Show()
                end
            end
        end
    )
    self.uiElements.hideOutOfCombatCheckbox = hideOutOfCombatCheckbox
    yPos = newY - 12 -- Update yPos for the next element

    -- Display mode dropdown
    local displayModeOptions = {
        ["ALWAYS"] = L("CONFIG_DISPLAY_MODE_ALWAYS"),
        ["PARTY_ONLY"] = L("CONFIG_DISPLAY_MODE_PARTY"),
        ["RAID_ONLY"] = L("CONFIG_DISPLAY_MODE_RAID")
    }

    local currentDisplayMode = displayModeOptions[Config.displayMode] or L("CONFIG_DISPLAY_MODE_ALWAYS")

    local displayModeContainer, displayModeDropdown = Utils:CreateDropdown(
        content, "PeaversDisplayModeDropdown",
        L("CONFIG_DISPLAY_MODE"), displayModeOptions,
        currentDisplayMode, sliderWidth,
        function(value)
            Config.displayMode = value
            Config:Save()
            -- Apply the change immediately
            if PDS.Core and PDS.Core.frame then
                PDS.Core:UpdateFrameVisibility()
            end
        end
    )
    displayModeContainer:SetPoint("TOPLEFT", subControlIndent, yPos)
    yPos = yPos - 65 -- Update yPos for the next element

    return yPos
end

-- 2. STAT OPTIONS - Separated into Primary and Secondary stats with explanations
function ConfigUI:CreateStatOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local subControlIndent = controlIndent + 15

    -- Main section header
    local header, newY = Utils:CreateSectionHeader(content, L("CONFIG_STAT_OPTIONS"), baseSpacing, yPos)
    yPos = newY - 10

    -- Initialize stat checkboxes storage
    if not self.uiElements.statCheckboxes then
        self.uiElements.statCheckboxes = {}
    end

    -- Function to create a show/hide checkbox for a stat
    local function CreateStatCheckbox(statType, y, indent)
        -- Initialize showStats table if it doesn't exist
        if not Config.showStats then
            Config.showStats = {}
        end

        local onClick = function(checked)
            Config.showStats[statType] = checked
            Config:Save()
            if PDS.BarManager then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end

        local checkbox, newY = Utils:CreateCheckbox(
            content,
            "PeaversStat" .. statType .. "Checkbox",
            L("CONFIG_SHOW_STAT", PDS.Stats:GetName(statType)),
            indent, y,                           -- Pass x and y positions explicitly
            Config.showStats[statType] ~= false, -- Default to true
            onClick
        )
        -- Store reference for refresh
        self.uiElements.statCheckboxes[statType] = checkbox
        return newY
    end

    -- PRIMARY STATS SECTION
    local primaryStatsHeader, newY = Utils:CreateSectionHeader(content, L("CONFIG_PRIMARY_STATS"), baseSpacing + 10, yPos, 16)
    yPos = newY - 5

    -- Add explanation about primary stats
    local primaryStatsExplanation = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    primaryStatsExplanation:SetPoint("TOPLEFT", baseSpacing + 15, yPos)
    primaryStatsExplanation:SetWidth(400)
    primaryStatsExplanation:SetJustifyH("LEFT")
    primaryStatsExplanation:SetText(L("CONFIG_PRIMARY_STATS_DESC"))

    -- Calculate the height of the explanation text
    local explanationHeight = 40
    yPos = yPos - explanationHeight - 10

    -- Define primary stats according to WoW character screen
    local primaryStats = { "STRENGTH", "AGILITY", "INTELLECT", "STAMINA" }

    -- Create sections for primary stats
    for i, statType in ipairs(primaryStats) do
        -- Create subsection header with stat name
        local statHeader, newY = Utils:CreateSectionHeader(content, PDS.Stats:GetName(statType), baseSpacing + 25, yPos,
            14)
        yPos = newY

        -- Show/hide checkbox
        local newY = CreateStatCheckbox(statType, yPos, baseSpacing + 40)
        yPos = newY

        -- Color picker
        yPos = Utils:CreateStatColorPicker(content, statType, yPos, baseSpacing + 40)

        -- Add a thin separator between stats (except after the last one)
        if i < #primaryStats then
            local _, newY = UI:CreateSeparator(content, baseSpacing + 30, yPos, 380)
            yPos = newY - 5
        end
    end

    -- Add a separator between primary and secondary stats
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 15

    -- SECONDARY STATS SECTION
    local secondaryStatsHeader, newY = Utils:CreateSectionHeader(content, L("CONFIG_SECONDARY_STATS"), baseSpacing + 10, yPos, 16)
    yPos = newY - 5

    -- Add explanation about secondary stats
    local secondaryStatsExplanation = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    secondaryStatsExplanation:SetPoint("TOPLEFT", baseSpacing + 15, yPos)
    secondaryStatsExplanation:SetWidth(400)
    secondaryStatsExplanation:SetJustifyH("LEFT")
    secondaryStatsExplanation:SetText(L("CONFIG_SECONDARY_STATS_DESC"))

    -- Calculate the height of the explanation text
    local explanationHeight = 40
    yPos = yPos - explanationHeight - 10

    -- Define secondary stats in the order they appear on WoW character screen
    local secondaryStats = {
        "CRIT", "HASTE", "MASTERY", "VERSATILITY",
        "VERSATILITY_DAMAGE_REDUCTION", -- Damage reduction % (useful for tanks, Disc Priests)
        "DODGE", "PARRY",
        "BLOCK", "LEECH", "AVOIDANCE", "SPEED"
    }

    -- Create sections for secondary stats
    for i, statType in ipairs(secondaryStats) do
        -- Create subsection header with stat name
        local statHeader, newY = Utils:CreateSectionHeader(content, PDS.Stats:GetName(statType), baseSpacing + 25, yPos,
            14)
        yPos = newY

        -- Show/hide checkbox
        local newY = CreateStatCheckbox(statType, yPos, baseSpacing + 40)
        yPos = newY

        -- Color picker
        yPos = Utils:CreateStatColorPicker(content, statType, yPos, baseSpacing + 40)

        -- Add a thin separator between stats (except after the last one)
        if i < #secondaryStats then
            local _, newY = UI:CreateSeparator(content, baseSpacing + 30, yPos, 380)
            yPos = newY - 5
        end
    end

    return yPos - 15 -- Extra spacing after all stat sections
end

-- 3. BAR APPEARANCE - Everything related to the bars appearance and layout
function ConfigUI:CreateBarAppearanceOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local subControlIndent = controlIndent + 15
    local sliderWidth = 400

    -- Bar Appearance section header
    local header, newY = Utils:CreateSectionHeader(content, L("CONFIG_BAR_APPEARANCE"), baseSpacing, yPos)
    yPos = newY - 10

    -- Bar dimensions subsection
    local dimensionsLabel, newY = Utils:CreateSubsectionLabel(content, L("CONFIG_BAR_DIMENSIONS"), controlIndent, yPos)
    yPos = newY - 8

    -- Initialize values with defaults if they don't exist
    if not Config.barHeight then Config.barHeight = 20 end
    if not Config.barSpacing then Config.barSpacing = 2 end
    if not Config.barAlpha then Config.barAlpha = 1 end
    if not Config.barBgAlpha then Config.barBgAlpha = 0.2 end

    -- Bar height slider
    local heightContainer, heightSlider = Utils:CreateSlider(
        content, "PeaversHeightSlider",
        L("CONFIG_BAR_HEIGHT"), 10, 40, 1,
        Config.barHeight, sliderWidth,
        function(value)
            Config.barHeight = value
            Config:Save()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end
    )
    heightContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    self.uiElements.heightSlider = heightSlider
    yPos = yPos - 55

    -- Bar spacing slider
    local spacingContainer, spacingSlider = Utils:CreateSlider(
        content, "PeaversSpacingSlider",
        L("CONFIG_BAR_SPACING"), -5, 10, 1,
        Config.barSpacing, sliderWidth,
        function(value)
            Config.barSpacing = value
            Config:Save()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end
    )
    spacingContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    self.uiElements.spacingSlider = spacingSlider
    yPos = yPos - 65

    -- Bar background opacity slider
    local bgOpacityContainer, bgOpacitySlider = Utils:CreateSlider(
        content, "PeaversBarBgAlphaSlider",
        L("CONFIG_BAR_BG_OPACITY"), 0, 1, 0.05,
        Config.barBgAlpha, sliderWidth,
        function(value)
            Config.barBgAlpha = value
            Config:Save()
            if PDS.BarManager then
                PDS.BarManager:ResizeBars()
            end
        end
    )
    bgOpacityContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    self.uiElements.bgOpacitySlider = bgOpacitySlider
    yPos = yPos - 65

    -- Bar fill opacity slider (allows text-only mode when set to 0)
    local barOpacityContainer, barOpacitySlider = Utils:CreateSlider(
        content, "PeaversBarAlphaSlider",
        L("CONFIG_BAR_OPACITY"), 0, 1, 0.05,
        Config.barAlpha or 1.0, sliderWidth,
        function(value)
            Config.barAlpha = value
            Config:Save()
            -- Update all bar colors to apply the new opacity
            if PDS.BarManager and PDS.BarManager.bars then
                for _, bar in ipairs(PDS.BarManager.bars) do
                    bar:UpdateColor()
                end
            end
        end
    )
    barOpacityContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    self.uiElements.barOpacitySlider = barOpacitySlider
    yPos = yPos - 65

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 15

    -- Bar style subsection
    local styleLabel, newY = Utils:CreateSubsectionLabel(content, L("CONFIG_BAR_STYLE"), controlIndent, yPos)
    yPos = newY - 8

    -- Texture dropdown container
    local textures = Config:GetBarTextures()
    local currentTexture = textures[Config.barTexture] or "Default"

    local textureContainer, textureDropdown = Utils:CreateDropdown(
        content, "PeaversTextureDropdown",
        L("CONFIG_BAR_TEXTURE"), textures,
        currentTexture, sliderWidth,
        function(value)
            Config.barTexture = value
            Config:Save()
            if PDS.BarManager then
                PDS.BarManager:ResizeBars()
            end
        end
    )
    textureContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    self.uiElements.textureDropdown = textureDropdown
    yPos = yPos - 65

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 15
    
    -- Additional Bar Options
    local additionalLabel, newY = Utils:CreateSubsectionLabel(content, L("CONFIG_ADDITIONAL_BAR_OPTIONS"), controlIndent, yPos)
    yPos = newY - 8

    -- Initialize values with defaults if they don't exist
    if Config.showStatChanges == nil then Config.showStatChanges = true end
    if Config.showRatings == nil then Config.showRatings = true end
    if Config.showOverflowBars == nil then Config.showOverflowBars = true end

    -- Show stat changes checkbox
    local showStatChangesCheckbox, newY = Utils:CreateCheckbox(
        content, "PeaversShowStatChangesCheckbox",
        L("CONFIG_SHOW_STAT_CHANGES"), controlIndent, yPos,
        Config.showStatChanges,
        function(checked)
            Config.showStatChanges = checked
            Config:Save()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end
    )
    self.uiElements.showStatChangesCheckbox = showStatChangesCheckbox
    yPos = newY - 8 -- Update yPos for the next element

    -- Show ratings checkbox
    local showRatingsCheckbox, newY = Utils:CreateCheckbox(
        content, "PeaversShowRatingsCheckbox",
        L("CONFIG_SHOW_RATINGS"), controlIndent, yPos,
        Config.showRatings,
        function(checked)
            Config.showRatings = checked
            Config:Save()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end
    )
    self.uiElements.showRatingsCheckbox = showRatingsCheckbox
    yPos = newY - 8 -- Update yPos for the next element

    -- Show overflow bars checkbox
    local showOverflowBarsCheckbox, newY = Utils:CreateCheckbox(
        content, "PeaversShowOverflowBarsCheckbox",
        L("CONFIG_SHOW_OVERFLOW_BARS"), controlIndent, yPos,
        Config.showOverflowBars,
        function(checked)
            Config.showOverflowBars = checked
            Config:Save()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end
    )
    self.uiElements.showOverflowBarsCheckbox = showOverflowBarsCheckbox
    yPos = newY - 8 -- Update yPos for the next element

    -- Enable talent adjustments checkbox
    local enableTalentAdjustmentsCheckbox, newY = Utils:CreateCheckbox(
        content, "PeaversEnableTalentAdjustmentsCheckbox",
        L("CONFIG_ENABLE_TALENT_ADJUSTMENTS"), controlIndent, yPos,
        Config.enableTalentAdjustments,
        function(checked)
            Config.enableTalentAdjustments = checked
            Config:Save()
            if PDS.BarManager then
                PDS.BarManager:UpdateAllBars()
            end
        end
    )
    self.uiElements.enableTalentAdjustmentsCheckbox = enableTalentAdjustmentsCheckbox
    yPos = newY - 8 -- Update yPos for the next element

    return yPos
end

-- 4. TEMPLATE MANAGEMENT - Delegates to TemplateUI module
function ConfigUI:CreateTemplateManagementSection(content, yPos, baseSpacing, sectionSpacing)
    if PDS.TemplateUI and PDS.TemplateUI.CreateTemplateManagementUI then
        return PDS.TemplateUI:CreateTemplateManagementUI(content, yPos, baseSpacing, sectionSpacing)
    end
    return yPos
end

-- 5. TEXT SETTINGS - Font and text appearance settings
function ConfigUI:CreateTextOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local subControlIndent = controlIndent + 15
    local sliderWidth = 400

    -- Text Settings section header
    local header, newY = Utils:CreateSectionHeader(content, L("CONFIG_TEXT_SETTINGS"), baseSpacing, yPos)
    yPos = newY - 10

    -- Font selection subsection
    local fontSelectLabel, newY = Utils:CreateSubsectionLabel(content, L("CONFIG_FONT_SELECTION"), controlIndent, yPos)
    yPos = newY - 8

    -- Initialize values with defaults if they don't exist
    if not Config.fontFace then 
        Config.fontFace = Config:GetDefaultFont()  -- Use locale-appropriate font
    end
    if not Config.fontSize then Config.fontSize = 11 end
    if not Config.fontOutline then Config.fontOutline = "" end
    if not Config.fontShadow then Config.fontShadow = true end

    -- Font dropdown container
    local fonts = Config:GetFonts()
    local currentFont = fonts[Config.fontFace] or "Default"

    local fontContainer, fontDropdown = Utils:CreateDropdown(
        content, "PeaversFontDropdown",
        L("CONFIG_FONT"), fonts,
        currentFont, sliderWidth,
        function(value)
            Config.fontFace = value
            Config:Save()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end
    )
    fontContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    self.uiElements.fontDropdown = fontDropdown
    yPos = yPos - 65

    -- Font size slider
    local fontSizeContainer, fontSizeSlider = Utils:CreateSlider(
        content, "PeaversFontSizeSlider",
        L("CONFIG_FONT_SIZE"), 6, 18, 1,
        Config.fontSize, sliderWidth,
        function(value)
            Config.fontSize = value
            Config:Save()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end
    )
    fontSizeContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    self.uiElements.fontSizeSlider = fontSizeSlider
    yPos = yPos - 55

    -- Font style options
    local fontStyleLabel, newY = Utils:CreateSubsectionLabel(content, L("CONFIG_FONT_STYLE"), controlIndent, yPos)
    yPos = newY - 8

    -- Font outline checkbox
    local fontOutlineCheckbox, newY = Utils:CreateCheckbox(
        content, "PeaversFontOutlineCheckbox",
        L("CONFIG_FONT_OUTLINE"), controlIndent, yPos,
        Config.fontOutline == "OUTLINE",
        function(checked)
            Config.fontOutline = checked and "OUTLINE" or ""
            Config:Save()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end
    )
    self.uiElements.fontOutlineCheckbox = fontOutlineCheckbox
    yPos = newY - 8 -- Update yPos for the next element

    -- Font shadow checkbox
    local fontShadowCheckbox, newY = Utils:CreateCheckbox(
        content, "PeaversFontShadowCheckbox",
        L("CONFIG_FONT_SHADOW"), controlIndent, yPos,
        Config.fontShadow,
        function(checked)
            Config.fontShadow = checked
            Config:Save()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end
    )
    self.uiElements.fontShadowCheckbox = fontShadowCheckbox
    yPos = newY - 15 -- Update yPos for the next element

    return yPos
end

-- Refresh all UI elements to match current Config values
-- Call this after profile changes (e.g., spec switch) to update the UI
function ConfigUI:RefreshUI()
    if not self.uiElements then return end

    local Config = PDS.Config

    -- Refresh sliders
    if self.uiElements.widthSlider then
        self.uiElements.widthSlider:SetValue(Config.frameWidth or 250)
    end

    if self.uiElements.opacitySlider then
        self.uiElements.opacitySlider:SetValue(Config.bgAlpha or 0.8)
    end

    if self.uiElements.heightSlider then
        self.uiElements.heightSlider:SetValue(Config.barHeight or 20)
    end

    if self.uiElements.spacingSlider then
        self.uiElements.spacingSlider:SetValue(Config.barSpacing or 2)
    end

    if self.uiElements.bgOpacitySlider then
        self.uiElements.bgOpacitySlider:SetValue(Config.barBgAlpha or 0.7)
    end

    if self.uiElements.barOpacitySlider then
        self.uiElements.barOpacitySlider:SetValue(Config.barAlpha or 1.0)
    end

    if self.uiElements.fontSizeSlider then
        self.uiElements.fontSizeSlider:SetValue(Config.fontSize or 9)
    end

    -- Refresh checkboxes
    if self.uiElements.titleBarCheckbox then
        self.uiElements.titleBarCheckbox:SetChecked(Config.showTitleBar)
    end

    if self.uiElements.lockPositionCheckbox then
        self.uiElements.lockPositionCheckbox:SetChecked(Config.lockPosition)
    end

    if self.uiElements.hideOutOfCombatCheckbox then
        self.uiElements.hideOutOfCombatCheckbox:SetChecked(Config.hideOutOfCombat)
    end

    if self.uiElements.showStatChangesCheckbox then
        self.uiElements.showStatChangesCheckbox:SetChecked(Config.showStatChanges)
    end

    if self.uiElements.showRatingsCheckbox then
        self.uiElements.showRatingsCheckbox:SetChecked(Config.showRatings)
    end

    if self.uiElements.showOverflowBarsCheckbox then
        self.uiElements.showOverflowBarsCheckbox:SetChecked(Config.showOverflowBars)
    end

    if self.uiElements.enableTalentAdjustmentsCheckbox then
        self.uiElements.enableTalentAdjustmentsCheckbox:SetChecked(Config.enableTalentAdjustments)
    end

    if self.uiElements.fontOutlineCheckbox then
        self.uiElements.fontOutlineCheckbox:SetChecked(Config.fontOutline == "OUTLINE")
    end

    if self.uiElements.fontShadowCheckbox then
        self.uiElements.fontShadowCheckbox:SetChecked(Config.fontShadow)
    end

    -- Refresh dropdowns
    if self.uiElements.textureDropdown and Config.barTexture then
        local textures = Config:GetBarTextures()
        local currentTexture = textures[Config.barTexture] or "Default"
        UIDropDownMenu_SetText(self.uiElements.textureDropdown, currentTexture)
    end

    if self.uiElements.fontDropdown and Config.fontFace then
        local fonts = Config:GetFonts()
        local currentFont = fonts[Config.fontFace] or "Default"
        UIDropDownMenu_SetText(self.uiElements.fontDropdown, currentFont)
    end

    -- Refresh stat checkboxes
    if self.uiElements.statCheckboxes then
        for statType, checkbox in pairs(self.uiElements.statCheckboxes) do
            checkbox:SetChecked(Config.showStats[statType] ~= false)
        end
    end
end

-- Opens the configuration panel
function ConfigUI:OpenOptions()
    -- Ensure settings are saved before opening
    PDS.Config:Save()

    if Settings and Settings.OpenToCategory then
        -- Try using the category ID stored by PeaversCommons.SettingsUI
        -- Prefer opening to the settings subcategory if available
        if PDS.directSettingsCategoryID then
            local success = pcall(Settings.OpenToCategory, PDS.directSettingsCategoryID)
            if success then return end
        end

        -- Fallback to main category ID
        if PDS.directCategoryID then
            local success = pcall(Settings.OpenToCategory, PDS.directCategoryID)
            if success then return end
        end

        -- Try with category objects as fallback
        if PDS.directSettingsCategory then
            local success = pcall(Settings.OpenToCategory, PDS.directSettingsCategory)
            if success then return end
        end

        if PDS.directCategory then
            local success = pcall(Settings.OpenToCategory, PDS.directCategory)
            if success then return end
        end
    end

    -- Fallback: just open the Settings panel
    if SettingsPanel then
        ShowUIPanel(SettingsPanel)
        return
    end

    -- Legacy fallback for older clients
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("PeaversDynamicStats")
        InterfaceOptionsFrame_OpenToCategory("PeaversDynamicStats")
    end
end

-- Handler for the /pds config command
PDS.Config.OpenOptionsCommand = function()
    ConfigUI:OpenOptions()
end

-- Initialize the configuration UI when called
function ConfigUI:Initialize()
    self.panel = self:InitializeOptions()
    
    -- Hook Settings panel to ensure settings are saved when opened and closed
    if Settings then
        if Settings.OpenToCategory then
            hooksecurefunc(Settings, "OpenToCategory", function()
                -- Save settings before opening to ensure we have the latest
                PDS.Config:Save()
            end)
        end
        
        if Settings.CloseUI then
            hooksecurefunc(Settings, "CloseUI", function()
                -- Ensure settings are saved when closing the panel
                PDS.Config:Save()
                
                -- Force a delayed save to ensure everything is written
                C_Timer.After(0.5, function()
                    PDS.Config:Save()
                end)
            end)
        end
    end
    
    -- For older clients using InterfaceOptionsFrame
    if InterfaceOptionsFrame then
        if not self.frameHooksRegistered then
            InterfaceOptionsFrame:HookScript("OnHide", function()
                PDS.Config:Save()
                
                -- Force a delayed save to ensure everything is written
                C_Timer.After(0.5, function()
                    PDS.Config:Save()
                end)
            end)
            self.frameHooksRegistered = true
        end
    end
end

return ConfigUI
