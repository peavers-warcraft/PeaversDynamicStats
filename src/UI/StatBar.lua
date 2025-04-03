local addonName, PDS = ...

-- Initialize StatBar namespace
PDS.StatBar = {}
local StatBar = PDS.StatBar

-- Creates a new stat bar instance
function StatBar:New(parent, name, statType)
	local obj = {}
	setmetatable(obj, { __index = StatBar })

	obj.name = name
	obj.statType = statType
	obj.value = 0
	obj.maxValue = 100
	obj.targetValue = 0
	obj.smoothing = true
	obj.yOffset = 0
	obj.frame = obj:CreateFrame(parent)

	-- Set the initial color after frame is created
	obj:UpdateColor()

	obj:InitAnimationSystem()
	obj:InitChangeTextFadeAnimation()
	obj:InitTooltip()

	return obj
end

-- Sets up the animation system for smooth value transitions
function StatBar:InitAnimationSystem()
	self.smoothing = true
	self.animationGroup = self.frame.bar:CreateAnimationGroup()
	self.valueAnimation = self.animationGroup:CreateAnimation("Progress")
	self.valueAnimation:SetDuration(0.3)
	self.valueAnimation:SetSmoothing("OUT")

	self.valueAnimation:SetScript("OnUpdate", function(anim)
		local progress = anim:GetProgress()
		local startValue = anim.startValue or 0
		local changeValue = anim.changeValue or 0
		local currentValue = startValue + (changeValue * progress)

		self.frame.bar:SetValue(currentValue)
	end)
end

-- Sets up the fade animation for the change indicator text
function StatBar:InitChangeTextFadeAnimation()
	-- Create animation group for the change text
	self.changeTextAnimGroup = self.frame.changeText:CreateAnimationGroup()

	-- Create alpha animation to fade out the text
	-- This animation will gradually reduce the opacity of the text from 100% to 0%
	self.changeTextFadeAnim = self.changeTextAnimGroup:CreateAnimation("Alpha")
	self.changeTextFadeAnim:SetFromAlpha(1.0)  -- Start fully visible
	self.changeTextFadeAnim:SetToAlpha(0.0)    -- End completely transparent
	self.changeTextFadeAnim:SetDuration(3.0)   -- Fade out over 3 seconds
	self.changeTextFadeAnim:SetStartDelay(1.0) -- Start fading after 1 second display
	self.changeTextFadeAnim:SetSmoothing("OUT") -- Ease out for smoother appearance

	-- Hide the text when the animation completes to ensure it's not taking up space
	-- and reset the alpha for the next time it needs to be displayed
	self.changeTextAnimGroup:SetScript("OnFinished", function()
		self.frame.changeText:SetText("")      -- Clear the text
		self.frame.changeText:SetAlpha(1.0)    -- Reset alpha for next display
	end)
end

