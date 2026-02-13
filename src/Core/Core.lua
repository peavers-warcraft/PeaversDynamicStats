local addonName, PDS = ...
local Core = {}
PDS.Core = Core

Core.inCombat = false

function Core:Initialize()
	PDS.Stats:InitializeBaseValues()
	
	if PDS.Config and PDS.Config.InitializeStatSettings then
		PDS.Config:InitializeStatSettings()
	end
	
	if PDS.StatHistory then
		PDS.StatHistory:Initialize()
	end
	
	-- Set up auto-save hook for whenever settings are modified
	local autoSaveTimer = nil
	local function QueueSettingsSave()
		-- Cancel any pending timer to avoid multiple rapid saves
		if autoSaveTimer then 
			autoSaveTimer:Cancel()
		end
		
		-- Set a new timer to save settings after a short delay
		autoSaveTimer = C_Timer.NewTimer(2, function()
			if PDS.Config then
				PDS.Config:Save()
				autoSaveTimer = nil
			end
		end)
	end
	
	-- Register an event to catch settings changes
	local settingsFrame = CreateFrame("Frame")
	settingsFrame:RegisterEvent("VARIABLES_LOADED")
	settingsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	settingsFrame:RegisterEvent("ADDON_LOADED")
	settingsFrame:SetScript("OnEvent", function(self, event, ...)
		if event == "ADDON_LOADED" and ... == addonName then
			QueueSettingsSave()
		elseif event == "VARIABLES_LOADED" or event == "PLAYER_ENTERING_WORLD" then
			QueueSettingsSave()
		end
	end)
	
	self.frame = CreateFrame("Frame", "PeaversDynamicStatsFrame", UIParent, "BackdropTemplate")
	self.frame:SetSize(PDS.Config.frameWidth, PDS.Config.frameHeight)
	self.frame:SetBackdrop({
		bgFile = "Interface\\BUTTONS\\WHITE8X8",
		edgeFile = "Interface\\BUTTONS\\WHITE8X8",
		tile = true, tileSize = 16, edgeSize = 1,
	})
	self.frame:SetBackdropColor(PDS.Config.bgColor.r, PDS.Config.bgColor.g, PDS.Config.bgColor.b, PDS.Config.bgAlpha)
	self.frame:SetBackdropBorderColor(0, 0, 0, PDS.Config.bgAlpha)

	local titleBar = PDS.TitleBar:Create(self.frame)
	self.titleBar = titleBar

	self.contentFrame = CreateFrame("Frame", nil, self.frame)
	-- Initial anchors will be set by UpdateLayoutForGrowthAnchor
	self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -20)
	self.contentFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)

	-- Update layout based on growth anchor setting (repositions title bar and content)
	self:UpdateLayoutForGrowthAnchor()
	self:UpdateTitleBarVisibility()

	PDS.BarManager:CreateBars(self.contentFrame)
	self:AdjustFrameHeight()
	self:ApplyFramePosition()
	self:UpdateFrameLock()

	self.inCombat = InCombatLockdown()
	self:UpdateFrameVisibility()
end

function Core:AdjustFrameHeight()
	PDS.BarManager:AdjustFrameHeight(self.frame, self.contentFrame, PDS.Config.showTitleBar)
end

function Core:UpdateFrameLock()
	local PeaversCommons = _G.PeaversCommons
	PeaversCommons.FrameLock:ApplyFromConfig(
		self.frame,
		self.contentFrame,
		PDS.Config,
		function() PDS.Config:Save() end
	)
end

function Core:UpdateTitleBarVisibility()
	if self.titleBar then
		if PDS.Config.showTitleBar then
			self.titleBar:Show()
		else
			self.titleBar:Hide()
		end

		-- Update layout based on growth anchor
		self:UpdateLayoutForGrowthAnchor()
		self:AdjustFrameHeight()
		self:UpdateFrameLock()
	end
end

-- Updates the layout of title bar and content frame based on growth anchor
-- For bottom anchors, title bar goes at bottom and content grows upward
function Core:UpdateLayoutForGrowthAnchor()
	local growthAnchor = PDS.Config.growthAnchor or "TOPLEFT"
	local isBottomAnchor = growthAnchor == "BOTTOMLEFT" or growthAnchor == "BOTTOM" or growthAnchor == "BOTTOMRIGHT"
	local titleBarHeight = PDS.Config.showTitleBar and 20 or 0

	-- Clear existing anchor points
	self.contentFrame:ClearAllPoints()
	if self.titleBar then
		self.titleBar:ClearAllPoints()
	end

	if isBottomAnchor then
		-- Title bar at bottom, content above it
		if self.titleBar and PDS.Config.showTitleBar then
			self.titleBar:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
			self.titleBar:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
		end
		self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
		self.contentFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, titleBarHeight)
	else
		-- Title bar at top (default), content below it
		if self.titleBar and PDS.Config.showTitleBar then
			self.titleBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
			self.titleBar:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
		end
		self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -titleBarHeight)
		self.contentFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
	end
end

-- Applies frame position from current Config values
-- Call this after loading a profile to update the physical frame position
-- Supports both absolute positioning (UIParent) and relative anchoring (to another frame)
function Core:ApplyFramePosition()
	if not self.frame or not PDS.Config then return end

	self.frame:ClearAllPoints()

	-- Check if we should anchor to another frame
	local anchorFrameName = PDS.Config.anchorFrame
	if anchorFrameName and anchorFrameName ~= "" then
		local anchorFrame = _G[anchorFrameName]
		if anchorFrame and anchorFrame.IsShown and anchorFrame:IsShown() then
			-- Use relative anchoring to the specified frame
			self.frame:SetPoint(
				PDS.Config.anchorPoint or "TOPLEFT",
				anchorFrame,
				PDS.Config.anchorRelPoint or "BOTTOMLEFT",
				PDS.Config.anchorOffsetX or 0,
				PDS.Config.anchorOffsetY or -5
			)
			return
		end
		-- Anchor frame not found or not visible, fall through to absolute positioning
	end

	-- Fallback to absolute positioning relative to UIParent
	self.frame:SetPoint(
		PDS.Config.framePoint or "CENTER",
		PDS.Config.frameX or 0,
		PDS.Config.frameY or 0
	)
end

-- Updates frame visibility based on display mode setting
-- Display modes: ALWAYS, PARTY_ONLY, RAID_ONLY
function Core:UpdateFrameVisibility()
	local PeaversCommons = _G.PeaversCommons
	PeaversCommons.VisibilityManager:UpdateVisibility(self.frame, PDS.Config, self.inCombat)
end

return Core
