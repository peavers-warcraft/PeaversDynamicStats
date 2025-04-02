local addonName, PDS = ...

-- Initialize UI namespace
PDS.UI = {}
local UI = PDS.UI
local UIMetatable = {}

-- Safely access global variables by name
local function GetGlobal(name)
	if name and type(name) == "string" then
		return _G[name]
	end
	return nil
end

-- Creates a section header with gold text
function UI:CreateSectionHeader(parent, text, x, y)
	local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", x, y)
	header:SetText(text)
	header:SetTextColor(1, 0.82, 0) -- Gold color only for headers
	header:SetWidth(400)
	header:SetJustifyH("LEFT") -- Explicitly set left alignment
	return header, y - 25 -- Return new y position
end

-- Creates a text label with optional font
function UI:CreateLabel(parent, text, x, y, fontObject)
	local label = parent:CreateFontString(nil, "ARTWORK", fontObject or "GameFontNormal")
	label:SetPoint("TOPLEFT", x, y)
	label:SetText(text)
	label:SetTextColor(1, 1, 1) -- Explicitly set white color for all labels
	return label, y - 20 -- Return new y position
end

-- Creates a checkbox with optional initial value and click handler
function UI:CreateCheckbox(parent, name, text, x, y, initialValue, textColor, onClick)
	local checkbox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", x, y)

	local textObj = checkbox.Text
	if not textObj and checkbox:GetName() then
		textObj = GetGlobal(checkbox:GetName() .. "Text")
	end

	if textObj then
		textObj:SetText(text)
		textObj:SetFontObject("GameFontNormal")
		if textColor then
			textObj:SetTextColor(textColor[1], textColor[2], textColor[3])
		end
	end

	if initialValue ~= nil then
		checkbox:SetChecked(initialValue)
	end

	if onClick then
		checkbox:SetScript("OnClick", onClick)
	end

	return checkbox, y - 25 -- Return new y position
end

-- Creates a slider with min/max values and step size
function UI:CreateSlider(parent, name, minVal, maxVal, step, x, y, initialValue, width)
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", x, y)
	slider:SetWidth(width or 400)
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValueStep(step)
	slider:SetValue(initialValue)

	local sliderName = slider:GetName()
	if sliderName then
		local lowText = GetGlobal(sliderName .. "Low")
		local highText = GetGlobal(sliderName .. "High")
		local valueText = GetGlobal(sliderName .. "Text")

		if lowText then
			lowText:SetText("")
		end
		if highText then
			highText:SetText("")
		end
		if valueText then
			valueText:SetText("")
		end
	end

	return slider, y - 40 -- Return new y position
end

-- Creates a dropdown menu with optional initial text
function UI:CreateDropdown(parent, name, x, y, width, initialText)
	local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", x, y)
	UIDropDownMenu_SetWidth(dropdown, width or 360)

	if initialText then
		UIDropDownMenu_SetText(dropdown, initialText)
	end

	return dropdown, y - 40 -- Return new y position
end

-- Creates a scrollable frame with content child
function UI:CreateScrollFrame(parent)
	local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 16, -16)
	scrollFrame:SetPoint("BOTTOMRIGHT", -32, 16)

	local content = CreateFrame("Frame", nil, scrollFrame)
	scrollFrame:SetScrollChild(content)
	content:SetWidth(scrollFrame:GetWidth() - 16)
	content:SetHeight(1) -- Will be adjusted dynamically

	return scrollFrame, content
end

-- Creates a basic frame with optional size and backdrop
function UI:CreateFrame(name, parent, width, height, backdrop)
	local frame = CreateFrame("Frame", name, parent, backdrop and "BackdropTemplate" or nil)

	if width and height then
		frame:SetSize(width, height)
	end

	if backdrop then
		frame:SetBackdrop(backdrop)
	end

	return frame
end

-- Creates a button with optional size and click handler
function UI:CreateButton(parent, name, text, x, y, width, height, onClick)
	local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
	button:SetPoint("TOPLEFT", x, y)
	button:SetSize(width or 100, height or 22)
	button:SetText(text)

	if onClick then
		button:SetScript("OnClick", onClick)
	end

	return button, y - (height or 22) - 5
end

-- Creates a color picker button with optional label and change handler
function UI:CreateColorPicker(parent, name, label, x, y, initialColor, onChange)
	local colorFrame = CreateFrame("Button", name, parent, "BackdropTemplate")
	colorFrame:SetPoint("TOPLEFT", x, y)
	colorFrame:SetSize(16, 16)
	colorFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})

	if initialColor then
		colorFrame:SetBackdropColor(initialColor.r, initialColor.g, initialColor.b)
	else
		colorFrame:SetBackdropColor(1, 1, 1)
	end

	local colorLabel
	if label then
		colorLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		colorLabel:SetPoint("LEFT", colorFrame, "RIGHT", 5, 0)
		colorLabel:SetText(label)
	end

	colorFrame:SetScript("OnClick", function()
		local function ColorCallback(restore)
			local newR, newG, newB
			if restore then
				newR, newG, newB = unpack(restore)
			else
				-- Handle different API versions for getting color
				if ColorPickerFrame.GetColorRGB then
					newR, newG, newB = ColorPickerFrame:GetColorRGB()
				elseif ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.GetColorRGB then
					newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
				else
					-- Fallback to stored values if API methods aren't available
					newR, newG, newB = colorFrame:GetBackdropColor()
				end
			end

			colorFrame:SetBackdropColor(newR, newG, newB)

			if onChange then
				onChange(newR, newG, newB)
			end
		end

		local r, g, b = colorFrame:GetBackdropColor()

		-- Set both func and swatchFunc for compatibility with different API versions
		ColorPickerFrame.func = ColorCallback
		ColorPickerFrame.swatchFunc = ColorCallback
		ColorPickerFrame.cancelFunc = ColorCallback
		ColorPickerFrame.opacityFunc = nil
		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame.previousValues = { r, g, b }

		-- Handle different API versions for setting color
		if ColorPickerFrame.SetColorRGB then
			ColorPickerFrame:SetColorRGB(r, g, b)
		elseif ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.SetColorRGB then
			ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
		end

		ColorPickerFrame:Hide() -- Hide first to trigger OnShow handler
		ColorPickerFrame:Show()
	end)

	return colorFrame, colorLabel, y - 25
end

-- Creates a horizontal separator line
function UI:CreateSeparator(parent, x, y, width)
	local separator = parent:CreateTexture(nil, "ARTWORK")
	separator:SetPoint("TOPLEFT", x, y)
	separator:SetSize(width or 450, 1)
	separator:SetColorTexture(0.5, 0.5, 0.5, 0.5) -- Semi-transparent gray line

	return separator, y - 15 -- Return new y position with spacing
end

-- Set up OOP-like behavior
setmetatable(UI, UIMetatable)

return UI
