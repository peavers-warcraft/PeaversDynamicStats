local _, PDS = ...
local Config = PDS.Config

local ConfigUI = {}
PDS.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
if not PeaversCommons then
    print("|cffff0000Error:|r PeaversCommons not found.")
    return
end

-- Used by InitializeOptions below. The settings pages that went took the rest of
-- this file's locals with them, and this one nearly followed - which made
-- ConfigUI:Initialize throw, and took the whole addon's startup with it.
local ConfigUIUtils = PeaversCommons.ConfigUIUtils

-- Applying a setting lives with the addon's schema now, in EditMode.lua, so the
-- settings page and the Edit Mode panel cannot disagree about what a change
-- should do.

function ConfigUI:BuildInfoPage(parentFrame)
    PeaversCommons.ConfigUIUtils.BuildInfoPage(parentFrame, "Dynamic Stats", {
        "Shows your primary and secondary stats as live bars that update in " ..
            "real time - watch haste procs, trinkets, and buffs move your " ..
            "stats as they happen.",
        { command = "/pds", desc = "toggle the stats display" },
        { command = "/pds config", desc = "open the configuration panel" },

        { header = "Reading the bars" },
        "Each bar shows a stat's current rating or percentage; hover over one " ..
            "for details, including its recent history. During combat the " ..
            "display updates more frequently, so short procs are visible.",

        { header = "Settings are in Edit Mode" },
        "Open Edit Mode from the game menu and select the bars. Everything is " ..
            "there: size and position, the bars and their text, which stats to " ..
            "show and what colour each one is, and when the frame should hide " ..
            "itself.",
    })
end

function ConfigUI:GetPages()
    return {
        { key = "info", label = "Information", builder = function(f) ConfigUI:BuildInfoPage(f) end },
    }
end

function ConfigUI:BuildIntoFrame(parentFrame)
    self:BuildInfoPage(parentFrame)
    return parentFrame
end

function ConfigUI:InitializeOptions()
    local panel = ConfigUIUtils.CreateSettingsPanel(
        "Settings",
        "Configuration options for the stat display"
    )
    local content = panel.content
    self:BuildIntoFrame(content)
    panel:UpdateContentHeight(content:GetHeight())
    return panel
end

function ConfigUI:OpenOptions()
    PDS.Config:Save()

    if _G.PeaversConfig and _G.PeaversConfig.MainFrame then
        _G.PeaversConfig.MainFrame:Show()
        _G.PeaversConfig.MainFrame:SelectAddon("PeaversDynamicStats")
        return
    end

    if Settings and Settings.OpenToCategory then
        if PDS.directSettingsCategoryID then
            local success = pcall(Settings.OpenToCategory, PDS.directSettingsCategoryID)
            if success then return end
        end
        if PDS.directCategoryID then
            local success = pcall(Settings.OpenToCategory, PDS.directCategoryID)
            if success then return end
        end
    end

    if SettingsPanel then
        ShowUIPanel(SettingsPanel)
    end
end

PDS.Config.OpenOptionsCommand = function()
    ConfigUI:OpenOptions()
end

function ConfigUI:RefreshUI()
end

function ConfigUI:Initialize()
    self.panel = self:InitializeOptions()
end

return ConfigUI
