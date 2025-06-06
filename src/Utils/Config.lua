local addonName, PDS = ...

-- Initialize Config namespace with default values
PDS.Config = {
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
    hideOutOfCombat = false, -- Hide the addon when out of combat
    enableTalentAdjustments = true, -- Enable talent-specific stat adjustments
    DEBUG_ENABLED = false,  -- Enable debug logging

    -- Character identification
    currentCharacter = nil,
    currentRealm = nil,
    currentSpec = nil,
    specIDs = {},
    
    -- Per-spec settings
    useSharedSpec = true, -- NEW: Use same settings for all specs (enabled by default)
}

-- Make sure the Stats module is loaded before accessing STAT_ORDER
-- This will be properly initialized in the InitializeStatSettings function

local Config = PDS.Config

-- Functions to get player identification information
function Config:GetPlayerName()
    return UnitName("player")
end

function Config:GetRealmName()
    local realm = GetRealmName()
    return realm
end

function Config:GetSpecialization()
    local currentSpec = GetSpecialization()
    if not currentSpec then
        return nil
    end
    
    local specID = GetSpecializationInfo(currentSpec)
    return specID
end

function Config:GetCharacterKey()
    return self:GetPlayerName() .. "-" .. self:GetRealmName()
end

function Config:GetFullProfileKey()
    local charKey = self:GetCharacterKey()
    
    -- If using shared spec settings, just return the character key
    if self.useSharedSpec then
        return charKey .. "-shared"
    end
    
    -- Otherwise use per-spec settings
    local specID = self:GetSpecialization()
    if not specID then
        -- Fall back to character-only key if spec not available
        return charKey
    end
    
    return charKey .. "-" .. tostring(specID)
end

function Config:UpdateCurrentIdentifiers()
    self.currentCharacter = self:GetPlayerName()
    self.currentRealm = self:GetRealmName()
    self.currentSpec = self:GetSpecialization()
end

-- Saves all configuration values to the SavedVariables database
function Config:Save()
    -- Initialize database structure if it doesn't exist
    if not PeaversDynamicStatsDB then
        PeaversDynamicStatsDB = {
            profiles = {},       -- Per-character + spec profiles
            characters = {},     -- Character-specific data
            global = {}          -- Global settings
        }
    end
    
    -- Initialize structure components if they don't exist
    PeaversDynamicStatsDB.profiles = PeaversDynamicStatsDB.profiles or {}
    PeaversDynamicStatsDB.characters = PeaversDynamicStatsDB.characters or {}
    PeaversDynamicStatsDB.global = PeaversDynamicStatsDB.global or {}
    
    -- Update current identifiers
    self:UpdateCurrentIdentifiers()
    
    -- Get character key (CharacterName-Realm)
    local charKey = self:GetCharacterKey()
    
    -- Get full profile key (CharacterName-Realm-SpecID)
    local profileKey = self:GetFullProfileKey()
    
    -- Initialize character data if it doesn't exist
    if not PeaversDynamicStatsDB.characters[charKey] then
        PeaversDynamicStatsDB.characters[charKey] = {
            lastSpec = self.currentSpec,
            specs = {}
        }
    end
    
    -- Update character's last specialization
    PeaversDynamicStatsDB.characters[charKey].lastSpec = self.currentSpec
    
    -- Add current spec to list of this character's specs
    if self.currentSpec then
        -- Make sure the specs table is initialized
        PeaversDynamicStatsDB.characters[charKey].specs = PeaversDynamicStatsDB.characters[charKey].specs or {}
        
        -- Add the spec to the list if it's not already there
        local specKey = tostring(self.currentSpec)
        if not PeaversDynamicStatsDB.characters[charKey].specs[specKey] then
            PeaversDynamicStatsDB.characters[charKey].specs[specKey] = true
        end
    end
    
    -- Initialize profile data if it doesn't exist
    if not PeaversDynamicStatsDB.profiles[profileKey] then
        PeaversDynamicStatsDB.profiles[profileKey] = {}
    end
    
    -- Save global settings that are not specific to profiles
    PeaversDynamicStatsDB.global.useSharedSpec = self.useSharedSpec
    
    -- Save current settings to the profile
    local profile = PeaversDynamicStatsDB.profiles[profileKey]
    
    -- Save all configuration settings to the profile
    profile.fontFace = self.fontFace
    profile.fontSize = self.fontSize
    profile.fontOutline = self.fontOutline
    profile.fontShadow = self.fontShadow
    profile.framePoint = self.framePoint
    profile.frameX = self.frameX
    profile.frameY = self.frameY
    profile.frameWidth = self.frameWidth
    profile.barWidth = self.barWidth
    profile.barHeight = self.barHeight
    profile.barTexture = self.barTexture
    profile.barBgAlpha = self.barBgAlpha
    profile.bgAlpha = self.bgAlpha
    profile.bgColor = self.bgColor
    profile.showStats = self.showStats
    profile.barSpacing = self.barSpacing
    profile.showTitleBar = self.showTitleBar
    profile.lockPosition = self.lockPosition
    profile.customColors = self.customColors
    profile.showOverflowBars = self.showOverflowBars
    profile.showStatChanges = self.showStatChanges
    profile.showRatings = self.showRatings
    profile.hideOutOfCombat = self.hideOutOfCombat
    profile.enableTalentAdjustments = self.enableTalentAdjustments
    profile.DEBUG_ENABLED = self.DEBUG_ENABLED
