local addonName, PDS = ...
local Core = {}
PDS.Core = Core

function Core:Initialize()
	PDS.Stats:InitializeBaseValues()
	
	if PDS.Config and PDS.Config.InitializeStatSettings then
		PDS.Config:InitializeStatSettings()
	end
	
	if PDS.StatHistory then
		PDS.StatHistory:Initialize()
	end

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
	self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -20)
	self.contentFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)

	self:UpdateTitleBarVisibility()

	-- Create bars using the BarManager
	PDS.BarManager:CreateBars(self.contentFrame)

	-- Adjust frame height based on visible bars
	self:AdjustFrameHeight()

	-- Now set the position after bars are created and frame height is adjusted
	self.frame:SetPoint(PDS.Config.framePoint, PDS.Config.frameX, PDS.Config.frameY)

	self:UpdateFrameLock()

	local inCombat = InCombatLockdown()

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

-- Registers all required events
function Core:RegisterEvents()
	local frame = CreateFrame("Frame")
	self.eventFrame = frame

	frame:RegisterEvent("UNIT_STATS")
	frame:RegisterEvent("UNIT_AURA")
	frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

	-- Set up event and update handlers
	frame:SetScript("OnEvent", function(self, event, ...)
		Core:OnEvent(event, ...)
	end)
	frame:SetScript("OnUpdate", function(self, elapsed)
		Core:OnUpdate(elapsed)
	end)
end

-- Recalculates frame height based on number of bars and title bar visibility
function Core:AdjustFrameHeight()
	-- Use the BarManager to adjust frame height
	PDS.BarManager:AdjustFrameHeight(self.frame, self.contentFrame, PDS.Config.showTitleBar)
end

-- Enables or disables frame dragging based on lock setting
function Core:UpdateFrameLock()
	if PDS.Config.lockPosition then
		self.frame:SetMovable(false)
		self.frame:EnableMouse(true) -- Keep mouse enabled for tooltips
		self.frame:RegisterForDrag("")
		self.frame:SetScript("OnDragStart", nil)
		self.frame:SetScript("OnDragStop", nil)
		
		-- Make content frame draggable if title bar is hidden
		self.contentFrame:SetMovable(false)
		self.contentFrame:EnableMouse(true) -- Keep mouse enabled for tooltips
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
		
		-- Make content frame draggable when title bar is hidden
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

-- Shows or hides the title bar and adjusts content frame accordingly
function Core:UpdateTitleBarVisibility()
	if self.titleBar then
		if PDS.Config.showTitleBar then
			self.titleBar:Show()
			self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -20)
		else
			self.titleBar:Hide()
			self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
		end

		self:AdjustFrameHeight()
		self:UpdateFrameLock() -- Update dragging behavior when title bar visibility changes
	end
end

return Core
