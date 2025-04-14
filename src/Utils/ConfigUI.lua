local _, PDS = ...
local Config = PDS.Config
local UI = PDS.UI
local ConfigUI = {}

-- Initialize ConfigUI namespace
PDS.Config.UI = ConfigUI

-- Utility functions to reduce code duplication
local Utils = {}

-- Creates a slider with standardized formatting
function Utils:CreateSlider(parent, name, label, min, max, step, defaultVal, width, callback)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 400, 50)

    local labelText = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetText(label .. ": " .. defaultVal)

    local slider = CreateFrame("Slider", name, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -20)
    slider:SetWidth(width or 400)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetValue(defaultVal)

    -- Hide default slider text
    local sliderName = slider:GetName()
    if sliderName then
        local lowText = PDS.Utils:GetGlobal(sliderName .. "Low")
        local highText = PDS.Utils:GetGlobal(sliderName .. "High")
        local valueText = PDS.Utils:GetGlobal(sliderName .. "Text")

        if lowText then lowText:SetText("") end
        if highText then highText:SetText("") end
        if valueText then valueText:SetText("") end
    end

    slider:SetScript("OnValueChanged", function(self, value)
        local roundedValue
        if step < 1 then
            -- For decimal values (like opacity 0-1)
            roundedValue = PDS.Utils:Round(value * (1 / step)) / (1 / step)
        else
            roundedValue = PDS.Utils:Round(value)
        end

        -- Format percentages
        if min == 0 and max == 1 then
            labelText:SetText(label .. ": " .. math.floor(roundedValue * 100) .. "%")
        else
            labelText:SetText(label .. ": " .. roundedValue)
        end

        -- Call the provided callback with the rounded value
        if callback then
            callback(roundedValue)
        end
    end)

    return container, slider, labelText
end

-- Creates a dropdown with standardized formatting
function Utils:CreateDropdown(parent, name, label, options, defaultOption, width, callback)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 400, 60)

    local labelText = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetText(label)

    local dropdown = CreateFrame("Frame", name, container, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 0, -20)
    UIDropDownMenu_SetWidth(dropdown, (width or 400) - 55)
    UIDropDownMenu_SetText(dropdown, defaultOption)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for value, text in pairs(options) do
            info.text = text
            info.checked = (value == defaultOption or text == defaultOption)
            info.func = function()
                UIDropDownMenu_SetText(dropdown, text)
                if callback then
                    callback(value)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    return container, dropdown, labelText
end

-- Creates a checkbox with standardized formatting - FIXED version
function Utils:CreateCheckbox(parent, name, label, x, y, checked, callback)
    local checkbox, newY = UI:CreateCheckbox(
        parent,
        name,
        label,
        x, -- Pass the x parameter explicitly
        y, -- Pass the y parameter explicitly
        checked,
        { 1, 1, 1 },
        function(self)
            if callback then
                callback(self:GetChecked())
            end
        end
    )

    return checkbox, newY -- Return both the checkbox and the new y position
end

-- Creates a section header with standardized formatting
function Utils:CreateSectionHeader(parent, text, indent, yPos, fontSize)
    local header, newY = UI:CreateSectionHeader(parent, text, indent, yPos)
    header:SetFont(header:GetFont(), fontSize or 18)
    return header, newY
end