end

-- Loads configuration values from the SavedVariables database
function Config:Load()
    -- If no saved data exists, initialize it
    if not PeaversDynamicStatsDB then
        PeaversDynamicStatsDB = {
            profiles = {},       -- Per-character + spec profiles
            characters = {},     -- Character-specific data
            global = {}          -- Global settings
        }
    end
    
    -- Ensure the database has the correct structure
    if not PeaversDynamicStatsDB.profiles then
        PeaversDynamicStatsDB.profiles = {}
    end
    
    if not PeaversDynamicStatsDB.characters then
        PeaversDynamicStatsDB.characters = {}
    end
    
    if not PeaversDynamicStatsDB.global then
        PeaversDynamicStatsDB.global = {}
    end
    
    -- Convert old database format to new format if needed
    self:MigrateOldData()
    
    -- Update current identifiers
    self:UpdateCurrentIdentifiers()
    
    -- Load global settings
    if PeaversDynamicStatsDB.global then
        if PeaversDynamicStatsDB.global.useSharedSpec ~= nil then
            self.useSharedSpec = PeaversDynamicStatsDB.global.useSharedSpec
        end
    end
    
    -- Get character key (CharacterName-Realm)
    local charKey = self:GetCharacterKey()
    
    -- Get full profile key (CharacterName-Realm-SpecID)
    local profileKey = self:GetFullProfileKey()
    
    -- Initialize character data if it doesn't exist
    if not PeaversDynamicStatsDB.characters[charKey] then
        PeaversDynamicStatsDB.characters[charKey] = {
            lastSpec = self.currentSpec,
            specs = {}
        }
    end
    
    -- If we don't have a profile for this character+spec combo, create one
    if not PeaversDynamicStatsDB.profiles[profileKey] then
        -- See if this character exists but with a different spec
        local lastSpec = PeaversDynamicStatsDB.characters[charKey].lastSpec
        if lastSpec then
            -- Try to find a profile with that spec
            local lastProfileKey = charKey .. "-" .. lastSpec
            if PeaversDynamicStatsDB.profiles[lastProfileKey] then
                -- Copy that profile for our new spec
                PeaversDynamicStatsDB.profiles[profileKey] = self:CopyTable(PeaversDynamicStatsDB.profiles[lastProfileKey])
            end
        end
    end
    
    -- If we still don't have a profile, create an empty one
    if not PeaversDynamicStatsDB.profiles[profileKey] then
        PeaversDynamicStatsDB.profiles[profileKey] = {}
    end
    
    -- Load settings from the profile
    local profile = PeaversDynamicStatsDB.profiles[profileKey]
    
    -- Load settings from the profile, using defaults if not found
    if profile.fontFace then
        self.fontFace = profile.fontFace
    end
    if profile.fontSize then
        self.fontSize = profile.fontSize
    end
    if profile.fontOutline then
        self.fontOutline = profile.fontOutline
    end
    if profile.fontShadow ~= nil then
        self.fontShadow = profile.fontShadow
    end
    if profile.framePoint then
        self.framePoint = profile.framePoint
    end
    if profile.frameX then
        self.frameX = profile.frameX
    end
    if profile.frameY then
        self.frameY = profile.frameY
    end
    if profile.frameWidth then
        self.frameWidth = profile.frameWidth
    end
    if profile.barWidth then
        self.barWidth = profile.barWidth
    end
    if profile.barHeight then
        self.barHeight = profile.barHeight
    end
    if profile.barTexture then
        self.barTexture = profile.barTexture
    end
    if profile.barBgAlpha then
        self.barBgAlpha = profile.barBgAlpha
    end
    if profile.bgAlpha then
        self.bgAlpha = profile.bgAlpha
    end
    if profile.bgColor then
        self.bgColor = profile.bgColor
    end
    if profile.showStats then
        self.showStats = profile.showStats
    end
    if profile.barSpacing then
        self.barSpacing = profile.barSpacing
    end
    if profile.showTitleBar ~= nil then
        self.showTitleBar = profile.showTitleBar
    end
    if profile.lockPosition ~= nil then
        self.lockPosition = profile.lockPosition
    end
    if profile.customColors then
        self.customColors = profile.customColors
    end
    if profile.showOverflowBars ~= nil then
        self.showOverflowBars = profile.showOverflowBars
    end
    if profile.showStatChanges ~= nil then
        self.showStatChanges = profile.showStatChanges
    end
    if profile.showRatings ~= nil then
        self.showRatings = profile.showRatings
    end
    if profile.hideOutOfCombat ~= nil then
        self.hideOutOfCombat = profile.hideOutOfCombat
    end
    if profile.enableTalentAdjustments ~= nil then
        self.enableTalentAdjustments = profile.enableTalentAdjustments
    end
    if profile.DEBUG_ENABLED ~= nil then
        self.DEBUG_ENABLED = profile.DEBUG_ENABLED
    end
