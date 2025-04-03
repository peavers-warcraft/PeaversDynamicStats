local _, PDS = ...
local Config = PDS.Config
local UI = PDS.UI
local ConfigUI = {}

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

    -- Create stat checkboxes
    yPos = self:CreateStatOptions(content, yPos, baseSpacing, sectionSpacing)

    -- Add a separator between major sections
    local _, newY = UI:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - baseSpacing

    -- Create bar settings
    yPos = self:CreateBarOptions(content, yPos, baseSpacing, sectionSpacing)

    -- Add a separator between major sections
    local _, newY = UI:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - baseSpacing

    -- Create visual settings
    yPos = self:CreateVisualOptions(content, yPos, baseSpacing, sectionSpacing)

    -- Update content height based on the last element position
    content:SetHeight(math.abs(yPos) + 50)

    -- Register with the Interface Options
    if Settings and Settings.RegisterCanvasLayoutCategory then
        Config.categoryID = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(Config.categoryID)
    else
        InterfaceOptions_AddCategory(panel)
    end

    return panel
end

-- Creates individual stat sections with configuration options
function ConfigUI:CreateStatOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40

    -- Main section header
    local header, newY = UI:CreateSectionHeader(content, "Stat Options", baseSpacing, yPos)
    header:SetFont(header:GetFont(), 18)
    yPos = newY - 10

    -- Function to create a show/hide checkbox for a stat
    local function CreateStatCheckbox(statType, y, indent)
        local onClick = function(self)
            Config.showStats[statType] = self:GetChecked()
            Config:Save()
            if PDS.Core and PDS.Core.CreateBars then
                PDS.Core:CreateBars()
            end
        end

        return UI:CreateCheckbox(
            content,
            "PeaversStat" .. statType .. "Checkbox",
            "Show " .. PDS.Stats:GetName(statType),
            indent,
            y,
            Config.showStats[statType],
            { 1, 1, 1 },
            onClick
        )
    end

    -- Create a section for each stat
    for i, statType in ipairs(PDS.Stats.STAT_ORDER) do
        -- Create subsection header with stat name
        local statHeader, newY = UI:CreateSectionHeader(content, PDS.Stats:GetName(statType), baseSpacing + 10, yPos)
        statHeader:SetFont(statHeader:GetFont(), 14) -- Smaller sub-headings
        yPos = newY

        -- Show/hide checkbox
        local _, newY = CreateStatCheckbox(statType, yPos, baseSpacing + 25)
        yPos = newY

        -- Color picker
        local r, g, b
        -- Use custom color if available, otherwise use default
        if Config.customColors[statType] then
            local color = Config.customColors[statType]
            r, g, b = color.r, color.g, color.b
        else
            r, g, b = PDS.Stats:GetColor(statType)
        end

        -- Create a container frame for better alignment of color picker and label
        local colorContainer = CreateFrame("Frame", nil, content)
        colorContainer:SetSize(400, 30)
        colorContainer:SetPoint("TOPLEFT", baseSpacing + 25, yPos)

        local colorLabel = colorContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        colorLabel:SetPoint("LEFT", 0, 0)
        colorLabel:SetText("Bar Color:")

        local colorPicker = CreateFrame("Button", "PeaversStat" .. statType .. "ColorPicker", colorContainer, "BackdropTemplate")
        colorPicker:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
        colorPicker:SetSize(20, 20)
        colorPicker:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        colorPicker:SetBackdropColor(r, g, b)

        local colorText = colorContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        colorText:SetPoint("LEFT", colorPicker, "RIGHT", 10, 0)
        colorText:SetText("Change color")

        -- Create reset button
        local resetButton = CreateFrame("Button", "PeaversStat" .. statType .. "ResetButton", colorContainer, "UIPanelButtonTemplate")
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

            -- Update all bars if they exist
            if PDS.Core and PDS.Core.bars then
                for _, bar in ipairs(PDS.Core.bars) do
                    if bar.statType == statType then
                        bar:UpdateColor()
                    end
                end
            end
        end)

        colorPicker:SetScript("OnClick", function()
            local function ColorCallback(restore)
                local newR, newG, newB
                if restore then
                    newR, newG, newB = unpack(restore)
                else
                    -- Handle different API versions for getting color
                    if ColorPickerFrame.GetColorRGB then
                        newR, newG, newB = ColorPickerFrame:GetColorRGB()
                    elseif ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.GetColorRGB then
                        newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
                    else
                        -- Fallback to stored values if API methods aren't available
                        newR, newG, newB = colorPicker:GetBackdropColor()
                    end
                end

                colorPicker:SetBackdropColor(newR, newG, newB)

                -- Save the custom color
                Config.customColors[statType] = {r = newR, g = newG, b = newB}
                Config:Save()

                -- Update all bars if they exist
                if PDS.Core and PDS.Core.bars then
                    for _, bar in ipairs(PDS.Core.bars) do
                        if bar.statType == statType then
                            bar:UpdateColor()
                        end
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

            -- Handle different API versions for setting color
            if ColorPickerFrame.SetColorRGB then
                ColorPickerFrame:SetColorRGB(r, g, b)
            elseif ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.SetColorRGB then
                ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
            end

            ColorPickerFrame:Hide() -- Hide first to trigger OnShow handler
            ColorPickerFrame:Show()
        end)

        yPos = yPos - 35

        -- Add a thin separator between stats (except after the last one)
        if i < #PDS.Stats.STAT_ORDER then
            local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
            yPos = newY - 5
        end
    end

    return yPos - 15 -- Extra spacing after all stat sections
