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

    -- Frame anchoring (for resolution-independent positioning)
    -- When anchorFrame is set, position is relative to that frame instead of UIParent
    anchorFrame = nil,           -- Frame name to anchor to (e.g., "UUF_Player")
    anchorPoint = "TOPLEFT",     -- Point on PDS frame
    anchorRelPoint = "BOTTOMLEFT", -- Point on anchor frame
    anchorOffsetX = 0,           -- X offset from anchor
    anchorOffsetY = -5,          -- Y offset from anchor (negative = below)

    -- Bar settings
    barWidth = 230,
    barBgAlpha = 0.7,
    textAlpha = 1.0,

    -- PDS-specific features
    growthAnchor = "TOPLEFT",
    combatUpdateInterval = 0.2,
    showStats = {},
    customTextColors = {},
    autoHideZeroStats = true,
    showOverflowBars = true,
    showStatChanges = true,
    persistStatChanges = false,
    showRatings = true,
    showRawValues = false,
    rawValueMax = 0,
    sortBarsByRating = false,
    showStatNames = true,
    showTooltips = true,
    hideOutOfCombat = false,
    displayMode = "ALWAYS",
    enableTalentAdjustments = true,
    lastAppliedTemplate = nil,
    highlightHighestRating = false,
    highlightStyle = "SUBTLE",
    highlightShowIcon = false,
}

-- Create the AceDB-backed config with spec-based profiles
PDS.Config = ConfigManager:NewWithAceDB(
    PDS,
    PDS_DEFAULTS,
    {
        savedVariablesName = "PeaversDynamicStatsDB",
        profileType = "spec",
        onProfileChanged = function()
            if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
                PDS.BarManager:CreateBars(PDS.Core.contentFrame)
                PDS.Core:AdjustFrameHeight()
            end
        end,
    }
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

function Config:GetSpecTemplate()
    if not self.db or not self.db.char then return nil end
    local specID = GetSpecialization() and GetSpecializationInfo(GetSpecialization())
    if not specID then return nil end
    local specTemplates = self.db.char.specTemplates
    if not specTemplates then return nil end
    return specTemplates[tostring(specID)]
end

function Config:SetSpecTemplate(templateName)
    if not self.db then return false end
    local specID = GetSpecialization() and GetSpecializationInfo(GetSpecialization())
    if not specID then return false end

    if not self.db.char.specTemplates then
        self.db.char.specTemplates = {}
    end

    if templateName and templateName ~= "" then
        self.db.char.specTemplates[tostring(specID)] = templateName
    else
        self.db.char.specTemplates[tostring(specID)] = nil
    end

    return true
end

function Config:GetSpecialization()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    return GetSpecializationInfo(specIndex)
end

function Config:CopyTable(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            copy[k] = self:CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Initialize stat visibility settings based on available stats
function Config:InitializeStatSettings()
    self.showStats = self.showStats or {}

    -- Stats that should default to hidden (opt-in rather than opt-out)
    local defaultHiddenStats = {
        ["VERSATILITY_DAMAGE_REDUCTION"] = true,
        ["PRIMARY_STAT"] = true,
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
