local _, PDS = ...

-- Initialize TemplateUI namespace
PDS.TemplateUI = {}
local TemplateUI = PDS.TemplateUI

-- Access PeaversCommons utilities
local PeaversCommons = _G.PeaversCommons
local ConfigUIUtils = PeaversCommons and PeaversCommons.ConfigUIUtils

-- Localization helper - uses PDS.L from Localization.lua
local function L(key)
    return PDS.L and PDS.L[key] or key
end

--------------------------------------------------------------------------------
-- Template Storage Functions
--------------------------------------------------------------------------------

-- Get the templates table from SavedVariables
local function GetTemplates()
    if not PeaversDynamicStatsDB then
        PeaversDynamicStatsDB = {}
    end
    if not PeaversDynamicStatsDB.templates then
        PeaversDynamicStatsDB.templates = {}
    end
    return PeaversDynamicStatsDB.templates
end

-- Save a template with the given name
function TemplateUI:SaveTemplate(name)
    if not name or name == "" then
        PDS.Utils.Print(L("TEMPLATE_ERROR_EMPTY_NAME"))
        return false
    end

    local templates = GetTemplates()

    -- Check for duplicate names
    if templates[name] then
        PDS.Utils.Print(L("TEMPLATE_ERROR_DUPLICATE"))
        return false
    end

    -- Get current settings from Config
    local config = PDS.Config
    if not config then
        PDS.Utils.Print(L("TEMPLATE_ERROR_NO_PROFILE"))
        return false
    end

    -- Create template data by copying current settings
    local templateData = {
        -- Frame settings
        frameWidth = config.frameWidth,
        framePoint = config.framePoint,
        frameX = config.frameX,
        frameY = config.frameY,
        lockPosition = config.lockPosition,

        -- Bar settings
        barWidth = config.barWidth,
        barHeight = config.barHeight,
        barSpacing = config.barSpacing,
        barBgAlpha = config.barBgAlpha,
        barAlpha = config.barAlpha,
        barTexture = config.barTexture,

        -- Visual settings
        fontFace = config.fontFace,
        fontSize = config.fontSize,
        fontOutline = config.fontOutline,
        fontShadow = config.fontShadow,
        bgAlpha = config.bgAlpha,
        bgColor = config.bgColor and {
            r = config.bgColor.r,
            g = config.bgColor.g,
            b = config.bgColor.b
        } or nil,

        -- Display settings
        showTitleBar = config.showTitleBar,
        showStats = config.showStats and PDS.Config.CopyTable and PDS.Config:CopyTable(config.showStats) or config.showStats,
        customColors = config.customColors and PDS.Config.CopyTable and PDS.Config:CopyTable(config.customColors) or config.customColors,
        showOverflowBars = config.showOverflowBars,
        showStatChanges = config.showStatChanges,
        showRatings = config.showRatings,
        hideOutOfCombat = config.hideOutOfCombat,
        enableTalentAdjustments = config.enableTalentAdjustments,

        -- Metadata
        createdAt = time(),
    }

    templates[name] = templateData
    PDS.Utils.Print(string.format(L("TEMPLATE_CREATED"), name))
    return true
end

-- Apply a template to current settings
function TemplateUI:ApplyTemplate(name)
    local templates = GetTemplates()
    local templateData = templates[name]

    if not templateData then
        PDS.Utils.Print(L("TEMPLATE_ERROR_NOT_FOUND"))
        return false
    end

    local config = PDS.Config
    if not config then
        PDS.Utils.Print(L("TEMPLATE_ERROR_NO_PROFILE"))
        return false
    end

    -- Apply template settings to config
    for key, value in pairs(templateData) do
        if key ~= "createdAt" then  -- Skip metadata
            if type(value) == "table" then
                config[key] = PDS.Config.CopyTable and PDS.Config:CopyTable(value) or value
            else
                config[key] = value
            end
        end
    end

    -- Save the updated config
    config:Save()

    -- Refresh the UI
    if PDS.Core and PDS.Core.frame then
        -- Update frame size and position
        PDS.Core.frame:SetWidth(config.frameWidth)
        PDS.Core.frame:ClearAllPoints()
        PDS.Core.frame:SetPoint(config.framePoint, config.frameX, config.frameY)

        -- Update backdrop
        PDS.Core.frame:SetBackdropColor(
            config.bgColor.r,
            config.bgColor.g,
            config.bgColor.b,
            config.bgAlpha
        )

        -- Update title bar visibility
        if PDS.Core.UpdateTitleBarVisibility then
            PDS.Core:UpdateTitleBarVisibility()
        end

        -- Update frame lock
        if PDS.Core.UpdateFrameLock then
            PDS.Core:UpdateFrameLock()
        end

        -- Recreate bars with new settings
        if PDS.BarManager and PDS.BarManager.CreateBars then
            PDS.BarManager:CreateBars(PDS.Core.contentFrame)
        end

        -- Adjust frame height
        if PDS.Core.AdjustFrameHeight then
            PDS.Core:AdjustFrameHeight()
        end
    end

    PDS.Utils.Print(string.format(L("TEMPLATE_APPLIED"), name))
    return true
