local addonName, PDS = ...

-- Check for PeaversCommons
local PeaversCommons = _G.PeaversCommons
if not PeaversCommons then
    print("|cffff0000Error:|r " .. addonName .. " requires PeaversCommons to work properly.")
    return
end

-- Check for required PeaversCommons modules
local requiredModules = {"Events", "SlashCommands", "Utils"}
for _, module in ipairs(requiredModules) do
    if not PeaversCommons[module] then
        print("|cffff0000Error:|r " .. addonName .. " requires PeaversCommons." .. module .. " which is missing.")
        return
    end
end

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

--------------------------------------------------------------------------------
-- WoW 12.0 API Diagnostics
-- Logs API availability at startup for debugging compatibility issues
--------------------------------------------------------------------------------

local function LogAPIAvailability()
    if not PDS.Config.DEBUG_ENABLED then return end

    local apis = {
        -- Core stat APIs
        { name = "GetHaste", func = GetHaste },
        { name = "GetCritChance", func = GetCritChance },
        { name = "GetSpellCritChance", func = GetSpellCritChance },
        { name = "GetMasteryEffect", func = GetMasteryEffect },
        { name = "GetMastery", func = GetMastery },
        { name = "GetCombatRating", func = GetCombatRating },
        { name = "GetCombatRatingBonus", func = GetCombatRatingBonus },
        { name = "GetSpeed", func = GetSpeed },
        { name = "GetLifesteal", func = GetLifesteal },
        { name = "GetAvoidance", func = GetAvoidance },
        { name = "GetDodgeChance", func = GetDodgeChance },
        { name = "GetParryChance", func = GetParryChance },
        { name = "GetBlockChance", func = GetBlockChance },
        { name = "UnitStat", func = UnitStat },
        -- 12.0 Secret Value API
        { name = "issecretvalue", func = issecretvalue },
        -- Aura APIs (may be restricted in 12.0 combat)
        { name = "C_UnitAuras", func = C_UnitAuras },
        { name = "C_UnitAuras.GetAuraDataByIndex", func = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex },
        -- New stat APIs (may be added in future)
        { name = "C_Attributes", func = C_Attributes },
        { name = "C_Stats", func = C_Stats },
    }

    PDS.Utils.Debug("=== WoW 12.0 API Availability Check ===")
    for _, api in ipairs(apis) do
        local available = api.func ~= nil
        local status = available and "|cff00ff00available|r" or "|cffff0000MISSING|r"
        PDS.Utils.Debug(api.name .. ": " .. status)
    end
    PDS.Utils.Debug("=== End API Check ===")
end

-- Expose for manual testing via /pds debug
PDS.LogAPIAvailability = LogAPIAvailability

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
    end,
    debug = function()
        -- Toggle debug mode
        PDS.Config.DEBUG_ENABLED = not PDS.Config.DEBUG_ENABLED
        if PDS.Utils and PDS.Utils.Print then
            if PDS.Config.DEBUG_ENABLED then
                PDS.Utils.Print("Debug mode ENABLED - Check for detailed messages")
            else
                PDS.Utils.Print("Debug mode DISABLED")
            end
        end
        PDS.Config:Save()
    end,
    -- Special command for rogue versatility problems
    fixrogue = function()
        -- Toggle talent adjustments
        PDS.Config.enableTalentAdjustments = not PDS.Config.enableTalentAdjustments
        if PDS.Utils and PDS.Utils.Print then
            if PDS.Config.enableTalentAdjustments then
                PDS.Utils.Print("Talent adjustments (Thief's Versatility fix) ENABLED")
            else
                PDS.Utils.Print("Talent adjustments (Thief's Versatility fix) DISABLED")
            end
        end
        -- Update bars
        if PDS.BarManager then
            PDS.BarManager:UpdateAllBars()
        end
        PDS.Config:Save()
    end
})

-- Initialize addon using the PeaversCommons Events module
PeaversCommons.Events:Init(addonName, function()
    -- Initialize localization (stat names)
    if PDS.Stats and PDS.Stats.InitializeStatNames then
        PDS.Stats:InitializeStatNames()
    end
    
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

    -- Log API availability for 12.0 compatibility debugging
    LogAPIAvailability()

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

        -- WoW 12.0: Refresh talent cache after combat ends (aura APIs now accessible)
        if PDS.Stats and PDS.Stats.combatCache then
            PDS.Stats.combatCache.talentAdjustments = {}
            PDS.Stats.combatCache.lastUpdateTime = 0
            if PDS.Config.DEBUG_ENABLED then
                PDS.Utils.Debug("Combat ended - cleared talent adjustment cache for refresh")
            end
        end
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_LOGOUT", function()
        PDS.Config:Save()
    end)
    
    -- Removed redundant PLAYER_ENTERING_WORLD handler as it's now handled by SaveGuard
    
    -- Removed redundant ADDON_LOADED handler as it's now handled by SaveGuard

    -- Use the centralized SettingsUI system from PeaversCommons
    C_Timer.After(0.5, function()
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
	suppressAnnouncement = true
})