-- Creates the visual elements of the stat bar
function StatBar:CreateFrame(parent)
	local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	frame:SetSize(PDS.Config.barWidth, PDS.Config.barHeight)

	local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	bg:SetBackdrop({
		bgFile = "Interface\\BUTTONS\\WHITE8X8",
		edgeFile = "Interface\\BUTTONS\\WHITE8X8",
		tile = true, edgeSize = 1,
	})
	bg:SetBackdropColor(0, 0, 0, PDS.Config.barBgAlpha)
	bg:SetBackdropBorderColor(0, 0, 0, PDS.Config.barBgAlpha)
	frame.bg = bg

	-- Create the status bar with explicit name to help with debugging
	local bar = CreateFrame("StatusBar", "PDS_StatBar_" .. self.statType, bg)
	bar:SetPoint("TOPLEFT", bg, "TOPLEFT", 1, -1)
	bar:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -1, 1)
	bar:SetMinMaxValues(0, 100)
	bar:SetValue(0)

	-- Set the status bar texture using the configured texture if available
	if PDS.Config.barTexture then
		bar:SetStatusBarTexture(PDS.Config.barTexture)
	else
		-- Fallback to a plain white texture if no texture path is configured
		local texture = bar:CreateTexture(nil, "ARTWORK")
		texture:SetAllPoints()
		texture:SetColorTexture(1, 1, 1, 1) -- White texture that will take color
		bar:SetStatusBarTexture(texture)
	end

	-- Set initial color
	bar:SetStatusBarColor(0.8, 0.8, 0.8, 1)

	frame.bar = bar

	-- Create the overflow bar that will show when value exceeds 100%
	local overflowBar = CreateFrame("StatusBar", "PDS_StatBar_Overflow_" .. self.statType, bg)
	overflowBar:SetPoint("TOPLEFT", bg, "TOPLEFT", 1, -1)
	overflowBar:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -1, 1)
	overflowBar:SetMinMaxValues(0, 100)
	overflowBar:SetValue(0)
	overflowBar:SetFrameLevel(bar:GetFrameLevel() + 1) -- Set higher frame level to ensure it's visible above the main bar

	-- Set the overflow bar texture
	if PDS.Config.barTexture then
		overflowBar:SetStatusBarTexture(PDS.Config.barTexture)
	else
		local texture = overflowBar:CreateTexture(nil, "ARTWORK")
		texture:SetAllPoints()
		texture:SetColorTexture(1, 1, 1, 1)
		overflowBar:SetStatusBarTexture(texture)
	end

	-- Initially hide the overflow bar
	overflowBar:Hide()

	frame.overflowBar = overflowBar

	-- Create a text layer frame that will be above both bars
	local textLayer = CreateFrame("Frame", nil, bar)
	textLayer:SetAllPoints()
	textLayer:SetFrameLevel(overflowBar:GetFrameLevel() + 1) -- Set higher than overflow bar

	local valueText = textLayer:CreateFontString(nil, "OVERLAY")
	valueText:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
	valueText:SetFont(PDS.Config.fontFace, PDS.Config.fontSize, PDS.Config.fontOutline)
	valueText:SetJustifyH("RIGHT")
	valueText:SetText("0")
	valueText:SetTextColor(1, 1, 1)
	if PDS.Config.fontShadow then
		valueText:SetShadowOffset(1, -1)
	else
		valueText:SetShadowOffset(0, 0)
	end
	frame.valueText = valueText

	local nameText = textLayer:CreateFontString(nil, "OVERLAY")
	nameText:SetPoint("LEFT", bar, "LEFT", 4, 0)
	nameText:SetFont(PDS.Config.fontFace, PDS.Config.fontSize, PDS.Config.fontOutline)
	nameText:SetJustifyH("LEFT")
	nameText:SetText(self.name)
	nameText:SetTextColor(1, 1, 1)
	if PDS.Config.fontShadow then
		nameText:SetShadowOffset(1, -1)
	else
		nameText:SetShadowOffset(0, 0)
	end
	frame.nameText = nameText

	-- Create change indicator text
	local changeText = textLayer:CreateFontString(nil, "OVERLAY")
	changeText:SetPoint("CENTER", bar, "CENTER", 0, 0)
	changeText:SetFont(PDS.Config.fontFace, PDS.Config.fontSize, PDS.Config.fontOutline)
	changeText:SetJustifyH("CENTER")
	changeText:SetText("")
	changeText:SetTextColor(1, 1, 1)
	if PDS.Config.fontShadow then
		changeText:SetShadowOffset(1, -1)
	else
		changeText:SetShadowOffset(0, 0)
	end
	frame.changeText = changeText

	-- Store the text layer for future reference
	frame.textLayer = textLayer

	return frame
end

-- Handle overflow bar visibility and tooltip initialization
function StatBar:HandleOverflow(overflowValue)
	if not self.frame.overflowBar then
		return false
	end

	-- Track overflow bar visibility changes to reinit tooltip if needed
	local overflowBarWasVisible = self.frame.overflowBar:IsVisible()
	local overflowBarShouldBeVisible = overflowValue > 0 and PDS.Config.showOverflowBars

	-- Show or hide the overflow bar based on the overflow value and global user preference
	if overflowBarShouldBeVisible then
		-- Show the overflow bar if user has enabled it
		self.frame.overflowBar:Show()
	else
		-- Hide the overflow bar if value is 100% or less, or if user has disabled overflow bars globally
		self.frame.overflowBar:Hide()
		self.frame.overflowBar:SetValue(0)
	end

	-- Return whether visibility changed (for tooltip reinitialization)
	return overflowBarWasVisible ~= overflowBarShouldBeVisible
end