end

-- Creates bar settings
function ConfigUI:CreateBarOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local sliderWidth = 400

    -- Bar Settings section header
    local header, newY = UI:CreateSectionHeader(content, "Bar Settings", baseSpacing, yPos)
    header:SetFont(header:GetFont(), 18)
    yPos = newY - 10

    -- Create a container for dimensions settings
    local dimensionsLabel, newY = UI:CreateLabel(content, "Dimensions:", controlIndent, yPos, "GameFontNormalSmall")
    dimensionsLabel:SetTextColor(0.9, 0.9, 0.9)
    yPos = newY - 5

    -- Bar spacing slider
    local spacingContainer = CreateFrame("Frame", nil, content)
    spacingContainer:SetSize(sliderWidth, 50)
    spacingContainer:SetPoint("TOPLEFT", controlIndent, yPos)

    local spacingLabel = spacingContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    spacingLabel:SetPoint("TOPLEFT", 0, 0)
    spacingLabel:SetText("Bar Spacing: " .. Config.barSpacing)

    local spacingSlider = CreateFrame("Slider", "PeaversSpacingSlider", spacingContainer, "OptionsSliderTemplate")
    spacingSlider:SetPoint("TOPLEFT", 0, -20)
    spacingSlider:SetWidth(sliderWidth)
    spacingSlider:SetMinMaxValues(-5, 10)
    spacingSlider:SetValueStep(1)
    spacingSlider:SetValue(Config.barSpacing)

    -- Hide default slider text
    local sliderName = spacingSlider:GetName()
    if sliderName then
        local lowText = PDS.Utils:GetGlobal(sliderName .. "Low")
        local highText = PDS.Utils:GetGlobal(sliderName .. "High")
        local valueText = PDS.Utils:GetGlobal(sliderName .. "Text")

        if lowText then lowText:SetText("") end
        if highText then highText:SetText("") end
        if valueText then valueText:SetText("") end
    end

    spacingSlider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = PDS.Utils:Round(value)
        spacingLabel:SetText("Bar Spacing: " .. roundedValue)
        Config.barSpacing = roundedValue
        Config:Save()
        if PDS.Core and PDS.Core.CreateBars then
            PDS.Core:CreateBars()
        end
    end)

    yPos = yPos - 55

    -- Bar height slider
    local heightContainer = CreateFrame("Frame", nil, content)
    heightContainer:SetSize(sliderWidth, 50)
    heightContainer:SetPoint("TOPLEFT", controlIndent, yPos)

    local heightLabel = heightContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    heightLabel:SetPoint("TOPLEFT", 0, 0)
    heightLabel:SetText("Bar Height: " .. Config.barHeight)

    local heightSlider = CreateFrame("Slider", "PeaversHeightSlider", heightContainer, "OptionsSliderTemplate")
    heightSlider:SetPoint("TOPLEFT", 0, -20)
    heightSlider:SetWidth(sliderWidth)
    heightSlider:SetMinMaxValues(10, 40)
    heightSlider:SetValueStep(1)
    heightSlider:SetValue(Config.barHeight)

    -- Hide default slider text
    local sliderName = heightSlider:GetName()
    if sliderName then
        local lowText = PDS.Utils:GetGlobal(sliderName .. "Low")
        local highText = PDS.Utils:GetGlobal(sliderName .. "High")
        local valueText = PDS.Utils:GetGlobal(sliderName .. "Text")

        if lowText then lowText:SetText("") end
        if highText then highText:SetText("") end
        if valueText then valueText:SetText("") end
    end

    heightSlider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = PDS.Utils:Round(value)
        heightLabel:SetText("Bar Height: " .. roundedValue)
        Config.barHeight = roundedValue
        Config:Save()
        if PDS.Core and PDS.Core.CreateBars then
            PDS.Core:CreateBars()
        end
    end)

    yPos = yPos - 55

    -- Frame width slider
    local widthContainer = CreateFrame("Frame", nil, content)
    widthContainer:SetSize(sliderWidth, 50)
    widthContainer:SetPoint("TOPLEFT", controlIndent, yPos)

    local widthLabel = widthContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    widthLabel:SetPoint("TOPLEFT", 0, 0)
    widthLabel:SetText("Frame Width: " .. Config.frameWidth)

    local widthSlider = CreateFrame("Slider", "PeaversWidthSlider", widthContainer, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", 0, -20)
    widthSlider:SetWidth(sliderWidth)
    widthSlider:SetMinMaxValues(150, 400)
    widthSlider:SetValueStep(10)
    widthSlider:SetValue(Config.frameWidth)

    -- Hide default slider text
    local sliderName = widthSlider:GetName()
    if sliderName then
        local lowText = PDS.Utils:GetGlobal(sliderName .. "Low")
        local highText = PDS.Utils:GetGlobal(sliderName .. "High")
        local valueText = PDS.Utils:GetGlobal(sliderName .. "Text")

        if lowText then lowText:SetText("") end
        if highText then highText:SetText("") end
        if valueText then valueText:SetText("") end
    end

    widthSlider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = PDS.Utils:Round(value / 10) * 10
        widthLabel:SetText("Frame Width: " .. roundedValue)
        Config.frameWidth = roundedValue
        Config.barWidth = roundedValue - 20
        Config:Save()
        if PDS.Core and PDS.Core.frame then
            PDS.Core.frame:SetWidth(roundedValue)
            if PDS.Core.bars then
                for _, bar in ipairs(PDS.Core.bars) do
                    bar:UpdateWidth()
                end
            end
        end
    end)

    yPos = yPos - 55

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 10

    -- Create a container for appearance settings
    local appearanceLabel, newY = UI:CreateLabel(content, "Appearance:", controlIndent, yPos, "GameFontNormalSmall")
    appearanceLabel:SetTextColor(0.9, 0.9, 0.9)
    yPos = newY - 5

    -- Bar background opacity slider
    local barBgOpacityContainer = CreateFrame("Frame", nil, content)
    barBgOpacityContainer:SetSize(sliderWidth, 50)
    barBgOpacityContainer:SetPoint("TOPLEFT", controlIndent, yPos)

    local barBgOpacityLabel = barBgOpacityContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    barBgOpacityLabel:SetPoint("TOPLEFT", 0, 0)
    barBgOpacityLabel:SetText("Bar Background Opacity: " .. math.floor(Config.barBgAlpha * 100) .. "%")

    local barBgOpacitySlider = CreateFrame("Slider", "PeaversBarBgOpacitySlider", barBgOpacityContainer, "OptionsSliderTemplate")
    barBgOpacitySlider:SetPoint("TOPLEFT", 0, -20)
    barBgOpacitySlider:SetWidth(sliderWidth)
    barBgOpacitySlider:SetMinMaxValues(0, 1)
    barBgOpacitySlider:SetValueStep(0.05)
    barBgOpacitySlider:SetValue(Config.barBgAlpha)

    -- Hide default slider text
    local sliderName = barBgOpacitySlider:GetName()
    if sliderName then
        local lowText = PDS.Utils:GetGlobal(sliderName .. "Low")
        local highText = PDS.Utils:GetGlobal(sliderName .. "High")
        local valueText = PDS.Utils:GetGlobal(sliderName .. "Text")

        if lowText then lowText:SetText("") end
        if highText then highText:SetText("") end
        if valueText then valueText:SetText("") end
    end

    barBgOpacitySlider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = PDS.Utils:Round(value * 20) / 20
        barBgOpacityLabel:SetText("Bar Background Opacity: " .. math.floor(roundedValue * 100) .. "%")
        Config.barBgAlpha = roundedValue
        Config:Save()
        if PDS.Core and PDS.Core.bars then
            for _, bar in ipairs(PDS.Core.bars) do
                bar:UpdateBackgroundOpacity()
            end
        end
    end)

    yPos = yPos - 55

    return yPos
