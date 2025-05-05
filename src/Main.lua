local addonName, PDS = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons

-- Initialize addon namespace and modules
PDS = PDS or {}

-- Module namespaces (initialize them if they don't exist)
PDS.Core = PDS.Core or {}
PDS.UI = PDS.UI or {}
PDS.Utils = PDS.Utils or {}
PDS.Config = PDS.Config or {}
PDS.Stats = PDS.Stats or {}

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
    config = function()
        -- Use the addon's own OpenOptions function
        if PDS.ConfigUI and PDS.ConfigUI.OpenOptions then
            PDS.ConfigUI:OpenOptions()
        elseif PDS.Config and PDS.Config.OpenOptionsCommand then
            PDS.Config.OpenOptionsCommand()
        end
    end
})

-- Initialize addon using the PeaversCommons Events module
PeaversCommons.Events:Init(addonName, function()
    -- Make sure Stats is initialized if possible
    if PDS.Stats.Initialize then
        PDS.Stats:Initialize()
    end
    
    -- Make sure Config is properly loaded and initialized
    if not PDS.Config or not PDS.Config.Save then
        -- Create a minimal Config if something went wrong
        -- Use PDS.Utils.Print if initialized
        if PDS.Utils and PDS.Utils.Print then
            PDS.Utils.Print("Config module not properly loaded, using defaults")
        -- Or use PeaversCommons.Utils.Print if available
        elseif PeaversCommons and PeaversCommons.Utils and PeaversCommons.Utils.Print then
            PeaversCommons.Utils.Print("DynamicStats: Config module not properly loaded, using defaults")
        -- Fallback to direct printing if nothing else works
        else
            print("|cff3abdf7Peavers|rDynamicStats: Config module not properly loaded, using defaults")
        end
        
        PDS.Config = {
            enabled = true,
            showTitleBar = true,
            bgAlpha = 0.8,
            showOverflowBars = true,
            showStatChanges = true,
            showRatings = true,
            Save = function() end -- No-op function
        }
    else
        -- Config exists, make sure it's properly initialized 
        if PDS.Config.Initialize then
            PDS.Config:Initialize()
        end
    end
    
    -- Initialize configuration UI
    if PDS.ConfigUI and PDS.ConfigUI.Initialize then
        PDS.ConfigUI:Initialize()
    end
    
    -- Initialize patrons support
    if PDS.Patrons and PDS.Patrons.Initialize then
        PDS.Patrons:Initialize()
    end
    
    -- Initialize the SaveGuard system for robust settings persistence
    if PDS.SaveGuard and PDS.SaveGuard.Initialize then
        PDS.SaveGuard:Initialize()
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
        
        -- For profile-based configs, we don't need to manually update identifiers or load
        -- The ConfigManager handles that automatically on the next access
        
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
        -- Save settings when combat ends
        PDS.Config:Save()
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_LOGOUT", function()
        PDS.Config:Save()
    end)
    
    -- Removed redundant PLAYER_ENTERING_WORLD handler as it's now handled by SaveGuard
    
    -- Removed redundant ADDON_LOADED handler as it's now handled by SaveGuard

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