-- Creates a subsection label with standardized formatting
function Utils:CreateSubsectionLabel(parent, text, indent, y)
    local label, newY = UI:CreateLabel(parent, text, indent, y, "GameFontNormalSmall")
    label:SetTextColor(0.9, 0.9, 0.9)
    return label, newY
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

    -- Create a container frame for better alignment of color picker and label
    local colorContainer = CreateFrame("Frame", nil, parent)
    colorContainer:SetSize(400, 30)
    colorContainer:SetPoint("TOPLEFT", indent, y)

    local colorLabel = colorContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colorLabel:SetPoint("LEFT", 0, 0)
    colorLabel:SetText("Bar Color:")

    local colorPicker = CreateFrame("Button", "PeaversStat" .. statType .. "ColorPicker", colorContainer,
        "BackdropTemplate")
    colorPicker:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
    colorPicker:SetSize(20, 20)
    colorPicker:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    colorPicker:SetBackdropColor(r, g, b)

    local colorText = colorContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    colorText:SetPoint("LEFT", colorPicker, "RIGHT", 10, 0)
    colorText:SetText("Change color")

    -- Create reset button
    local resetButton = CreateFrame("Button", "PeaversStat" .. statType .. "ResetButton", colorContainer,
        "UIPanelButtonTemplate")
    resetButton:SetSize(80, 20)
    resetButton:SetPoint("LEFT", colorText, "RIGHT", 15, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
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
    end)

    colorPicker:SetScript("OnClick", function()
        local function ColorCallback(restore)
            local newR, newG, newB
            if restore then
                newR, newG, newB = unpack(restore)
            else
                -- Get color using the latest API
                newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
            end

            colorPicker:SetBackdropColor(newR, newG, newB)

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
        end

        local r, g, b = colorPicker:GetBackdropColor()

        -- Set both func and swatchFunc for compatibility with different API versions
        ColorPickerFrame.func = ColorCallback
        ColorPickerFrame.swatchFunc = ColorCallback
        ColorPickerFrame.cancelFunc = ColorCallback
        ColorPickerFrame.opacityFunc = nil
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.previousValues = { r, g, b }

        -- Set color using the latest API
        ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)

        ColorPickerFrame:Hide() -- Hide first to trigger OnShow handler
        ColorPickerFrame:Show()
    end)

    return y - 35
end