end

-- Creates visual settings
function ConfigUI:CreateVisualOptions(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local subControlIndent = controlIndent + 15

    -- Visual Settings section header
    local header, newY = UI:CreateSectionHeader(content, "Visual Settings", baseSpacing, yPos)
    header:SetFont(header:GetFont(), 18)
    yPos = newY - 10

    -- Group 1: Layout controls
    local layoutLabel, newY = UI:CreateLabel(content, "Layout Options:", controlIndent, yPos, "GameFontNormalSmall")
    layoutLabel:SetTextColor(0.9, 0.9, 0.9)
    yPos = newY - 5

    -- Show title bar checkbox
    local titleBarCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversTitleBarCheckbox",
        "Show Title Bar",
        subControlIndent,
        yPos,
        Config.showTitleBar,
        { 1, 1, 1 },
        function(self)
            Config.showTitleBar = self:GetChecked()
            Config:Save()
            if PDS.Core then
                PDS.Core:UpdateTitleBarVisibility()
            end
        end
    )
    yPos = newY

    -- Lock position checkbox
    local lockPositionCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversLockPositionCheckbox",
        "Lock Frame Position",
        subControlIndent,
        yPos,
        Config.lockPosition,
        { 1, 1, 1 },
        function(self)
            Config.lockPosition = self:GetChecked()
            Config:Save()
            if PDS.Core then
                PDS.Core:UpdateFrameLock()
            end
        end
    )
    yPos = newY - 10

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 10

    -- Group 2: Background settings
    local bgLabel, newY = UI:CreateLabel(content, "Background:", controlIndent, yPos, "GameFontNormalSmall")
    bgLabel:SetTextColor(0.9, 0.9, 0.9)
    yPos = newY - 5

    -- Background opacity slider
    local opacityContainer = CreateFrame("Frame", nil, content)
    opacityContainer:SetSize(400, 50)
    opacityContainer:SetPoint("TOPLEFT", subControlIndent, yPos)

    local opacityLabel = opacityContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    opacityLabel:SetPoint("TOPLEFT", 0, 0)
    opacityLabel:SetText("Opacity: " .. math.floor(Config.bgAlpha * 100) .. "%")

    local opacitySlider = CreateFrame("Slider", "PeaversOpacitySlider", opacityContainer, "OptionsSliderTemplate")
    opacitySlider:SetPoint("TOPLEFT", 0, -20)
    opacitySlider:SetWidth(400)
    opacitySlider:SetMinMaxValues(0, 1)
    opacitySlider:SetValueStep(0.05)
    opacitySlider:SetValue(Config.bgAlpha)

    -- Hide default slider text
    local sliderName = opacitySlider:GetName()
    if sliderName then
        local lowText = PDS.Utils:GetGlobal(sliderName .. "Low")
        local highText = PDS.Utils:GetGlobal(sliderName .. "High")
        local valueText = PDS.Utils:GetGlobal(sliderName .. "Text")

        if lowText then lowText:SetText("") end
        if highText then highText:SetText("") end
        if valueText then valueText:SetText("") end
    end

    opacitySlider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = PDS.Utils:Round(value * 20) / 20
        opacityLabel:SetText("Opacity: " .. math.floor(roundedValue * 100) .. "%")
        Config.bgAlpha = roundedValue
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
    end)

    yPos = yPos - 55

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 10

    -- Group 3: Font selection
    local textStyleLabel, newY = UI:CreateLabel(content, "Text Style:", controlIndent, yPos, "GameFontNormalSmall")
    textStyleLabel:SetTextColor(0.9, 0.9, 0.9)
    yPos = newY - 5

    -- Font dropdown container
    local fontContainer = CreateFrame("Frame", nil, content)
    fontContainer:SetSize(400, 60)
    fontContainer:SetPoint("TOPLEFT", subControlIndent, yPos)

    local fontLabel = fontContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", 0, 0)
    fontLabel:SetText("Font")

    local fonts = Config:GetFonts()
    local currentFont = fonts[Config.fontFace] or "Default"

    local fontDropdown = CreateFrame("Frame", "PeaversFontDropdown", fontContainer, "UIDropDownMenuTemplate")
    fontDropdown:SetPoint("TOPLEFT", 0, -20)
    UIDropDownMenu_SetWidth(fontDropdown, 345)
    UIDropDownMenu_SetText(fontDropdown, currentFont)

    UIDropDownMenu_Initialize(fontDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for path, name in pairs(fonts) do
            info.text = name
            info.checked = (path == Config.fontFace)
            info.func = function()
                Config.fontFace = path
                UIDropDownMenu_SetText(fontDropdown, name)
                Config:Save()
                if PDS.Core and PDS.Core.CreateBars then
                    PDS.Core:CreateBars()
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    yPos = yPos - 65

    -- Font outline checkbox
    local outlineCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversFontOutlineCheckbox",
        "Outlined Font",
        subControlIndent,
        yPos,
        Config.fontOutline == "OUTLINE",
        { 1, 1, 1 },
        function(self)
            Config.fontOutline = self:GetChecked() and "OUTLINE" or ""
            Config:Save()
            if PDS.Core and PDS.Core.CreateBars then
                PDS.Core:CreateBars()
            end
        end
    )
    yPos = newY - 10

    -- Font shadow checkbox
    local shadowCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversFontShadowCheckbox",
        "Font Shadow",
        subControlIndent,
        yPos,
        Config.fontShadow,
        { 1, 1, 1 },
        function(self)
            Config.fontShadow = self:GetChecked()
            Config:Save()
            if PDS.Core and PDS.Core.CreateBars then
                PDS.Core:CreateBars()
            end
        end
    )
    yPos = newY - 10

    -- Font size slider
    local fontSizeContainer = CreateFrame("Frame", nil, content)
    fontSizeContainer:SetSize(400, 50)
    fontSizeContainer:SetPoint("TOPLEFT", subControlIndent, yPos)

    local fontSizeLabel = fontSizeContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontSizeLabel:SetPoint("TOPLEFT", 0, 0)
    fontSizeLabel:SetText("Font Size: " .. Config.fontSize)

    local fontSizeSlider = CreateFrame("Slider", "PeaversFontSizeSlider", fontSizeContainer, "OptionsSliderTemplate")
    fontSizeSlider:SetPoint("TOPLEFT", 0, -20)
    fontSizeSlider:SetWidth(400)
    fontSizeSlider:SetMinMaxValues(6, 18)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetValue(Config.fontSize)

    -- Hide default slider text
    local sliderName = fontSizeSlider:GetName()
    if sliderName then
        local lowText = PDS.Utils:GetGlobal(sliderName .. "Low")
        local highText = PDS.Utils:GetGlobal(sliderName .. "High")
        local valueText = PDS.Utils:GetGlobal(sliderName .. "Text")

        if lowText then lowText:SetText("") end
        if highText then highText:SetText("") end
        if valueText then valueText:SetText("") end
    end

    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = math.floor(value + 0.5)
        fontSizeLabel:SetText("Font Size: " .. roundedValue)
        Config.fontSize = roundedValue
        Config:Save()
        if PDS.Core and PDS.Core.CreateBars then
            PDS.Core:CreateBars()
        end
    end)

    yPos = yPos - 65

    -- Add a thin separator
    local _, newY = UI:CreateSeparator(content, baseSpacing + 15, yPos, 400)
    yPos = newY - 10

    -- Group 4: Bar texture
    local barAppLabel, newY = UI:CreateLabel(content, "Bar Appearance:", controlIndent, yPos, "GameFontNormalSmall")
    barAppLabel:SetTextColor(0.9, 0.9, 0.9)
    yPos = newY - 5

    -- Texture dropdown container
    local textureContainer = CreateFrame("Frame", nil, content)
    textureContainer:SetSize(400, 60)
    textureContainer:SetPoint("TOPLEFT", subControlIndent, yPos)

    local textureLabel = textureContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    textureLabel:SetPoint("TOPLEFT", 0, 0)
    textureLabel:SetText("Bar Texture")

    local textures = Config:GetBarTextures()
    local currentTexture = textures[Config.barTexture] or "Default"

    local textureDropdown = CreateFrame("Frame", "PeaversTextureDropdown", textureContainer, "UIDropDownMenuTemplate")
    textureDropdown:SetPoint("TOPLEFT", 0, -20)
    UIDropDownMenu_SetWidth(textureDropdown, 345)
    UIDropDownMenu_SetText(textureDropdown, currentTexture)

    UIDropDownMenu_Initialize(textureDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for path, name in pairs(textures) do
            info.text = name
            info.checked = (path == Config.barTexture)
            info.func = function()
                Config.barTexture = path
                UIDropDownMenu_SetText(textureDropdown, name)
                Config:Save()
                if PDS.Core and PDS.Core.bars then
                    for _, bar in ipairs(PDS.Core.bars) do
                        bar:UpdateTexture()
                    end
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    yPos = yPos - 65

    -- Show stat changes checkbox
    local showStatChangesCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversShowStatChangesCheckbox",
        "Show Stat Value Changes",
        subControlIndent,
        yPos,
        Config.showStatChanges,
        { 1, 1, 1 },
        function(self)
            Config.showStatChanges = self:GetChecked()
            Config:Save()
            if PDS.Core and PDS.Core.CreateBars then
                PDS.Core:CreateBars()
            end
        end
    )
    yPos = newY - 10

    -- Show ratings checkbox
    local showRatingsCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversShowRatingsCheckbox",
        "Show Rating Values",
        subControlIndent,
        yPos,
        Config.showRatings,
        { 1, 1, 1 },
        function(self)
            Config.showRatings = self:GetChecked()
            Config:Save()
            if PDS.Core and PDS.Core.CreateBars then
                PDS.Core:CreateBars()
            end
        end
    )
    yPos = newY - 10

    -- Show overflow bars checkbox
    local showOverflowBarsCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversShowOverflowBarsCheckbox",
        "Show Overflow Bars",
        subControlIndent,
        yPos,
        Config.showOverflowBars,
        { 1, 1, 1 },
        function(self)
            Config.showOverflowBars = self:GetChecked()
            Config:Save()
            if PDS.Core and PDS.Core.CreateBars then
                PDS.Core:CreateBars()
            end
        end
    )
    yPos = newY - 10

    -- Show tooltips checkbox
    local showTooltipsCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversShowTooltipsCheckbox",
        "Show Enhanced Tooltips",
        subControlIndent,
        yPos,
        Config.showTooltips,
        { 1, 1, 1 },
        function(self)
            Config.showTooltips = self:GetChecked()
            Config:Save()
        end
    )
    yPos = newY - 10

    -- Enable stat history tracking checkbox
    local enableStatHistoryCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversEnableStatHistoryCheckbox",
        "Enable Stat History Tracking",
        subControlIndent,
        yPos,
        Config.enableStatHistory,
        { 1, 1, 1 },
        function(self)
            Config.enableStatHistory = self:GetChecked()
            Config:Save()
            -- Clear history data if disabled
            if not self:GetChecked() and PDS.StatHistory then
                PDS.StatHistory:Clear()
            end
        end
    )
    yPos = newY - 10

    return yPos
end

-- Opens the configuration panel
function ConfigUI:OpenOptions()
    -- No need to initialize options panel here, it's already initialized in Main.lua
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory("PeaversDynamicStats")
    else
        InterfaceOptionsFrame_OpenToCategory("PeaversDynamicStats")
        InterfaceOptionsFrame_OpenToCategory("PeaversDynamicStats")
    end
end

-- Attach the ConfigUI to the Config namespace
PDS.Config.UI = ConfigUI

-- Handler for the /pds config command
PDS.Config.OpenOptionsCommand = function()
    ConfigUI:OpenOptions()
end

return ConfigUI