-- Updates the bar with a new value, using animation for smooth transitions
function StatBar:Update(value, maxValue, change)
	if value ~= self.value then
		self.value = value or 0

		-- Get the bar values from Stats.lua
		local percentValue, overflowValue = PDS.Stats:CalculateBarValues(self.value)

		-- Handle overflow bar visibility and reinitialize tooltip if needed
		local visibilityChanged = self:HandleOverflow(overflowValue)
		if visibilityChanged then
			-- Force tooltip reinitialization when overflow bar visibility changes
			self.tooltipInitialized = false
			self:InitTooltip()
		end

		-- Get the formatted display value from Stats.lua
		local displayValue = PDS.Stats:GetDisplayValue(self.statType, self.value)

		local currentText = self.frame.valueText:GetText()
		if currentText ~= displayValue then
			self.frame.valueText:SetText(displayValue)
		end

		-- Update change indicator if showStatChanges is enabled
		if PDS.Config.showStatChanges and change and change ~= 0 then
			-- If there's an existing animation playing, we need to stop it
			-- before starting a new one to prevent visual glitches
			if self.changeTextAnimGroup then
				self.changeTextAnimGroup:Stop()
			end

			-- Reset alpha to full visibility for the new change display
			self.frame.changeText:SetAlpha(1.0)

			-- Get the formatted change display value and color from Stats.lua
			local changeDisplay, r, g, b = PDS.Stats:GetChangeDisplayValue(change)
			self.frame.changeText:SetText(changeDisplay)
			self.frame.changeText:SetTextColor(r, g, b)

			-- Start the fade-out animation to gradually hide the change indicator
			-- This will make the text fade out over a few seconds instead of staying static
			if self.changeTextAnimGroup then
				self.changeTextAnimGroup:Play()
			end
		else
			-- If there's no change or changes are disabled, just clear the text
			self.frame.changeText:SetText("")
		end

		-- Use animation if enabled, otherwise set value directly
		if self.smoothing then
			self:AnimateToValue(percentValue, overflowValue)
		else
			self.frame.bar:SetValue(percentValue)
			if self.frame.overflowBar then
				self.frame.overflowBar:SetValue(overflowValue)
			end
		end
	end
end

-- Animates the bar to a new value
function StatBar:AnimateToValue(newValue, overflowValue)
	self.animationGroup:Stop()

	-- Handle the main bar animation
	local currentValue = self.frame.bar:GetValue()

	if math.abs(newValue - currentValue) >= 0.5 then
		self.valueAnimation.startValue = currentValue
		self.valueAnimation.changeValue = newValue - currentValue
		self.animationGroup:Play()
	else
		self.frame.bar:SetValue(newValue)
	end

	-- Handle the overflow bar animation if it exists
	if self.frame.overflowBar then
		overflowValue = overflowValue or 0

		-- Handle overflow bar visibility and reinitialize tooltip if needed
		local visibilityChanged = self:HandleOverflow(overflowValue)
		if visibilityChanged then
			self:InitTooltip()
		end

		-- If overflow bar is visible, animate it
		if self.frame.overflowBar:IsVisible() then
			-- Create animation group for overflow bar if it doesn't exist
			if not self.overflowAnimationGroup then
				self.overflowAnimationGroup = self.frame.overflowBar:CreateAnimationGroup()
				self.overflowValueAnimation = self.overflowAnimationGroup:CreateAnimation("Progress")
				self.overflowValueAnimation:SetDuration(0.3)
				self.overflowValueAnimation:SetSmoothing("OUT")

				self.overflowValueAnimation:SetScript("OnUpdate", function(anim)
					local progress = anim:GetProgress()
					local startValue = anim.startValue or 0
					local changeValue = anim.changeValue or 0
					local currentValue = startValue + (changeValue * progress)

					self.frame.overflowBar:SetValue(currentValue)
				end)
			end

			-- Animate the overflow bar
			self.overflowAnimationGroup:Stop()

			local currentOverflowValue = self.frame.overflowBar:GetValue()

			if math.abs(overflowValue - currentOverflowValue) >= 0.5 then
				self.overflowValueAnimation.startValue = currentOverflowValue
				self.overflowValueAnimation.changeValue = overflowValue - currentOverflowValue
				self.overflowAnimationGroup:Play()
			else
				self.frame.overflowBar:SetValue(overflowValue)
			end
		end
	end
end