end

-- Helper function to make a deep copy of a table
function Config:CopyTable(source)
    if type(source) ~= "table" then
        return source
    end
    
    local copy = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            copy[key] = self:CopyTable(value)
        else
            copy[key] = value
        end
    end
    
    return copy
end

-- Migration helper for old database format
function Config:MigrateOldData()
    -- Only migrate if we have old format (direct keys in the root) and no profiles yet
    if PeaversDynamicStatsDB.fontFace and (not PeaversDynamicStatsDB.profiles or not next(PeaversDynamicStatsDB.profiles)) then
        -- Initialize the new structure
        PeaversDynamicStatsDB.profiles = {}
        PeaversDynamicStatsDB.characters = {}
        PeaversDynamicStatsDB.global = {}
        
        -- Update identifiers
        self:UpdateCurrentIdentifiers()
        
        -- Create character and profile entries
        local charKey = self:GetCharacterKey()
        local profileKey = self:GetFullProfileKey()
        
        -- Initialize character data
        PeaversDynamicStatsDB.characters[charKey] = {
            lastSpec = self.currentSpec,
            specs = {}
        }
        
        -- Add current spec to character specs
        if self.currentSpec then
            -- Make sure the specs table is initialized
            PeaversDynamicStatsDB.characters[charKey].specs = PeaversDynamicStatsDB.characters[charKey].specs or {}
            
            -- Add the spec to the list
            PeaversDynamicStatsDB.characters[charKey].specs[tostring(self.currentSpec)] = true
        end
        
        -- Create profile with old settings
        PeaversDynamicStatsDB.profiles[profileKey] = {
            fontFace = PeaversDynamicStatsDB.fontFace,
            fontSize = PeaversDynamicStatsDB.fontSize,
            fontOutline = PeaversDynamicStatsDB.fontOutline,
            fontShadow = PeaversDynamicStatsDB.fontShadow,
            framePoint = PeaversDynamicStatsDB.framePoint,
            frameX = PeaversDynamicStatsDB.frameX,
            frameY = PeaversDynamicStatsDB.frameY,
            frameWidth = PeaversDynamicStatsDB.frameWidth,
            barWidth = PeaversDynamicStatsDB.barWidth,
            barHeight = PeaversDynamicStatsDB.barHeight,
            barTexture = PeaversDynamicStatsDB.barTexture,
            barBgAlpha = PeaversDynamicStatsDB.barBgAlpha,
            bgAlpha = PeaversDynamicStatsDB.bgAlpha,
            bgColor = PeaversDynamicStatsDB.bgColor,
            showStats = PeaversDynamicStatsDB.showStats,
            barSpacing = PeaversDynamicStatsDB.barSpacing,
            showTitleBar = PeaversDynamicStatsDB.showTitleBar,
            lockPosition = PeaversDynamicStatsDB.lockPosition,
            customColors = PeaversDynamicStatsDB.customColors,
            showOverflowBars = PeaversDynamicStatsDB.showOverflowBars,
            showStatChanges = PeaversDynamicStatsDB.showStatChanges,
            showRatings = PeaversDynamicStatsDB.showRatings,
            hideOutOfCombat = PeaversDynamicStatsDB.hideOutOfCombat
        }
        
        -- Clean up old format data
        PeaversDynamicStatsDB.fontFace = nil
        PeaversDynamicStatsDB.fontSize = nil
        PeaversDynamicStatsDB.fontOutline = nil
        PeaversDynamicStatsDB.fontShadow = nil
        PeaversDynamicStatsDB.framePoint = nil
        PeaversDynamicStatsDB.frameX = nil
        PeaversDynamicStatsDB.frameY = nil
        PeaversDynamicStatsDB.frameWidth = nil
        PeaversDynamicStatsDB.barWidth = nil
        PeaversDynamicStatsDB.barHeight = nil
        PeaversDynamicStatsDB.barTexture = nil
        PeaversDynamicStatsDB.barBgAlpha = nil
        PeaversDynamicStatsDB.bgAlpha = nil
        PeaversDynamicStatsDB.bgColor = nil
        PeaversDynamicStatsDB.showStats = nil
        PeaversDynamicStatsDB.barSpacing = nil
        PeaversDynamicStatsDB.showTitleBar = nil
        PeaversDynamicStatsDB.lockPosition = nil
        PeaversDynamicStatsDB.customColors = nil
        PeaversDynamicStatsDB.showOverflowBars = nil
        PeaversDynamicStatsDB.showStatChanges = nil
        PeaversDynamicStatsDB.showRatings = nil
        PeaversDynamicStatsDB.hideOutOfCombat = nil
    end