end

-- Delete a template
function TemplateUI:DeleteTemplate(name)
    local templates = GetTemplates()

    if not templates[name] then
        PDS.Utils.Print(L("TEMPLATE_ERROR_NOT_FOUND"))
        return false
    end

    templates[name] = nil
    PDS.Utils.Print(string.format(L("TEMPLATE_DELETED"), name))
    return true
end

-- Rename a template
function TemplateUI:RenameTemplate(oldName, newName)
    if not newName or newName == "" then
        PDS.Utils.Print(L("TEMPLATE_ERROR_EMPTY_NAME"))
        return false
    end

    local templates = GetTemplates()

    if not templates[oldName] then
        PDS.Utils.Print(L("TEMPLATE_ERROR_NOT_FOUND"))
        return false
    end

    if templates[newName] then
        PDS.Utils.Print(L("TEMPLATE_ERROR_DUPLICATE"))
        return false
    end

    templates[newName] = templates[oldName]
    templates[oldName] = nil
    PDS.Utils.Print(string.format(L("TEMPLATE_RENAMED"), oldName, newName))
    return true
end

-- Get list of template names
function TemplateUI:GetTemplateNames()
    local templates = GetTemplates()
    local names = {}

    for name in pairs(templates) do
        table.insert(names, name)
    end

    table.sort(names)
    return names
end

--------------------------------------------------------------------------------
-- UI Creation
--------------------------------------------------------------------------------

