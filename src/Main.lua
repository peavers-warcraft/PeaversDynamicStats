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

-- Expose addon namespace globally for PeaversUISetup integration
_G.PeaversDynamicStats = PDS

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

    -- Register with GlobalAppearance if using global appearance
    if PDS.Config.useGlobalAppearance and PeaversCommons.GlobalAppearance then
        PeaversCommons.GlobalAppearance:RegisterAddon("PeaversDynamicStats", PDS.Config, function(key, value)
            -- Refresh UI when global appearance changes
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
            -- Update frame background
            if PDS.Core and PDS.Core.frame then
                PDS.Core.frame:SetBackdropColor(
                    PDS.Config.bgColor.r,
                    PDS.Config.bgColor.g,
                    PDS.Config.bgColor.b,
                    PDS.Config.bgAlpha
                )
            end
        end)
    end

    -- Initialize template management
    if PDS.TemplateUI and PDS.TemplateUI.Initialize then
        PDS.TemplateUI:Initialize()
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
        if PDS.BarManager and PDS.BarManager.UpdateAllBars then
            PDS.BarManager:UpdateAllBars()
        end
    end)

    PeaversCommons.Events:RegisterEvent("UNIT_AURA", function()
        if PDS.BarManager and PDS.BarManager.UpdateAllBars then
            PDS.BarManager:UpdateAllBars()
        end
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function()
        if PDS.BarManager and PDS.BarManager.UpdateAllBars then
            PDS.BarManager:UpdateAllBars()
        end
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        -- Save current settings for the previous spec
        PDS.Config:Save()

        -- Update identifiers for new spec (fixes stale currentSpec)
        if PDS.Config.UpdateCurrentIdentifiers then
            PDS.Config:UpdateCurrentIdentifiers()
        end

        -- Load the new spec's settings
        if PDS.Config.Load then
            PDS.Config:Load()
        end

        -- Check if there's a template assigned to this spec for auto-apply
        local templateName = PDS.Config:GetSpecTemplate()
        if templateName and PDS.TemplateUI then
            -- Verify template still exists
            local templates = PeaversDynamicStatsDB and PeaversDynamicStatsDB.templates or {}
            if templates[templateName] then
                PDS.TemplateUI:ApplyTemplate(templateName)
                if PDS.Utils then
                    PDS.Utils.Print(string.format("Auto-applied template '%s' for this spec", templateName))
                end
            else
                -- Template was deleted, clear the mapping
                PDS.Config:SetSpecTemplate(nil)
            end
        end

        -- Reapply frame position from loaded profile
        if PDS.Core and PDS.Core.ApplyFramePosition then
            PDS.Core:ApplyFramePosition()
        end

        -- Update layout for growth anchor (title bar and content frame positioning)
        if PDS.Core and PDS.Core.UpdateLayoutForGrowthAnchor then
            PDS.Core:UpdateLayoutForGrowthAnchor()
        end

        -- Recreate bars with new profile's settings (including growth anchor)
        if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
            PDS.BarManager:CreateBars(PDS.Core.contentFrame)
            PDS.Core:AdjustFrameHeight()
        end

        -- Refresh Config UI to reflect new profile values
        if PDS.ConfigUI and PDS.ConfigUI.RefreshUI then
            PDS.ConfigUI:RefreshUI()
        end
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        PDS.Core.inCombat = true
        -- Update visibility based on display mode and combat status
        if PDS.Core.UpdateFrameVisibility then
            PDS.Core:UpdateFrameVisibility()
        end
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        PDS.Core.inCombat = false
        -- Update visibility based on display mode and combat status
        if PDS.Core.UpdateFrameVisibility then
            PDS.Core:UpdateFrameVisibility()
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

    -- Update visibility when group composition changes (for PARTY_ONLY / RAID_ONLY modes)
    PeaversCommons.Events:RegisterEvent("GROUP_ROSTER_UPDATE", function()
        if PDS.Core and PDS.Core.UpdateFrameVisibility then
            PDS.Core:UpdateFrameVisibility()
        end
    end)

    -- Removed redundant PLAYER_ENTERING_WORLD handler as it's now handled by SaveGuard
    
    -- Removed redundant ADDON_LOADED handler as it's now handled by SaveGuard

    -- Use the centralized SettingsUI system from PeaversCommons
    C_Timer.After(0.5, function()
        local mainPanel, settingsPanel = PeaversCommons.SettingsUI:CreateSettingsPages(
            PDS,                      -- Addon reference
            "PeaversDynamicStats",    -- Addon name
            "Peavers Dynamic Stats",  -- Display title
            "Tracks and displays character stats in real-time.", -- Description
            {   -- Slash commands
                "/pds - Toggle display",
                "/pds config - Open settings"
            }
        )

        -- Hook OnShow to refresh UI when settings panel is displayed
        if settingsPanel then
            settingsPanel:HookScript("OnShow", function()
                if PDS.ConfigUI and PDS.ConfigUI.RefreshUI then
                    PDS.ConfigUI:RefreshUI()
                end
            end)
        end
    end)
end, {
	suppressAnnouncement = true
})
