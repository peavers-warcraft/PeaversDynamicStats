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
    
    -- Initialize patrons support
    if PDS.Patrons and PDS.Patrons.Initialize then
        PDS.Patrons:Initialize()
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
        -- Save current settings for the previous spec
        PDS.Config:Save()
        
        -- Update identifier for new spec
        PDS.Config:UpdateCurrentIdentifiers()
        
        -- Load settings for the new spec
        PDS.Config:Load()
        
        -- Update all bars with the new spec's settings
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

    -- Use the centralized SettingsUI system from PeaversCommons
    C_Timer.After(0.5, function()
        -- Create standardized settings pages
        PeaversCommons.SettingsUI:CreateSettingsPages(
            PDS,                      -- Addon reference
            "PeaversDynamicStats",    -- Addon name
            "Peavers Dynamic Stats",  -- Display title
            "Tracks and displays character stats in real-time.", -- Description
            {   -- Slash commands
                "/pds - Toggle display",
                "/pds config - Open settings"
            }
        )
    end)
end, {
	announceMessage = "Use |cff3abdf7/pds config|r to get started"
})