-- Returns the color for a specific stat type
function StatBar:GetColorForStat(statType)
	-- Check if there's a custom color for this stat
	if PDS.Config.customColors and PDS.Config.customColors[statType] then
		local color = PDS.Config.customColors[statType]
		if color and color.r and color.g and color.b then
			return color.r, color.g, color.b
		end
	end

	-- Fall back to default colors from STAT_COLORS
	if PDS.Stats.STAT_COLORS and PDS.Stats.STAT_COLORS[statType] then
		return unpack(PDS.Stats.STAT_COLORS[statType])
	end

	-- Ultimate fallback to ensure visibility
	return 0.8, 0.8, 0.8
end

-- Returns a contrasting color for the overflow portion of the bar
function StatBar:GetOverflowColor(r, g, b)
	-- Create a contrasting color by inverting the brightness
	-- If the original color is bright, make the overflow darker
	-- If the original color is dark, make the overflow brighter

	-- Calculate perceived brightness (using the formula for luminance)
	local brightness = 0.299 * r + 0.587 * g + 0.114 * b

	if brightness > 0.5 then
		-- Original color is bright, make overflow darker
		return r * 0.6, g * 0.6, b * 0.6
	else
		-- Original color is dark, make overflow brighter
		return math.min(r * 1.4, 1), math.min(g * 1.4, 1), math.min(b * 1.4, 1)
	end
end

-- Updates the color of the bar
function StatBar:UpdateColor()
	local r, g, b = self:GetColorForStat(self.statType)

	-- Ensure we have valid color values
	r = r or 0.8
	g = g or 0.8
	b = b or 0.8

	-- Apply the color to the status bar - set color directly without recreating texture
	if self.frame and self.frame.bar then
		self.frame.bar:SetStatusBarColor(r, g, b, 1)
	end

	-- Apply contrasting color to the overflow bar with transparency
	if self.frame and self.frame.overflowBar then
		local or_r, or_g, or_b = self:GetOverflowColor(r, g, b)
		self.frame.overflowBar:SetStatusBarColor(or_r, or_g, or_b, 0.7) -- Use 0.7 alpha for better visibility while still being distinct
	end
end

-- Sets the position of the bar relative to its parent
function StatBar:SetPosition(x, y)
	self.yOffset = y
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOPLEFT", self.frame:GetParent(), "TOPLEFT", x, y)
	self.frame:SetPoint("TOPRIGHT", self.frame:GetParent(), "TOPRIGHT", 0, y)
end

-- Sets the highlight/select state of the bar
function StatBar:SetSelected(selected)
	if selected then
		if not self.frame.highlight then
			local highlight = self.frame.bar:CreateTexture(nil, "OVERLAY")
			highlight:SetAllPoints()
			highlight:SetColorTexture(1, 1, 1, 0.1)
			self.frame.highlight = highlight
		end
		self.frame.highlight:Show()
	elseif self.frame.highlight then
		self.frame.highlight:Hide()
	end
end

-- Updates the font used for text elements
function StatBar:UpdateFont()
	self.frame.valueText:SetFont(PDS.Config.fontFace, PDS.Config.fontSize, PDS.Config.fontOutline)
	self.frame.nameText:SetFont(PDS.Config.fontFace, PDS.Config.fontSize, PDS.Config.fontOutline)
	self.frame.changeText:SetFont(PDS.Config.fontFace, PDS.Config.fontSize, PDS.Config.fontOutline)

	-- Apply shadow if enabled
	if PDS.Config.fontShadow then
		self.frame.valueText:SetShadowOffset(1, -1)
		self.frame.nameText:SetShadowOffset(1, -1)
		self.frame.changeText:SetShadowOffset(1, -1)
	else
		self.frame.valueText:SetShadowOffset(0, 0)
		self.frame.nameText:SetShadowOffset(0, 0)
		self.frame.changeText:SetShadowOffset(0, 0)
	end
end

-- Updates the texture used for the status bar
function StatBar:UpdateTexture()
	-- Use the configured texture path if available
	if PDS.Config.barTexture then
		self.frame.bar:SetStatusBarTexture(PDS.Config.barTexture)

		-- Also update the overflow bar texture if it exists
		if self.frame.overflowBar then
			self.frame.overflowBar:SetStatusBarTexture(PDS.Config.barTexture)
		end
	else
		-- Fallback to a plain white texture if no texture path is configured
		local texture = self.frame.bar:CreateTexture(nil, "ARTWORK")
		texture:SetAllPoints()
		texture:SetColorTexture(1, 1, 1, 1)
		self.frame.bar:SetStatusBarTexture(texture)

		-- Also update the overflow bar texture if it exists
		if self.frame.overflowBar then
			local overflowTexture = self.frame.overflowBar:CreateTexture(nil, "ARTWORK")
			overflowTexture:SetAllPoints()
			overflowTexture:SetColorTexture(1, 1, 1, 1)
			self.frame.overflowBar:SetStatusBarTexture(overflowTexture)
		end
	end

	-- Reapply color after updating texture
	self:UpdateColor()

	-- Force tooltip reinitialization
	self.tooltipInitialized = false
	self:InitTooltip()
