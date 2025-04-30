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
local function getAddOnMetadata(name, key)
    return C_AddOns.GetAddOnMetadata(name, key)
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

        -- Initialize support UI
        if PDS.SupportUI and PDS.SupportUI.Initialize then
            PDS.SupportUI:Initialize()
        end

        -- Initialize core components
        PDS.Core:Initialize()

        -- Register other events after initialization
        PDS.Core:RegisterEvents()

        -- Frame visibility is managed in Core.lua's Initialize function

        -- Unregister the ADDON_LOADED event as we don't need it anymore
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGOUT" then
        -- Save configuration on logout
        PDS.Config:Save()
    end
end)
