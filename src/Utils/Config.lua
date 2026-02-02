--------------------------------------------------------------------------------
-- PeaversDynamicStats Configuration
-- Uses PeaversCommons.ConfigManager for character+spec based profile management
--------------------------------------------------------------------------------

local addonName, PDS = ...

local PeaversCommons = _G.PeaversCommons
local ConfigManager = PeaversCommons.ConfigManager

-- PDS-specific defaults (these extend the common defaults from ConfigManager)
local PDS_DEFAULTS = {
    -- Frame position
    framePoint = "RIGHT",
    frameX = -20,
    frameY = 0,
    frameWidth = 250,
    frameHeight = 300,

    -- Bar settings
    barWidth = 230,
    barBgAlpha = 0.7,

    -- PDS-specific features
    growthAnchor = "TOPLEFT",
    combatUpdateInterval = 0.2,
    showStats = {},
    showOverflowBars = true,
    showStatChanges = true,
    showRatings = true,
    showTooltips = true,
    hideOutOfCombat = false,
    displayMode = "ALWAYS",
    enableTalentAdjustments = true,
    lastAppliedTemplate = nil,
}

-- Create the character+spec based config using ConfigManager
PDS.Config = ConfigManager:NewCharacterSpecBased(
    PDS,
    PDS_DEFAULTS,
    { savedVariablesName = "PeaversDynamicStatsDB" }
)

local Config = PDS.Config

--------------------------------------------------------------------------------
-- PDS-Specific Methods
--------------------------------------------------------------------------------

-- Returns the growth direction multiplier and anchor point based on growthAnchor setting
-- Returns: yMultiplier (-1 for down, 1 for up), xMultiplier (-1 for left, 1 for right), anchorPoint
function Config:GetGrowthDirection()
    local anchor = self.growthAnchor or "TOPLEFT"

    local directions = {
        TOPLEFT     = { yMult = -1, xMult = 1,  anchor = "TOPLEFT" },
        TOP         = { yMult = -1, xMult = 0,  anchor = "TOP" },
        TOPRIGHT    = { yMult = -1, xMult = -1, anchor = "TOPRIGHT" },
        LEFT        = { yMult = -1, xMult = 1,  anchor = "TOPLEFT" },
        CENTER      = { yMult = -1, xMult = 0,  anchor = "TOP" },
        RIGHT       = { yMult = -1, xMult = -1, anchor = "TOPRIGHT" },
        BOTTOMLEFT  = { yMult = 1,  xMult = 1,  anchor = "BOTTOMLEFT" },
        BOTTOM      = { yMult = 1,  xMult = 0,  anchor = "BOTTOM" },
        BOTTOMRIGHT = { yMult = 1,  xMult = -1, anchor = "BOTTOMRIGHT" },
    }

    local dir = directions[anchor] or directions.TOPLEFT
    return dir.yMult, dir.xMult, dir.anchor
end

-- Gets the template assigned to the current spec for auto-apply
function Config:GetSpecTemplate()
    local charKey = self:GetCharacterKey()
    local specID = self:GetSpecialization()

    if not specID or not PeaversDynamicStatsDB or not PeaversDynamicStatsDB.characters then
        return nil
    end

    local charData = PeaversDynamicStatsDB.characters[charKey]
    if not charData or not charData.specTemplates then
        return nil
    end

    return charData.specTemplates[tostring(specID)]
end

-- Assigns a template to the current spec for auto-apply
function Config:SetSpecTemplate(templateName)
    local charKey = self:GetCharacterKey()
    local specID = self:GetSpecialization()

    if not specID then
        return false
    end

    -- Initialize database structure if needed
    if not PeaversDynamicStatsDB then
        PeaversDynamicStatsDB = { profiles = {}, characters = {}, global = {} }
    end
    if not PeaversDynamicStatsDB.characters then
        PeaversDynamicStatsDB.characters = {}
    end
    if not PeaversDynamicStatsDB.characters[charKey] then
        PeaversDynamicStatsDB.characters[charKey] = {
            lastSpec = specID,
            specs = {},
            specTemplates = {}
        }
    end
    if not PeaversDynamicStatsDB.characters[charKey].specTemplates then
        PeaversDynamicStatsDB.characters[charKey].specTemplates = {}
    end

    -- Set or clear the template mapping
    if templateName and templateName ~= "" then
        PeaversDynamicStatsDB.characters[charKey].specTemplates[tostring(specID)] = templateName
    else
        PeaversDynamicStatsDB.characters[charKey].specTemplates[tostring(specID)] = nil
    end

    return true
end

-- Initialize stat visibility settings based on available stats
function Config:InitializeStatSettings()
    self.showStats = self.showStats or {}

    -- Stats that should default to hidden (opt-in rather than opt-out)
    local defaultHiddenStats = {
        ["VERSATILITY_DAMAGE_REDUCTION"] = true,
    }

    -- Get stat order from Stats module if available
    local statOrder = (PDS.Stats and PDS.Stats.STAT_ORDER) or {
        "STRENGTH", "AGILITY", "INTELLECT", "STAMINA",
        "CRIT", "HASTE", "MASTERY", "VERSATILITY",
        "VERSATILITY_DAMAGE_REDUCTION",
        "DODGE", "PARRY", "BLOCK", "LEECH", "AVOIDANCE", "SPEED"
    }

    for _, statType in ipairs(statOrder) do
        if self.showStats[statType] == nil then
            self.showStats[statType] = not defaultHiddenStats[statType]
        end
    end
end

return PDS.Config
