local addonName, PDS = ...

-- Initialize addon namespace and modules
PDS = PDS or {}

-- Module namespaces
PDS.Core = {}
PDS.UI = {}
PDS.Utils = {}
PDS.Config = {}
PDS.Stats = {}

-- Version information
-- Use C_AddOns.GetAddOnMetadata for newer WoW versions, fall back to GetAddOnMetadata for older versions
local function getAddOnMetadata(name, key)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(name, key)
    elseif GetAddOnMetadata then
        return GetAddOnMetadata(name, key)
    else
        return nil
    end
end

PDS.version = getAddOnMetadata(addonName, "Version") or "1.0.5"
PDS.addonName = addonName

-- Initialize addon when ADDON_LOADED event fires
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize configuration
        PDS.Config:Initialize()

        -- Initialize configuration UI
        if PDS.Config.UI and PDS.Config.UI.InitializeOptions then
            PDS.Config.UI:InitializeOptions()
        end

        -- Initialize core components
        PDS.Core:Initialize()

        -- Register other events after initialization
        PDS.Core:RegisterEvents()

        -- Show frame if configured to show on login
        if PDS.Config.showOnLogin then
            PDS.Core.frame:Show()
        else
            PDS.Core.frame:Hide()
        end

        -- Unregister the ADDON_LOADED event as we don't need it anymore
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGOUT" then
        -- Save configuration on logout
        PDS.Config:Save()
    end
end)
