local addonName, PDS = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons

-- Initialize addon namespace and modules
PDS = PDS or {}

-- Module namespaces
PDS.Core = {}
PDS.UI = {}
PDS.Utils = {}
PDS.Config = {}
PDS.Stats = {}

-- Version information
local function getAddOnMetadata(name, key)
    return C_AddOns.GetAddOnMetadata(name, key)
end

PDS.version = getAddOnMetadata(addonName, "Version") or "1.0.5"
PDS.addonName = addonName
PDS.name = addonName

-- Function to toggle the stats display
function ToggleStatsDisplay()
    if PDS.Core.frame:IsShown() then
        PDS.Core.frame:Hide()
    else
        PDS.Core.frame:Show()
    end
end

-- Make the function globally accessible
_G.ToggleStatsDisplay = ToggleStatsDisplay

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "pds", {
    default = function()
        ToggleStatsDisplay()
    end,
})

-- Initialize addon using the PeaversCommons Events module
PeaversCommons.Events:Init(addonName, function()
    -- Initialize configuration
    PDS.Config:Initialize()

    -- Initialize configuration UI
    if PDS.ConfigUI and PDS.ConfigUI.Initialize then
        PDS.ConfigUI:Initialize()
    end

    -- Initialize support UI
    if PDS.SupportUI and PDS.SupportUI.Initialize then
        PDS.SupportUI:Initialize()
    end

    -- Initialize core components
    PDS.Core:Initialize()

    -- Register event handlers
    PeaversCommons.Events:RegisterEvent("UNIT_STATS", function()
        PDS.BarManager:UpdateAllBars()
    end)

    PeaversCommons.Events:RegisterEvent("UNIT_AURA", function()
        PDS.BarManager:UpdateAllBars()
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function()
        PDS.BarManager:UpdateAllBars()
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        PDS.BarManager:UpdateAllBars()
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        PDS.Core.inCombat = true
        -- Always show the frame when entering combat if hideOutOfCombat is enabled
        if PDS.Config.hideOutOfCombat then
            PDS.Core.frame:Show()
        end
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        PDS.Core.inCombat = false
        -- Hide the frame when leaving combat if hideOutOfCombat is enabled
        if PDS.Config.hideOutOfCombat then
            PDS.Core.frame:Hide()
        end
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_LOGOUT", function()
        PDS.Config:Save()
    end)

    -- Set up OnUpdate handler for stats
    PeaversCommons.Events:RegisterOnUpdate(0.5, function(elapsed)
        local interval = PDS.Core.inCombat and PDS.Config.combatUpdateInterval or 2.0
        PDS.BarManager:UpdateAllBars()

        -- Record stat history if the module is available
        if PDS.StatHistory then
            PDS.StatHistory:RecordStats()
        end
    end, "PDS_Update")

    -- DIRECT REGISTRATION APPROACH
    -- This ensures the addon appears in Options > Addons regardless of PeaversCommons logic
    C_Timer.After(0.5, function()
        -- Create the main panel (Support UI as landing page)
        local mainPanel = CreateFrame("Frame")
        mainPanel.name = "PeaversDynamicStats"

        -- Required callbacks
        mainPanel.OnRefresh = function() end
        mainPanel.OnCommit = function() end
        mainPanel.OnDefault = function() end

        -- Get addon version
        local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

        -- Add background image
        local ICON_ALPHA = 0.1
        local iconPath = "Interface\\AddOns\\PeaversCommons\\src\\Media\\Icon"
        local largeIcon = mainPanel:CreateTexture(nil, "BACKGROUND")
        largeIcon:SetTexture(iconPath)
        largeIcon:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 0, 0)
        largeIcon:SetPoint("BOTTOMRIGHT", mainPanel, "BOTTOMRIGHT", 0, 0)
        largeIcon:SetAlpha(ICON_ALPHA)

        -- Create header and description
        local titleText = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        titleText:SetPoint("TOPLEFT", 16, -16)
        titleText:SetText("Peavers Dynamic Stats")
        titleText:SetTextColor(1, 0.84, 0)  -- Gold color for title

        -- Version information
        local versionText = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        versionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -8)
        versionText:SetText("Version: " .. version)

        -- Support information
        local supportInfo = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        supportInfo:SetPoint("TOPLEFT", 16, -70)
        supportInfo:SetPoint("TOPRIGHT", -16, -70)
        supportInfo:SetJustifyH("LEFT")
        supportInfo:SetText("Tracks and displays character stats in real-time. If you enjoy this addon and would like to support its development, or if you need help, stop by the website.")
        supportInfo:SetSpacing(2)

        -- Website URL
        local websiteLabel = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        websiteLabel:SetPoint("TOPLEFT", 16, -120)
        websiteLabel:SetText("Website:")

        local websiteURL = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        websiteURL:SetPoint("TOPLEFT", websiteLabel, "TOPLEFT", 70, 0)
        websiteURL:SetText("https://peavers.io")
        websiteURL:SetTextColor(0.3, 0.6, 1.0)

        -- Additional info
        local additionalInfo = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        additionalInfo:SetPoint("BOTTOMRIGHT", -16, 16)
        additionalInfo:SetJustifyH("RIGHT")
        additionalInfo:SetText("Thank you for using Peavers Addons!")

        -- Now create/prepare the settings panel
        local settingsPanel

        if PDS.ConfigUI and PDS.ConfigUI.panel then
            -- Use existing ConfigUI panel
            settingsPanel = PDS.ConfigUI.panel
            -- Print debug message to confirm we're using the proper panel
            if PeaversCommons and PeaversCommons.Utils and PeaversCommons.Utils.Debug then
                PeaversCommons.Utils.Debug(PDS, "Using ConfigUI panel with name: " .. (settingsPanel.name or "nil"))
            end
        else
            -- Create a simple settings panel with commands
            settingsPanel = CreateFrame("Frame")
            settingsPanel.name = "Settings"

            -- Required callbacks
            settingsPanel.OnRefresh = function() end
            settingsPanel.OnCommit = function() end
            settingsPanel.OnDefault = function() end

            -- Add content
            local settingsTitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            settingsTitle:SetPoint("TOPLEFT", 16, -16)
            settingsTitle:SetText("Settings")

            -- Add commands section
            local commandsTitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            commandsTitle:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 0, -16)
            commandsTitle:SetText("Available Commands:")

            local commandsList = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            commandsList:SetPoint("TOPLEFT", commandsTitle, "BOTTOMLEFT", 10, -8)
            commandsList:SetJustifyH("LEFT")
            commandsList:SetText(
                "/pds - Toggle display\n" ..
                "/pds config - Open settings"
            )
        end

        -- Register with the Settings API
        if Settings then
            -- Register main category
            local category = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)

            -- This is the CRITICAL line to make it appear in Options > Addons
            Settings.RegisterAddOnCategory(category)

            -- Store the category
            PDS.directCategory = category
            PDS.directPanel = mainPanel

            -- In case the ConfigUI panel wasn't properly initialized before, try to initialize it now
            if not PDS.ConfigUI.panel and PDS.ConfigUI.InitializeOptions then
                PDS.ConfigUI.panel = PDS.ConfigUI:InitializeOptions()
                if PDS.ConfigUI.panel then
                    settingsPanel = PDS.ConfigUI.panel
                end
            end

            -- Register settings panel as subcategory
            local settingsCategory = Settings.RegisterCanvasLayoutSubcategory(category, settingsPanel, settingsPanel.name)
            PDS.directSettingsCategory = settingsCategory

            -- Debug output
            if PeaversCommons and PeaversCommons.Utils and PeaversCommons.Utils.Debug then
                PeaversCommons.Utils.Debug(PDS, "Direct registration complete")
            end
        end
    end)
end, {
	announceMessage = "Use |cff3abdf7/pds config|r to get started"
})
