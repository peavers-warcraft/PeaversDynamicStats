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
	showStatChanges = true, -- Show stat value changes
	showRatings = true, -- Show rating values
}

-- Initialize showStats with values from Stats.STAT_TYPES
for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
	PDS.Config.showStats[statType] = true
end

local Config = PDS.Config

-- Saves all configuration values to the SavedVariables database
function Config:Save()
	if not PeaversDynamicStatsDB then
		PeaversDynamicStatsDB = {}
	end

	PeaversDynamicStatsDB.fontFace = self.fontFace
	PeaversDynamicStatsDB.fontSize = self.fontSize
	PeaversDynamicStatsDB.fontOutline = self.fontOutline
	PeaversDynamicStatsDB.fontShadow = self.fontShadow
	PeaversDynamicStatsDB.framePoint = self.framePoint
	PeaversDynamicStatsDB.frameX = self.frameX
	PeaversDynamicStatsDB.frameY = self.frameY
	PeaversDynamicStatsDB.frameWidth = self.frameWidth
	PeaversDynamicStatsDB.barWidth = self.barWidth
	PeaversDynamicStatsDB.barHeight = self.barHeight
	PeaversDynamicStatsDB.barTexture = self.barTexture
	PeaversDynamicStatsDB.barBgAlpha = self.barBgAlpha
	PeaversDynamicStatsDB.bgAlpha = self.bgAlpha
	PeaversDynamicStatsDB.bgColor = self.bgColor
	PeaversDynamicStatsDB.showStats = self.showStats
	PeaversDynamicStatsDB.barSpacing = self.barSpacing
	PeaversDynamicStatsDB.showTitleBar = self.showTitleBar
	PeaversDynamicStatsDB.lockPosition = self.lockPosition
	PeaversDynamicStatsDB.customColors = self.customColors
	PeaversDynamicStatsDB.showStatChanges = self.showStatChanges
	PeaversDynamicStatsDB.showRatings = self.showRatings
end

-- Loads configuration values from the SavedVariables database
function Config:Load()
	if not PeaversDynamicStatsDB then
		return
	end

	if PeaversDynamicStatsDB.fontFace then
		self.fontFace = PeaversDynamicStatsDB.fontFace
	end
	if PeaversDynamicStatsDB.fontSize then
		self.fontSize = PeaversDynamicStatsDB.fontSize
	end
	if PeaversDynamicStatsDB.fontOutline then
		self.fontOutline = PeaversDynamicStatsDB.fontOutline
	end
	if PeaversDynamicStatsDB.fontShadow ~= nil then
		self.fontShadow = PeaversDynamicStatsDB.fontShadow
	end
	if PeaversDynamicStatsDB.framePoint then
		self.framePoint = PeaversDynamicStatsDB.framePoint
	end
	if PeaversDynamicStatsDB.frameX then
		self.frameX = PeaversDynamicStatsDB.frameX
	end
	if PeaversDynamicStatsDB.frameY then
		self.frameY = PeaversDynamicStatsDB.frameY
	end
	if PeaversDynamicStatsDB.frameWidth then
		self.frameWidth = PeaversDynamicStatsDB.frameWidth
	end
	if PeaversDynamicStatsDB.barWidth then
		self.barWidth = PeaversDynamicStatsDB.barWidth
	end
	if PeaversDynamicStatsDB.barHeight then
		self.barHeight = PeaversDynamicStatsDB.barHeight
	end
	if PeaversDynamicStatsDB.barTexture then
		self.barTexture = PeaversDynamicStatsDB.barTexture
	end
	if PeaversDynamicStatsDB.barBgAlpha then
		self.barBgAlpha = PeaversDynamicStatsDB.barBgAlpha
	end
	if PeaversDynamicStatsDB.bgAlpha then
		self.bgAlpha = PeaversDynamicStatsDB.bgAlpha
	end
	if PeaversDynamicStatsDB.bgColor then
		self.bgColor = PeaversDynamicStatsDB.bgColor
	end
	if PeaversDynamicStatsDB.showStats then
		self.showStats = PeaversDynamicStatsDB.showStats
	end
	if PeaversDynamicStatsDB.barSpacing then
		self.barSpacing = PeaversDynamicStatsDB.barSpacing
	end
	if PeaversDynamicStatsDB.showTitleBar ~= nil then
		self.showTitleBar = PeaversDynamicStatsDB.showTitleBar
	end
	if PeaversDynamicStatsDB.lockPosition ~= nil then
		self.lockPosition = PeaversDynamicStatsDB.lockPosition
	end
	if PeaversDynamicStatsDB.customColors then
		self.customColors = PeaversDynamicStatsDB.customColors
	end
	if PeaversDynamicStatsDB.showStatChanges ~= nil then
		self.showStatChanges = PeaversDynamicStatsDB.showStatChanges
	end
	if PeaversDynamicStatsDB.showRatings ~= nil then
		self.showRatings = PeaversDynamicStatsDB.showRatings
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

-- Initialize the configuration when the addon loads
function Config:Initialize()
    -- Load saved configuration
    self:Load()

    -- Ensure all required stats are in the showStats table
    for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
        if self.showStats[statType] == nil then
            self.showStats[statType] = true
        end
    end

    -- Ensure showStatChanges is enabled by default
    if self.showStatChanges == nil then
        self.showStatChanges = true
    end

    -- Ensure showRatings is enabled by default
    if self.showRatings == nil then
        self.showRatings = true
    end
end