-- Creates and initializes the options panel
function ConfigUI:InitializeOptions()
    if not UI then
        print("ERROR: UI module not loaded. Cannot initialize options.")
        return
    end

    local panel = CreateFrame("Frame")
    panel.name = "PeaversDynamicStats"

    local scrollFrame, content = UI:CreateScrollFrame(panel)
    local yPos = 0

    -- Golden ratio for spacing (approximately 1.618)
    local goldenRatio = 1.618
    local baseSpacing = 25
    local sectionSpacing = baseSpacing * goldenRatio -- ~40px

    -- Create header and description
    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", baseSpacing, yPos)
    title:SetText("Peavers Dynamic Stats")
    title:SetTextColor(1, 0.84, 0) -- Gold color for main title
    title:SetFont(title:GetFont(), 24, "OUTLINE")
    yPos = yPos - (baseSpacing * goldenRatio)

    local subtitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", baseSpacing, yPos)
    subtitle:SetText("Configuration options for the dynamic stats display")
    subtitle:SetFont(subtitle:GetFont(), 14)
    yPos = yPos - sectionSpacing

    -- Add a separator after the header
    local _, newY = UI:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - baseSpacing

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

    -- 4. TEXT SETTINGS SECTION
    yPos = self:CreateTextOptions(content, yPos, baseSpacing, sectionSpacing)

    -- Add a separator between major sections
    local _, newY = UI:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - baseSpacing

    -- 5. BEHAVIOR SETTINGS SECTION
    yPos = self:CreateBehaviorOptions(content, yPos, baseSpacing, sectionSpacing)

    -- Update content height based on the last element position
    content:SetHeight(math.abs(yPos) + 50)

    -- Register with the Interface Options using the latest API
	PDS.mainCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
	PDS.mainCategory.ID = panel.name
	Settings.RegisterAddOnCategory(PDS.mainCategory)

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
    local header, newY = Utils:CreateSectionHeader(content, "Display Settings", baseSpacing, yPos)
    yPos = newY - 10

    -- Frame dimensions subsection
    local dimensionsLabel, newY = Utils:CreateSubsectionLabel(content, "Frame Dimensions:", controlIndent, yPos)
    yPos = newY - 8

    -- Frame width slider
    local widthContainer, widthSlider = Utils:CreateSlider(
        content, "PeaversWidthSlider",
        "Frame Width", 50, 400, 10,
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
        "Background Opacity", 0, 1, 0.05,
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
    local visibilityLabel, newY = Utils:CreateSubsectionLabel(content, "Visibility Options:", controlIndent, yPos)
    yPos = newY - 8

    -- Show title bar checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversTitleBarCheckbox",
        "Show Title Bar", controlIndent, yPos,
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
        "Lock Frame Position", controlIndent, yPos,
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
        "Hide When Out of Combat", controlIndent, yPos,
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
        ["ALWAYS"] = "Always Show",
        ["PARTY_ONLY"] = "Show in Party Only",
        ["RAID_ONLY"] = "Show in Raid Only"
    }

    local currentDisplayMode = displayModeOptions[Config.displayMode] or "Always Show"

    local displayModeContainer, displayModeDropdown = Utils:CreateDropdown(
        content, "PeaversDisplayModeDropdown",
        "Display Mode", displayModeOptions,
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
    local header, newY = Utils:CreateSectionHeader(content, "Stat Options", baseSpacing, yPos)
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
            "Show " .. PDS.Stats:GetName(statType),
            indent, y,                           -- Pass x and y positions explicitly
            Config.showStats[statType] ~= false, -- Default to true
            onClick
        )
        return newY
    end

    -- PRIMARY STATS SECTION
    local primaryStatsHeader, newY = Utils:CreateSectionHeader(content, "Primary Stats", baseSpacing + 10, yPos, 16)
    yPos = newY - 5

    -- Add explanation about primary stats
    local primaryStatsExplanation = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    primaryStatsExplanation:SetPoint("TOPLEFT", baseSpacing + 15, yPos)
    primaryStatsExplanation:SetWidth(400)
    primaryStatsExplanation:SetJustifyH("LEFT")
    primaryStatsExplanation:SetText(
        "Primary stats are calculated as percentages, starting at 100% (base value). Buffs, talents, and equipment can increase these values beyond 100%. Higher percentages represent better performance.")

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
    local secondaryStatsHeader, newY = Utils:CreateSectionHeader(content, "Secondary Stats", baseSpacing + 10, yPos, 16)
    yPos = newY - 5

    -- Add explanation about secondary stats
    local secondaryStatsExplanation = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    secondaryStatsExplanation:SetPoint("TOPLEFT", baseSpacing + 15, yPos)
    secondaryStatsExplanation:SetWidth(400)
    secondaryStatsExplanation:SetJustifyH("LEFT")
    secondaryStatsExplanation:SetText(
        "Secondary stats enhance your character's performance: Crit, Haste, Mastery, Versatility, etc.")

    -- Calculate the height of the explanation text
    local explanationHeight = 40
    yPos = yPos - explanationHeight - 10

    -- Define secondary stats in the order they appear on WoW character screen
    local secondaryStats = {
        "CRIT", "HASTE", "MASTERY", "VERSATILITY",
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
    local header, newY = Utils:CreateSectionHeader(content, "Bar Appearance", baseSpacing, yPos)
    yPos = newY - 10

    -- Bar dimensions subsection
    local dimensionsLabel, newY = Utils:CreateSubsectionLabel(content, "Bar Dimensions:", controlIndent, yPos)
    yPos = newY - 8

    -- Initialize values with defaults if they don't exist
    if not Config.barHeight then Config.barHeight = 20 end
    if not Config.barSpacing then Config.barSpacing = 2 end
    if not Config.barAlpha then Config.barAlpha = 1 end
    if not Config.barBgAlpha then Config.barBgAlpha = 0.2 end

    -- Bar height slider
    local heightContainer, heightSlider = Utils:CreateSlider(
        content, "PeaversHeightSlider",
        "Bar Height", 10, 40, 1,
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
        "Bar Spacing", -5, 10, 1,
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

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 15

    -- Bar style subsection
    local styleLabel, newY = Utils:CreateSubsectionLabel(content, "Bar Style:", controlIndent, yPos)
    yPos = newY - 8

    -- Texture dropdown container
    local textures = Config:GetBarTextures()
    local currentTexture = textures[Config.barTexture] or "Default"

    local textureContainer, textureDropdown = Utils:CreateDropdown(
        content, "PeaversTextureDropdown",
        "Bar Texture", textures,
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
    local additionalLabel, newY = Utils:CreateSubsectionLabel(content, "Additional Bar Options:", controlIndent, yPos)
    yPos = newY - 8

    -- Initialize values with defaults if they don't exist
    if Config.showStatChanges == nil then Config.showStatChanges = true end
    if Config.showRatings == nil then Config.showRatings = true end
    if Config.showOverflowBars == nil then Config.showOverflowBars = true end

    -- Show stat changes checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversShowStatChangesCheckbox",
        "Show Stat Value Changes", controlIndent, yPos,
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
        "Show Rating Values", controlIndent, yPos,
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
        "Show Overflow Bars", controlIndent, yPos,
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

    return yPos
end

-- 4. TEXT SETTINGS - Font and text appearance settings
function ConfigUI:CreateTextOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local subControlIndent = controlIndent + 15
    local sliderWidth = 400

    -- Text Settings section header
    local header, newY = Utils:CreateSectionHeader(content, "Text Settings", baseSpacing, yPos)
    yPos = newY - 10

    -- Font selection subsection
    local fontSelectLabel, newY = Utils:CreateSubsectionLabel(content, "Font Selection:", controlIndent, yPos)
    yPos = newY - 8

    -- Initialize values with defaults if they don't exist
    if not Config.fontFace then Config.fontFace = "Fonts\\ARIALN.TTF" end
    if not Config.fontSize then Config.fontSize = 11 end
    if not Config.fontOutline then Config.fontOutline = "" end
    if not Config.fontShadow then Config.fontShadow = true end

    -- Font dropdown container
    local fonts = Config:GetFonts()
    local currentFont = fonts[Config.fontFace] or "Default"

    local fontContainer, fontDropdown = Utils:CreateDropdown(
        content, "PeaversFontDropdown",
        "Font", fonts,
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
        "Font Size", 6, 18, 1,
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
    local fontStyleLabel, newY = Utils:CreateSubsectionLabel(content, "Font Style:", controlIndent, yPos)
    yPos = newY - 8

    -- Font outline checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversFontOutlineCheckbox",
        "Outlined Font", controlIndent, yPos,
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
        "Font Shadow", controlIndent, yPos,
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

-- 5. BEHAVIOR SETTINGS - Sorting, grouping, and other behavioral settings
function ConfigUI:CreateBehaviorOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local subControlIndent = controlIndent + 15
    local sliderWidth = 400

    -- Behavior Settings section header
    local header, newY = Utils:CreateSectionHeader(content, "Behavior Settings", baseSpacing, yPos)
    yPos = newY - 10

    -- Initialize values with defaults if they don't exist
    if Config.showTooltips == nil then Config.showTooltips = true end
    if Config.enableStatHistory == nil then Config.enableStatHistory = true end
    if not Config.sortOption then Config.sortOption = "VALUE_DESC" end

    -- Tooltip and Stat Tracking
    local tooltipLabel, newY = Utils:CreateSubsectionLabel(content, "Tooltips and Tracking:", controlIndent, yPos)
    yPos = newY - 8

    -- Show tooltips checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversShowTooltipsCheckbox",
        "Show Enhanced Tooltips", controlIndent, yPos,
        Config.showTooltips,
        function(checked)
            Config.showTooltips = checked
            Config:Save()
        end
    )
    yPos = newY - 8 -- Update yPos for the next element

    -- Enable stat history tracking checkbox
    local _, newY = Utils:CreateCheckbox(
        content, "PeaversEnableStatHistoryCheckbox",
        "Enable Stat History Tracking", controlIndent, yPos,
        Config.enableStatHistory,
        function(checked)
            Config.enableStatHistory = checked
            Config:Save()
            -- Clear history data if disabled
            if not checked and PDS.StatHistory then
                PDS.StatHistory:Clear()
            end
        end
    )
    yPos = newY - 20 -- Update yPos for the next element

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)

    yPos = yPos - 65 -- Update yPos for the next element

    return yPos
end

-- Opens the configuration panel
function ConfigUI:OpenOptions()
    -- No need to initialize options panel here, it's already initialized in Main.lua
    Settings.OpenToCategory("PeaversDynamicStats")
end

-- Handler for the /pds config command
PDS.Config.OpenOptionsCommand = function()
    ConfigUI:OpenOptions()
end

return ConfigUI