-- Create the template management UI section
function TemplateUI:CreateTemplateManagementUI(content, yPos, baseSpacing, sectionSpacing)
    baseSpacing = baseSpacing or 25
    sectionSpacing = sectionSpacing or 40
    local controlIndent = baseSpacing + 15
    local dropdownWidth = 250

    -- Section header
    local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", baseSpacing, yPos)
    header:SetText(L("CONFIG_TEMPLATE_SETTINGS"))
    yPos = yPos - 25

    -- Description
    local desc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", baseSpacing + 10, yPos)
    desc:SetWidth(400)
    desc:SetJustifyH("LEFT")
    desc:SetText(L("CONFIG_TEMPLATE_DESC"))
    yPos = yPos - 50

    -- Create template section
    local createLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    createLabel:SetPoint("TOPLEFT", controlIndent, yPos)
    createLabel:SetText(L("CONFIG_CREATE_TEMPLATE"))
    yPos = yPos - 20

    -- Template name input
    local nameInput = CreateFrame("EditBox", "PDS_TemplateNameInput", content, "InputBoxTemplate")
    nameInput:SetSize(200, 20)
    nameInput:SetPoint("TOPLEFT", controlIndent, yPos)
    nameInput:SetAutoFocus(false)
    nameInput:SetMaxLetters(50)

    -- Create button
    local createBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    createBtn:SetSize(150, 22)
    createBtn:SetPoint("LEFT", nameInput, "RIGHT", 10, 0)
    createBtn:SetText(L("CONFIG_CREATE_TEMPLATE_BTN"))

    yPos = yPos - 35

    -- Templates selection section
    local listLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    listLabel:SetPoint("TOPLEFT", controlIndent, yPos)
    listLabel:SetText(L("CONFIG_MANAGE_TEMPLATES"))
    yPos = yPos - 25

    -- Track currently selected template
    local selectedTemplate = nil

    -- Create the dropdown frame
    local dropdownFrame = CreateFrame("Frame", "PDS_TemplateDropdown", content, "UIDropDownMenuTemplate")
    dropdownFrame:SetPoint("TOPLEFT", controlIndent - 15, yPos)
    UIDropDownMenu_SetWidth(dropdownFrame, dropdownWidth)

    -- No templates message (shown when dropdown is empty)
    local noTemplatesLabel = content:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    noTemplatesLabel:SetPoint("TOPLEFT", controlIndent, yPos - 5)
    noTemplatesLabel:SetText(L("CONFIG_NO_TEMPLATES"))
    noTemplatesLabel:Hide()

    yPos = yPos - 35

    -- Button container for Apply and Delete
    local buttonContainer = CreateFrame("Frame", nil, content)
    buttonContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    buttonContainer:SetSize(400, 25)

    -- Apply button
    local applyBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    applyBtn:SetSize(80, 22)
    applyBtn:SetPoint("LEFT", 0, 0)
    applyBtn:SetText(L("APPLY"))
    applyBtn:Disable()

    -- Delete button
    local deleteBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    deleteBtn:SetSize(80, 22)
    deleteBtn:SetPoint("LEFT", applyBtn, "RIGHT", 10, 0)
    deleteBtn:SetText(L("DELETE"))
    deleteBtn:Disable()

    -- Function to refresh the dropdown
    local function RefreshDropdown()
        local templates = self:GetTemplateNames()

        if #templates == 0 then
            dropdownFrame:Hide()
            noTemplatesLabel:Show()
            buttonContainer:Hide()
            selectedTemplate = nil
            applyBtn:Disable()
            deleteBtn:Disable()
        else
            dropdownFrame:Show()
            noTemplatesLabel:Hide()
            buttonContainer:Show()

            -- Check if selected template still exists
            local templateStillExists = false
            for _, name in ipairs(templates) do
                if name == selectedTemplate then
                    templateStillExists = true
                    break
                end
            end

            if not templateStillExists then
                selectedTemplate = templates[1]
            end

            -- Update buttons state
            if selectedTemplate then
                applyBtn:Enable()
                deleteBtn:Enable()
            else
                applyBtn:Disable()
                deleteBtn:Disable()
            end
        end

        -- Initialize the dropdown
        UIDropDownMenu_Initialize(dropdownFrame, function(self, level)
            local templates = TemplateUI:GetTemplateNames()

            for _, name in ipairs(templates) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.value = name
                info.func = function(self)
                    selectedTemplate = self.value
                    UIDropDownMenu_SetSelectedValue(dropdownFrame, self.value)
                    UIDropDownMenu_SetText(dropdownFrame, self.value)
                    applyBtn:Enable()
                    deleteBtn:Enable()
                end
                info.checked = (name == selectedTemplate)
                UIDropDownMenu_AddButton(info, level)
            end
        end)

        -- Set the selected value
        if selectedTemplate then
            UIDropDownMenu_SetSelectedValue(dropdownFrame, selectedTemplate)
            UIDropDownMenu_SetText(dropdownFrame, selectedTemplate)
        else
            UIDropDownMenu_SetText(dropdownFrame, "")
        end
    end

    -- Apply button click handler
    applyBtn:SetScript("OnClick", function()
        if selectedTemplate then
            StaticPopupDialogs["PDS_APPLY_TEMPLATE"] = {
                text = string.format(L("TEMPLATE_APPLY_CONFIRM"), selectedTemplate),
                button1 = L("APPLY"),
                button2 = L("CANCEL"),
                OnAccept = function()
                    TemplateUI:ApplyTemplate(selectedTemplate)
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("PDS_APPLY_TEMPLATE")
        end
    end)

    -- Delete button click handler
    deleteBtn:SetScript("OnClick", function()
        if selectedTemplate then
            local templateToDelete = selectedTemplate
            StaticPopupDialogs["PDS_DELETE_TEMPLATE"] = {
                text = string.format(L("TEMPLATE_DELETE_CONFIRM"), templateToDelete),
                button1 = L("DELETE"),
                button2 = L("CANCEL"),
                OnAccept = function()
                    if TemplateUI:DeleteTemplate(templateToDelete) then
                        selectedTemplate = nil
                        RefreshDropdown()
                    end
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("PDS_DELETE_TEMPLATE")
        end
    end)

    -- Set up create button click handler
    createBtn:SetScript("OnClick", function()
        local templateName = nameInput:GetText()
        if templateName and templateName ~= "" then
            if self:SaveTemplate(templateName) then
                nameInput:SetText("")
                selectedTemplate = templateName
                RefreshDropdown()
            end
        else
            PDS.Utils.Print(L("TEMPLATE_ERROR_EMPTY_NAME"))
        end
    end)

    -- Enter key creates template
    nameInput:SetScript("OnEnterPressed", function()
        createBtn:Click()
    end)

    -- Initial population
    RefreshDropdown()

    yPos = yPos - 30

    return yPos
end

-- Initialize the template UI
function TemplateUI:Initialize()
    -- Ensure templates table exists in SavedVariables
    GetTemplates()
end

return TemplateUI
