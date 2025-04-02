local _, PDS = ...
local TitleBar = {}
PDS.TitleBar = TitleBar

-- Creates the title bar with text and version display
function TitleBar:Create(parentFrame)
	local titleBar = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
	titleBar:SetHeight(20)
	titleBar:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
	titleBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 0, 0)
	titleBar:SetBackdrop({
		bgFile = "Interface\\BUTTONS\\WHITE8X8",
		edgeFile = "Interface\\BUTTONS\\WHITE8X8",
		tile = true, tileSize = 16, edgeSize = 1,
	})

	titleBar:SetBackdropColor(PDS.Config.bgColor.r, PDS.Config.bgColor.g, PDS.Config.bgColor.b, PDS.Config.bgAlpha)
	titleBar:SetBackdropBorderColor(0, 0, 0, 1)

	local title = titleBar:CreateFontString(nil, "OVERLAY")
	title:SetFont(PDS.Config.fontFace, PDS.Config.fontSize, PDS.Config.fontOutline)
	title:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
	title:SetText("Peavers Dynamic Stats")
	title:SetTextColor(1, 1, 1)

	local verticalLine = titleBar:CreateTexture(nil, "ARTWORK")
	verticalLine:SetSize(1, 16)
	verticalLine:SetPoint("LEFT", title, "RIGHT", 5, 0)
	verticalLine:SetColorTexture(0.3, 0.3, 0.3, 0.5)

	local subtitle = titleBar:CreateFontString(nil, "OVERLAY")
	subtitle:SetFont(PDS.Config.fontFace, PDS.Config.fontSize, PDS.Config.fontOutline)
	subtitle:SetPoint("LEFT", verticalLine, "RIGHT", 5, 0)
	subtitle:SetText("v" .. (PDS.version or "1.0.5"))
	subtitle:SetTextColor(0.8, 0.8, 0.8)

	return titleBar
end

return TitleBar
