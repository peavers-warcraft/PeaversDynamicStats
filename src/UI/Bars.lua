local _, PDS = ...
local Core = PDS.Core

-- Creates or recreates all stat bars based on current configuration
function Core:CreateBars()
	-- Clear existing bars
	for _, bar in ipairs(self.bars) do
		bar.frame:Hide()
	end
	self.bars = {}

	local yOffset = 0
	for _, statType in ipairs(PDS.Stats.STAT_ORDER) do
		if PDS.Config.showStats[statType] then
			local statName = PDS.Stats:GetName(statType)
			local bar = PDS.StatBar:New(self.contentFrame, statName, statType)
			bar:SetPosition(0, yOffset)

			local value = PDS.Stats:GetValue(statType)
			bar:Update(value)

			-- Ensure the color is properly applied
			bar:UpdateColor()

			table.insert(self.bars, bar)

			-- When barSpacing is 0, position bars exactly barHeight pixels apart
			if PDS.Config.barSpacing == 0 then
				yOffset = yOffset - PDS.Config.barHeight
			else
				yOffset = yOffset - (PDS.Config.barHeight + PDS.Config.barSpacing)
			end
		end
	end

	local contentHeight = math.abs(yOffset)
	if contentHeight == 0 then
		self.frame:SetHeight(20) -- Just title bar
	else
		self.frame:SetHeight(contentHeight + 20) -- Add title bar height
	end

	self:AdjustFrameHeight()
	self.frame:SetWidth(PDS.Config.frameWidth)
end

-- Updates all stat bars with latest values, only if they've changed
function Core:UpdateAllBars()
	if not self.previousValues then
		self.previousValues = {}
	end

	for _, bar in ipairs(self.bars) do
		local value = PDS.Stats:GetValue(bar.statType)
		local statKey = bar.statType

		if not self.previousValues[statKey] then
			self.previousValues[statKey] = 0
		end

		if value ~= self.previousValues[statKey] then
			-- Calculate the change in value
			local change = value - self.previousValues[statKey]

			-- Update the bar with the new value and change
			bar:Update(value, nil, change)

			-- Ensure the color is properly applied when updating
			bar:UpdateColor()

			-- Store the new value for next comparison
			self.previousValues[statKey] = value
		end
	end
end
