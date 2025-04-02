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

    -- Create header and description
    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 25, yPos)
    title:SetText("Peavers Dynamic Stats")
    yPos = yPos - 30

    local subtitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", 25, yPos)
    subtitle:SetText("Configuration options for the dynamic stats display")
    yPos = yPos - 40

    -- Create stat checkboxes
    yPos = self:CreateStatOptions(content, yPos)

    -- Create bar settings
    yPos = self:CreateBarOptions(content, yPos)

    -- Create visual settings
    yPos = self:CreateVisualOptions(content, yPos)

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

-- Creates stat checkboxes
function ConfigUI:CreateStatOptions(content, yPos)
    local function CreateStatCheckbox(statType, y)
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
            PDS.Stats:GetName(statType),
            25,
            y,
            Config.showStats[statType],
            { 1, 1, 1 },
            onClick
        )
    end

    -- General section
    local _, newY = UI:CreateSectionHeader(content, "General", 25, yPos)
    yPos = newY

    -- Stat checkboxes
    for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
        local _, newY = CreateStatCheckbox(statType, yPos)
        yPos = newY
    end

    return yPos - 25 -- Extra spacing between sections
end

-- Creates bar settings
function ConfigUI:CreateBarOptions(content, yPos)
    -- Bar Settings section
    local _, newY = UI:CreateSectionHeader(content, "Bar Settings", 25, yPos)
    yPos = newY

    -- Bar spacing slider
    local spacingLabel, newY = UI:CreateLabel(content, "Bar Spacing: " .. Config.barSpacing, 25, yPos)
    yPos = newY

    local spacingSlider, newY = UI:CreateSlider(
        content, "PeaversSpacingSlider", -5, 10, 1, 25, yPos, Config.barSpacing
    )
    yPos = newY

    spacingSlider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = PDS.Utils:Round(value)
        spacingLabel:SetText("Bar Spacing: " .. roundedValue)
        Config.barSpacing = roundedValue
        Config:Save()
        if PDS.Core and PDS.Core.CreateBars then
            PDS.Core:CreateBars()
        end
    end)

    -- Bar height slider
    local heightLabel, newY = UI:CreateLabel(content, "Bar Height: " .. Config.barHeight, 25, yPos)
    yPos = newY

    local heightSlider, newY = UI:CreateSlider(
        content, "PeaversHeightSlider", 10, 40, 1, 25, yPos, Config.barHeight
    )
    yPos = newY

    heightSlider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = PDS.Utils:Round(value)
        heightLabel:SetText("Bar Height: " .. roundedValue)
        Config.barHeight = roundedValue
        Config:Save()
        if PDS.Core and PDS.Core.CreateBars then
            PDS.Core:CreateBars()
        end
    end)

    -- Frame width slider
    local widthLabel, newY = UI:CreateLabel(content, "Frame Width: " .. Config.frameWidth, 25, yPos)
    yPos = newY

    local widthSlider, newY = UI:CreateSlider(
        content, "PeaversWidthSlider", 150, 400, 10, 25, yPos, Config.frameWidth
    )
    yPos = newY

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

    yPos = yPos - 10 -- Extra spacing between sections

    -- Bar background opacity slider
    local barBgOpacityLabel, newY = UI:CreateLabel(
            content,
            "Bar Background Opacity: " .. math.floor(Config.barBgAlpha * 100) .. "%",
            25,
            yPos
    )
    yPos = newY

    local barBgOpacitySlider, newY = UI:CreateSlider(
            content, "PeaversBarBgOpacitySlider", 0, 1, 0.05, 25, yPos, Config.barBgAlpha
    )
    yPos = newY

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

    return yPos
end

-- Creates visual settings
function ConfigUI:CreateVisualOptions(content, yPos)
    -- Visual Settings section
    local _, newY = UI:CreateSectionHeader(content, "Visual Settings", 25, yPos)
    yPos = newY

    -- Group 1: Layout controls
    local _, newY = UI:CreateLabel(content, "Layout Options:", 30, yPos, "GameFontNormalSmall")
    yPos = newY

    -- Show title bar checkbox
    local titleBarCheckbox, newY = UI:CreateCheckbox(
        content,
        "PeaversTitleBarCheckbox",
        "Show Title Bar",
        40,
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
        40,
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
    yPos = newY - 10 -- Extra spacing between control groups

    -- Group 2: Background settings
    local _, newY = UI:CreateLabel(content, "Background:", 30, yPos, "GameFontNormalSmall")
    yPos = newY

    -- Background opacity slider
    local opacityLabel, newY = UI:CreateLabel(
        content,
        "Opacity: " .. math.floor(Config.bgAlpha * 100) .. "%",
        40,
        yPos
    )
    yPos = newY

    local opacitySlider, newY = UI:CreateSlider(
        content, "PeaversOpacitySlider", 0, 1, 0.05, 40, yPos, Config.bgAlpha
    )
    yPos = newY

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
            if PDS.Core.titleBar then
                PDS.Core.titleBar:SetBackdropColor(
                    Config.bgColor.r,
                    Config.bgColor.g,
                    Config.bgColor.b,
                    Config.bgAlpha
                )
            end
        end
    end)
    yPos = newY - 10 -- Extra spacing between control groups

    -- Group 3: Font selection
    local _, newY = UI:CreateLabel(content, "Text Style:", 30, yPos, "GameFontNormalSmall")
    yPos = newY

    local fontLabel, newY = UI:CreateLabel(content, "Font", 40, yPos)
    yPos = newY

    local fonts = Config:GetFonts()
    local currentFont = fonts[Config.fontFace] or "Default"

    local fontDropdown, newY = UI:CreateDropdown(
        content, "PeaversFontDropdown", 40, yPos, 345, currentFont
    )
    yPos = newY

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
    yPos = newY - 10 -- Extra spacing between control groups

    -- Group 4: Bar texture
    local _, newY = UI:CreateLabel(content, "Bar Appearance:", 30, yPos, "GameFontNormalSmall")
    yPos = newY

    local textureLabel, newY = UI:CreateLabel(content, "Bar Texture", 40, yPos)
    yPos = newY

    local textures = Config:GetBarTextures()
    local currentTexture = textures[Config.barTexture] or "Default"

    local textureDropdown, newY = UI:CreateDropdown(
        content, "PeaversTextureDropdown", 40, yPos, 345, currentTexture
    )
    yPos = newY

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
