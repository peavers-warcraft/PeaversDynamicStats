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
			self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -20)
		else
			self.titleBar:Hide()
			self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
		end

		self:AdjustFrameHeight()
		self:UpdateFrameLock()
	end
end

return Core
