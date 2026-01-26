-- PeaversDynamicStats Config Manager Module
local addonName, PDS = ...

-- Access PeaversCommons utilities
local PeaversCommons = _G.PeaversCommons

-- Create default settings
local defaults = {
    -- Frame settings
    frameWidth = 250,
    frameHeight = 300,
    framePoint = "RIGHT",
    frameX = -20,
    frameY = 0,
    lockPosition = false,

    -- Bar settings
    barWidth = 230,
    barHeight = 20,
    barSpacing = 2,
    barBgAlpha = 0.7,

    -- Visual settings
    fontFace = "Fonts\\FRIZQT__.TTF",
    fontSize = 9,
    fontOutline = "OUTLINE",
    fontShadow = false,

    -- Other settings
    barTexture = "Interface\\TargetingFrame\\UI-StatusBar",
    bgAlpha = 0.8,
    bgColor = { r = 0, g = 0, b = 0 },
    updateInterval = 0.5,
    combatUpdateInterval = 0.2,
    showOnLogin = true,
    showTitleBar = true,
    showStats = {},
    customColors = {},
    showOverflowBars = true, -- Show overflow bars for stats exceeding 100%
    showStatChanges = true, -- Show stat value changes
    showRatings = true,    -- Show rating values
    hideOutOfCombat = false, -- Hide the addon when out of combat,
    DEBUG_ENABLED = false,
}

-- Create a profile-based configuration manager for PDS
local ConfigManager = PeaversCommons.ConfigManager:NewProfileBased(
    "PeaversDynamicStats",  -- Addon name
    defaults,              -- Default settings
    {
        savedVariablesName = "PeaversDynamicStatsDB"
    }
)

-- Add additional utility functions for profile handling

-- Gets the character+spec-based profile key
function ConfigManager:GetProfileKey()
    local charKey = PeaversCommons.Utils.GetCharacterKey()
    local playerInfo = PeaversCommons.Utils.GetPlayerInfo()
    local specID = playerInfo.specID

    if not specID then
        -- Fall back to character key if spec not available
        return charKey
    end

    return charKey .. "-" .. tostring(specID)
end

-- Get available fonts
function ConfigManager:GetFonts()
    local fonts = {
        ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
        ["Fonts\\FRIZQT__.TTF"] = "Default",
        ["Fonts\\MORPHEUS.TTF"] = "Morpheus",
        ["Fonts\\SKURRI.TTF"] = "Skurri"
    }

    if LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true) then
        local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")
        if LSM then
            for name, path in pairs(LSM:HashTable("font")) do
                fonts[path] = name
            end
        end
    end

    local sortedFonts = {}
    for path, name in pairs(fonts) do
        table.insert(sortedFonts, { path = path, name = name })
    end

    table.sort(sortedFonts, function(a, b)
        return a.name < b.name
    end)

    local result = {}
    for _, font in ipairs(sortedFonts) do
        result[font.path] = font.name
    end

    return result
end

-- Get available bar textures
function ConfigManager:GetBarTextures()
    local textures = {
        ["Interface\\TargetingFrame\\UI-StatusBar"] = "Default",
        ["Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"] = "Skill Bar",
        ["Interface\\PVPFrame\\UI-PVP-Progress-Bar"] = "PVP Bar",
        ["Interface\\RaidFrame\\Raid-Bar-Hp-Fill"] = "Raid"
    }

    if LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true) then
        local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")
        if LSM then
            for name, path in pairs(LSM:HashTable("statusbar")) do
                textures[path] = name
            end
        end
    end

    if _G.Details and _G.Details.statusbar_info then
        for i, textureTable in ipairs(_G.Details.statusbar_info) do
            if textureTable.file and textureTable.name then
                textures[textureTable.file] = textureTable.name
            end
        end
    end

    local sortedTextures = {}
    for path, name in pairs(textures) do
        table.insert(sortedTextures, { path = path, name = name })
    end

    table.sort(sortedTextures, function(a, b)
        return a.name < b.name
    end)

    local result = {}
    for _, texture in ipairs(sortedTextures) do
        result[texture.path] = texture.name
    end

    return result
end

-- Initialize stat settings
function ConfigManager:InitializeStatSettings()
    if PDS.Stats and PDS.Stats.STAT_ORDER then
        for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
            if self.showStats[statType] == nil then
                self.showStats[statType] = true
            end
        end
    end
end

-- Override the standard Initialize method to handle custom initialization
local originalInitialize = ConfigManager.Initialize
function ConfigManager:Initialize()
    -- Call the original initialize method
    originalInitialize(self)
    
    -- Initialize stat settings
    self:InitializeStatSettings()
    
    -- Ensure any missing settings have defaults
    if not next(self.showStats) then
        self.showStats = {}
        self:InitializeStatSettings()
    end

    if self.showStatChanges == nil then
        self.showStatChanges = true
    end

    if self.showRatings == nil then
        self.showRatings = true
    end

    if self.showOverflowBars == nil then
        self.showOverflowBars = true
    end

    if self.hideOutOfCombat == nil then
        self.hideOutOfCombat = false
    end
end

-- Set as PDS Config
PDS.Config = ConfigManager

return ConfigManager