end

-- Updates the height of the bar
function StatBar:UpdateHeight()
	self.frame:SetHeight(PDS.Config.barHeight)
end

-- Updates the width of the bar
function StatBar:UpdateWidth()
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOPLEFT", self.frame:GetParent(), "TOPLEFT", 0, self.yOffset)
	self.frame:SetPoint("TOPRIGHT", self.frame:GetParent(), "TOPRIGHT", 0, self.yOffset)
end

-- Updates the background opacity of the bar
function StatBar:UpdateBackgroundOpacity()
	self.frame.bg:SetBackdropColor(0, 0, 0, PDS.Config.barBgAlpha)
	self.frame.bg:SetBackdropBorderColor(0, 0, 0, PDS.Config.barBgAlpha)
end

-- Shows the tooltip with stat information
function StatBar:ShowTooltip(frame)
	-- Only show tooltip if enabled in config
	if not PDS.Config.showTooltips then
		return
	end

	-- Always ensure tooltip is initialized properly
	if not self.tooltipInitialized then
		self:InitTooltip()
	end

	-- Get current stat value and rating
	local value = PDS.Stats:GetValue(self.statType)
	local rating = PDS.Stats:GetRating(self.statType)

	-- Safety check before using the tooltip
	if not self.tooltip then
		self:InitTooltip()
	end

	-- Reset the tooltip
	self.tooltip:ClearLines()

	-- Position the tooltip
	self.tooltip:SetOwner(frame, "ANCHOR_RIGHT")

	-- Add tooltip content
	if PDS.StatTooltips then
		PDS.StatTooltips:ShowTooltip(self.tooltip, self.statType, value, rating)
	else
		-- Fallback if StatTooltips module is not available
		self.tooltip:SetText(PDS.Stats:GetName(self.statType))
		self.tooltip:AddLine(PDS.Utils:FormatPercent(value))
		self.tooltip:Show()
	end
end


-- Hides the tooltip
function StatBar:HideTooltip()
	if self.tooltip then
		self.tooltip:Hide()
	end
end

-- Sets up the tooltip for the stat bar
function StatBar:InitTooltip()
	-- Always destroy existing tooltip to prevent memory leaks and stale references
	if self.tooltip then
		self.tooltip:Hide()
		self.tooltip:ClearLines()
		self.tooltip = nil
	end

	-- Create a new tooltip with a unique name
	local tooltipName = "PDS_StatTooltip_" .. self.statType .. "_" .. tostring(self):gsub("table:", "")
	self.tooltip = CreateFrame("GameTooltip", tooltipName, UIParent, "GameTooltipTemplate")

	-- Set up mouse event handlers for main bar
	self.frame:SetScript("OnEnter", function()
		self:ShowTooltip(self.frame)
	end)

	self.frame:SetScript("OnLeave", function()
		self:HideTooltip()
	end)

	-- Set up mouse event handlers for overflow bar if it exists
	if self.frame.overflowBar then
		self.frame.overflowBar:SetScript("OnEnter", function()
			self:ShowTooltip(self.frame.overflowBar)
		end)

		self.frame.overflowBar:SetScript("OnLeave", function()
			self:HideTooltip()
		end)
	end

	-- Mark the tooltip as initialized
	self.tooltipInitialized = true
end

function StatBar:Destroy()
	-- Clean up the tooltip
	if self.tooltip then
		self.tooltip:Hide()
		self.tooltip:ClearLines()
		self.tooltip = nil
	end

	-- Hide and clear the frame
	if self.frame then
		self.frame:Hide()
		self.frame:SetScript("OnEnter", nil)
		self.frame:SetScript("OnLeave", nil)
	end

	-- Clear overflow bar scripts if it exists
	if self.frame and self.frame.overflowBar then
		self.frame.overflowBar:SetScript("OnEnter", nil)
		self.frame.overflowBar:SetScript("OnLeave", nil)
	end
end
