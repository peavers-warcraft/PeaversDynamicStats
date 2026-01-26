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
	self.frame:SetPoint(PDS.Config.framePoint, PDS.Config.frameX, PDS.Config.frameY)
	self:UpdateFrameLock()

	local inCombat = InCombatLockdown()
	self.inCombat = inCombat

	if PDS.Config.showOnLogin then
		if PDS.Config.hideOutOfCombat and not inCombat then
			self.frame:Hide()
		else
			self.frame:Show()
		end
	else
		self.frame:Hide()
	end
	
	if PDS.Config.hideOutOfCombat and not inCombat then
		self.frame:Hide()
	end
end

function Core:AdjustFrameHeight()
	PDS.BarManager:AdjustFrameHeight(self.frame, self.contentFrame, PDS.Config.showTitleBar)
end

function Core:UpdateFrameLock()
	if PDS.Config.lockPosition then
		self.frame:SetMovable(false)
		self.frame:EnableMouse(true)
		self.frame:RegisterForDrag("")
		self.frame:SetScript("OnDragStart", nil)
		self.frame:SetScript("OnDragStop", nil)
		
		self.contentFrame:SetMovable(false)
		self.contentFrame:EnableMouse(true)
		self.contentFrame:RegisterForDrag("")
		self.contentFrame:SetScript("OnDragStart", nil)
		self.contentFrame:SetScript("OnDragStop", nil)
	else
		self.frame:SetMovable(true)
		self.frame:EnableMouse(true)
		self.frame:RegisterForDrag("LeftButton")
		self.frame:SetScript("OnDragStart", self.frame.StartMoving)
		self.frame:SetScript("OnDragStop", function(frame)
			frame:StopMovingOrSizing()

			local point, _, _, x, y = frame:GetPoint()
			PDS.Config.framePoint = point
			PDS.Config.frameX = x
			PDS.Config.frameY = y
			PDS.Config:Save()
		end)
		
		self.contentFrame:SetMovable(true)
		self.contentFrame:EnableMouse(true)
		self.contentFrame:RegisterForDrag("LeftButton")
		self.contentFrame:SetScript("OnDragStart", function()
			self.frame:StartMoving()
		end)
		self.contentFrame:SetScript("OnDragStop", function()
			self.frame:StopMovingOrSizing()
			
			local point, _, _, x, y = self.frame:GetPoint()
			PDS.Config.framePoint = point
			PDS.Config.frameX = x
			PDS.Config.frameY = y
			PDS.Config:Save()
		end)
	end
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
function Core:ApplyFramePosition()
	if self.frame and PDS.Config then
		self.frame:ClearAllPoints()
		self.frame:SetPoint(
			PDS.Config.framePoint or "CENTER",
			PDS.Config.frameX or 0,
			PDS.Config.frameY or 0
		)
	end
end

-- Updates frame visibility based on display mode setting
-- Display modes: ALWAYS, PARTY_ONLY, RAID_ONLY
function Core:UpdateFrameVisibility()
	if not self.frame then return end

	local displayMode = PDS.Config.displayMode or "ALWAYS"

	-- Check if we should hide due to hideOutOfCombat setting
	if PDS.Config.hideOutOfCombat and not self.inCombat then
		self.frame:Hide()
		return
	end

	-- Check display mode
	if displayMode == "ALWAYS" then
		self.frame:Show()
	elseif displayMode == "PARTY_ONLY" then
		-- Show if in a party (but not a raid) or solo
		local inRaid = IsInRaid()
		local inParty = IsInGroup()
		if inParty and not inRaid then
			self.frame:Show()
		else
			self.frame:Hide()
		end
	elseif displayMode == "RAID_ONLY" then
		-- Show only if in a raid
		if IsInRaid() then
			self.frame:Show()
		else
			self.frame:Hide()
		end
	else
		-- Default to showing
		self.frame:Show()
	end
end

return Core