end

-- Returns a sorted table of available fonts, including those from LibSharedMedia
function Config:GetFonts()
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

-- Returns a sorted table of available statusbar textures from various sources
function Config:GetBarTextures()
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

function Config:Initialize()
    -- Update current character, realm, and spec identifiers
    self:UpdateCurrentIdentifiers()
    
    -- Load settings for the current character and spec
    self:Load()

    -- Initialize default values if they're not set
    if not next(self.showStats) then
        self.showStats = {}
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
    
    -- Initialize the spec ID list for debugging/info
    self.specIDs = self.specIDs or {}
    if self.currentSpec then
        self.specIDs[tostring(self.currentSpec)] = true
    end
    
    -- Save settings after initialization to ensure they're persisted
    self:Save()
end

function Config:InitializeStatSettings()
    -- Initialize showStats if it's not already defined
    self.showStats = self.showStats or {}
    
    -- Make sure Stats module is loaded and has STAT_ORDER defined
    if PDS.Stats and PDS.Stats.STAT_ORDER then
        for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
            if self.showStats[statType] == nil then
                self.showStats[statType] = true
            end
        end
    else
        -- Fallback if Stats.STAT_ORDER is not available
        local defaultStats = {
            "STRENGTH", "AGILITY", "INTELLECT", "STAMINA",
            "CRIT", "HASTE", "MASTERY", "VERSATILITY", 
            "DODGE", "PARRY", "BLOCK", "LEECH", "AVOIDANCE", "SPEED"
        }
        
        for _, statType in ipairs(defaultStats) do
            if self.showStats[statType] == nil then
                self.showStats[statType] = true
            end
        end
    end
end
