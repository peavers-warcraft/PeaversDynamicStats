local _, PDS = ...
local Config = PDS.Config
local UI = PDS.UI

-- Initialize ConfigUI.lua namespace
local ConfigUI = {}
PDS.ConfigUI = ConfigUI

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
        PDS.L["CONFIG_BAR_COLOR"],
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

    -- 3.5. SPEC SETTINGS SECTION
    yPos = self:CreateSpecOptions(content, yPos, baseSpacing, sectionSpacing)

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
    local header, newY = Utils:CreateSectionHeader(content, PDS.L["CONFIG_DISPLAY_SETTINGS"], baseSpacing, yPos)
    yPos = newY - 10

    -- Frame dimensions subsection
    local dimensionsLabel, newY = Utils:CreateSubsectionLabel(content, PDS.L["CONFIG_FRAME_DIMENSIONS"], controlIndent, yPos)
    yPos = newY - 8

    -- Frame width slider
    local widthContainer, widthSlider = Utils:CreateSlider(
        content, "PeaversWidthSlider",
        PDS.L["CONFIG_FRAME_WIDTH"], 50, 400, 10,
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
    yPos = yPos - 55

    -- Background opacity slider
    local opacityContainer, opacitySlider = Utils:CreateSlider(
        content, "PeaversOpacitySlider",
        PDS.L["CONFIG_BG_OPACITY"], 0, 1, 0.05,
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
    yPos = yPos - 65

    -- Add a thin separator with more spacing
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 15

    -- Visibility options subsection
    local visibilityLabel, newY = Utils:CreateSubsectionLabel(content, PDS.L["CONFIG_VISIBILITY_OPTIONS"], controlIndent, yPos)
    yPos = newY - 8

    -- Show title bar checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversTitleBarCheckbox",
        PDS.L["CONFIG_SHOW_TITLE_BAR"], controlIndent, yPos,
        Config.showTitleBar or true,
        function(checked)
            Config.showTitleBar = checked
            Config:Save()
            if PDS.Core then
                PDS.Core:UpdateTitleBarVisibility()
            end
        end
    )
    yPos = newY - 8 -- Update yPos for the next element

    -- Lock position checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversLockPositionCheckbox",
        PDS.L["CONFIG_LOCK_POSITION"], controlIndent, yPos,
        Config.lockPosition or false,
        function(checked)
            Config.lockPosition = checked
            Config:Save()
            if PDS.Core then
                PDS.Core:UpdateFrameLock()
            end
        end
    )
    yPos = newY - 8 -- Update yPos for the next element

    -- Hide out of combat checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversHideOutOfCombatCheckbox",
        PDS.L["CONFIG_HIDE_OUT_OF_COMBAT"], controlIndent, yPos,
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
    yPos = newY - 12 -- Update yPos for the next element

    -- Display mode dropdown
    local displayModeOptions = {
        ["ALWAYS"] = PDS.L["CONFIG_DISPLAY_MODE_ALWAYS"],
        ["PARTY_ONLY"] = PDS.L["CONFIG_DISPLAY_MODE_PARTY"],
        ["RAID_ONLY"] = PDS.L["CONFIG_DISPLAY_MODE_RAID"]
    }

    local currentDisplayMode = displayModeOptions[Config.displayMode] or PDS.L["CONFIG_DISPLAY_MODE_ALWAYS"]

    local displayModeContainer, displayModeDropdown = Utils:CreateDropdown(
        content, "PeaversDisplayModeDropdown",
        PDS.L["CONFIG_DISPLAY_MODE"], displayModeOptions,
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
    local header, newY = Utils:CreateSectionHeader(content, PDS.L["CONFIG_STAT_OPTIONS"], baseSpacing, yPos)
    yPos = newY - 10

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

        local _, newY = Utils:CreateCheckbox(
            content,
            "PeaversStat" .. statType .. "Checkbox",
            PDS.L:Get("CONFIG_SHOW_STAT", PDS.Stats:GetName(statType)),
            indent, y,                           -- Pass x and y positions explicitly
            Config.showStats[statType] ~= false, -- Default to true
            onClick
        )
        return newY
    end

    -- PRIMARY STATS SECTION
    local primaryStatsHeader, newY = Utils:CreateSectionHeader(content, PDS.L["CONFIG_PRIMARY_STATS"], baseSpacing + 10, yPos, 16)
    yPos = newY - 5

    -- Add explanation about primary stats
    local primaryStatsExplanation = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    primaryStatsExplanation:SetPoint("TOPLEFT", baseSpacing + 15, yPos)
    primaryStatsExplanation:SetWidth(400)
    primaryStatsExplanation:SetJustifyH("LEFT")
    primaryStatsExplanation:SetText(PDS.L["CONFIG_PRIMARY_STATS_DESC"])

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
    local secondaryStatsHeader, newY = Utils:CreateSectionHeader(content, PDS.L["CONFIG_SECONDARY_STATS"], baseSpacing + 10, yPos, 16)
    yPos = newY - 5

    -- Add explanation about secondary stats
    local secondaryStatsExplanation = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    secondaryStatsExplanation:SetPoint("TOPLEFT", baseSpacing + 15, yPos)
    secondaryStatsExplanation:SetWidth(400)
    secondaryStatsExplanation:SetJustifyH("LEFT")
    secondaryStatsExplanation:SetText(PDS.L["CONFIG_SECONDARY_STATS_DESC"])

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
    local header, newY = Utils:CreateSectionHeader(content, PDS.L["CONFIG_BAR_APPEARANCE"], baseSpacing, yPos)
    yPos = newY - 10

    -- Bar dimensions subsection
    local dimensionsLabel, newY = Utils:CreateSubsectionLabel(content, PDS.L["CONFIG_BAR_DIMENSIONS"], controlIndent, yPos)
    yPos = newY - 8

    -- Initialize values with defaults if they don't exist
    if not Config.barHeight then Config.barHeight = 20 end
    if not Config.barSpacing then Config.barSpacing = 2 end
    if not Config.barAlpha then Config.barAlpha = 1 end
    if not Config.barBgAlpha then Config.barBgAlpha = 0.2 end

    -- Bar height slider
    local heightContainer, heightSlider = Utils:CreateSlider(
        content, "PeaversHeightSlider",
        PDS.L["CONFIG_BAR_HEIGHT"], 10, 40, 1,
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
    yPos = yPos - 55

    -- Bar spacing slider
    local spacingContainer, spacingSlider = Utils:CreateSlider(
        content, "PeaversSpacingSlider",
        PDS.L["CONFIG_BAR_SPACING"], -5, 10, 1,
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
    yPos = yPos - 65
    
    -- Bar background opacity slider
    local bgOpacityContainer, bgOpacitySlider = Utils:CreateSlider(
        content, "PeaversBarBgAlphaSlider",
        PDS.L["CONFIG_BAR_BG_OPACITY"], 0, 1, 0.05,
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
    yPos = yPos - 65

    -- Bar fill opacity slider (allows text-only mode when set to 0)
    local barOpacityContainer, barOpacitySlider = Utils:CreateSlider(
        content, "PeaversBarAlphaSlider",
        PDS.L["CONFIG_BAR_OPACITY"], 0, 1, 0.05,
        Config.barAlpha or 1.0, sliderWidth,
        function(value)
            Config.barAlpha = value
            Config:Save()
            if PDS.BarManager then
                PDS.BarManager:UpdateAllBars()
            end
        end
    )
    barOpacityContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    yPos = yPos - 65

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 15

    -- Bar style subsection
    local styleLabel, newY = Utils:CreateSubsectionLabel(content, PDS.L["CONFIG_BAR_STYLE"], controlIndent, yPos)
    yPos = newY - 8

    -- Texture dropdown container
    local textures = Config:GetBarTextures()
    local currentTexture = textures[Config.barTexture] or "Default"

    local textureContainer, textureDropdown = Utils:CreateDropdown(
        content, "PeaversTextureDropdown",
        PDS.L["CONFIG_BAR_TEXTURE"], textures,
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
    yPos = yPos - 65

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 15
    
    -- Additional Bar Options
    local additionalLabel, newY = Utils:CreateSubsectionLabel(content, PDS.L["CONFIG_ADDITIONAL_BAR_OPTIONS"], controlIndent, yPos)
    yPos = newY - 8

    -- Initialize values with defaults if they don't exist
    if Config.showStatChanges == nil then Config.showStatChanges = true end
    if Config.showRatings == nil then Config.showRatings = true end
    if Config.showOverflowBars == nil then Config.showOverflowBars = true end

    -- Show stat changes checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversShowStatChangesCheckbox",
        PDS.L["CONFIG_SHOW_STAT_CHANGES"], controlIndent, yPos,
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
    yPos = newY - 8 -- Update yPos for the next element

    -- Show ratings checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversShowRatingsCheckbox",
        PDS.L["CONFIG_SHOW_RATINGS"], controlIndent, yPos,
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
    yPos = newY - 8 -- Update yPos for the next element

    -- Show overflow bars checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversShowOverflowBarsCheckbox",
        PDS.L["CONFIG_SHOW_OVERFLOW_BARS"], controlIndent, yPos,
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
    yPos = newY - 8 -- Update yPos for the next element
    
    -- Enable talent adjustments checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversEnableTalentAdjustmentsCheckbox",
        PDS.L["CONFIG_ENABLE_TALENT_ADJUSTMENTS"], controlIndent, yPos,
        Config.enableTalentAdjustments,
        function(checked)
            Config.enableTalentAdjustments = checked
            Config:Save()
            if PDS.BarManager then
                PDS.BarManager:UpdateAllBars()
            end
        end
    )
    yPos = newY - 8 -- Update yPos for the next element

    return yPos
end

-- 4. TEXT SETTINGS - Font and text appearance settings
-- 3.5 SPECIALIZATION OPTIONS - Settings for per-spec configuration
function ConfigUI:CreateSpecOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local subControlIndent = controlIndent + 15

    -- Specialization Settings section header
    local header, newY = Utils:CreateSectionHeader(content, PDS.L["CONFIG_SPEC_SETTINGS"], baseSpacing, yPos)
    yPos = newY - 10

    -- Add "NEW" badge
    local newBadge = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    newBadge:SetPoint("LEFT", header, "RIGHT", 10, 0)
    newBadge:SetText(PDS.L["NEW_BADGE"])
    newBadge:SetTextColor(0, 1, 0)

    -- Create a colored glow around the NEW badge
    local newBadgeGlow = content:CreateTexture(nil, "BACKGROUND")
    newBadgeGlow:SetPoint("CENTER", newBadge, "CENTER", 0, 0)
    newBadgeGlow:SetSize(50, 25)
    newBadgeGlow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    newBadgeGlow:SetBlendMode("ADD")
    newBadgeGlow:SetAlpha(0.7)

    -- Animate the glow
    local animGroup = newBadgeGlow:CreateAnimationGroup()
    animGroup:SetLooping("REPEAT")

    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.7)
    fadeOut:SetToAlpha(0.3)
    fadeOut:SetDuration(1)
    fadeOut:SetOrder(1)

    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.3)
    fadeIn:SetToAlpha(0.7)
    fadeIn:SetDuration(1)
    fadeIn:SetOrder(2)

    animGroup:Play()

    -- Add explanation about specialization settings
    local specExplanation = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    specExplanation:SetPoint("TOPLEFT", baseSpacing + 15, yPos)
    specExplanation:SetWidth(400)
    specExplanation:SetJustifyH("LEFT")
    specExplanation:SetText(PDS.L["CONFIG_SPEC_DESC"])

    -- Calculate the height of the explanation text
    local explanationHeight = 40
    yPos = yPos - explanationHeight - 10

    -- Use shared spec settings checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversUseSharedSpecCheckbox",
        PDS.L["CONFIG_USE_SHARED_SPEC"], controlIndent, yPos,
        Config.useSharedSpec,
        function(checked)
            Config.useSharedSpec = checked
            Config:Save()

            -- If checked, copy current settings to the shared profile
            if checked then
                local charKey = Config:GetCharacterKey()
                local currentProfileKey = charKey .. "-" .. tostring(Config.currentSpec)
                local sharedProfileKey = charKey .. "-shared"

                -- Make sure SavedVariables DB exists
                if PeaversDynamicStatsDB and PeaversDynamicStatsDB.profiles then
                    -- Copy current spec settings to shared profile if it exists
                    if PeaversDynamicStatsDB.profiles[currentProfileKey] then
                        PeaversDynamicStatsDB.profiles[sharedProfileKey] = Config:CopyTable(PeaversDynamicStatsDB.profiles[currentProfileKey])
                    end
                end
            end

            -- Show a message to the user
            if checked then
                PDS.Utils.Print(PDS.L["CONFIG_SPEC_SHARED_MSG"])
            else
                PDS.Utils.Print(PDS.L["CONFIG_SPEC_SEPARATE_MSG"])
            end
        end
    )
    yPos = newY - 8

    -- Add extra info text
    local extraInfo = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    extraInfo:SetPoint("TOPLEFT", subControlIndent, yPos)
    extraInfo:SetWidth(380)
    extraInfo:SetJustifyH("LEFT")
    extraInfo:SetTextColor(0.8, 0.8, 1)
    extraInfo:SetText(PDS.L["CONFIG_SPEC_INFO"])

    -- Calculate height based on the text
    local infoHeight = 50
    yPos = yPos - infoHeight - 10

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
    local header, newY = Utils:CreateSectionHeader(content, PDS.L["CONFIG_TEXT_SETTINGS"], baseSpacing, yPos)
    yPos = newY - 10

    -- Font selection subsection
    local fontSelectLabel, newY = Utils:CreateSubsectionLabel(content, PDS.L["CONFIG_FONT_SELECTION"], controlIndent, yPos)
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
        PDS.L["CONFIG_FONT"], fonts,
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
    yPos = yPos - 65

    -- Font size slider
    local fontSizeContainer, fontSizeSlider = Utils:CreateSlider(
        content, "PeaversFontSizeSlider",
        PDS.L["CONFIG_FONT_SIZE"], 6, 18, 1,
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
    yPos = yPos - 55

    -- Font style options
    local fontStyleLabel, newY = Utils:CreateSubsectionLabel(content, PDS.L["CONFIG_FONT_STYLE"], controlIndent, yPos)
    yPos = newY - 8

    -- Font outline checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversFontOutlineCheckbox",
        PDS.L["CONFIG_FONT_OUTLINE"], controlIndent, yPos,
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
    yPos = newY - 8 -- Update yPos for the next element

    -- Font shadow checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversFontShadowCheckbox",
        PDS.L["CONFIG_FONT_SHADOW"], controlIndent, yPos,
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
    yPos = newY - 15 -- Update yPos for the next element

    return yPos
end

-- Opens the configuration panel
function ConfigUI:OpenOptions()
    -- Ensure settings are saved before opening
    PDS.Config:Save()

    -- Debug: show what categories are available
    print("PDS OpenOptions - directSettingsCategoryID:", PDS.directSettingsCategoryID)
    print("PDS OpenOptions - directCategoryID:", PDS.directCategoryID)
    print("PDS OpenOptions - directSettingsCategory:", PDS.directSettingsCategory)
    print("PDS OpenOptions - directCategory:", PDS.directCategory)

    if Settings and Settings.OpenToCategory then
        -- Try using the category ID stored by PeaversCommons.SettingsUI
        -- Prefer opening to the settings subcategory if available
        if PDS.directSettingsCategoryID then
            print("Trying directSettingsCategoryID...")
            local success, err = pcall(Settings.OpenToCategory, PDS.directSettingsCategoryID)
            print("Result:", success, err)
            if success then return end
        end

        -- Fallback to main category ID
        if PDS.directCategoryID then
            print("Trying directCategoryID...")
            local success, err = pcall(Settings.OpenToCategory, PDS.directCategoryID)
            print("Result:", success, err)
            if success then return end
        end

        -- Try with category objects as fallback
        if PDS.directSettingsCategory then
            print("Trying directSettingsCategory object...")
            local success, err = pcall(Settings.OpenToCategory, PDS.directSettingsCategory)
            print("Result:", success, err)
            if success then return end
        end

        if PDS.directCategory then
            print("Trying directCategory object...")
            local success, err = pcall(Settings.OpenToCategory, PDS.directCategory)
            print("Result:", success, err)
            if success then return end
        end
    end

    -- Fallback: just open the Settings panel
    print("Using fallback: ShowUIPanel")
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
