local addonName, PDS = ...

-- Initialize UI namespace
PDS.UI = {}
local UI = PDS.UI
local UIMetatable = {}

-- Access PeaversCommons utilities
local PeaversCommons = _G.PeaversCommons
local FrameUtils = PeaversCommons.FrameUtils

-- Forward all UI creation methods to FrameUtils
function UI:CreateSectionHeader(parent, text, x, y)
    return FrameUtils.CreateSectionHeader(parent, text, x, y)
end

function UI:CreateLabel(parent, text, x, y, fontObject)
    return FrameUtils.CreateLabel(parent, text, x, y, fontObject)
end

function UI:CreateCheckbox(parent, name, text, x, y, initialValue, textColor, onClick)
    return FrameUtils.CreateCheckbox(parent, name, text, x, y, initialValue, textColor, onClick)
end

function UI:CreateSlider(parent, name, minVal, maxVal, step, x, y, initialValue, width)
    return FrameUtils.CreateSlider(parent, name, minVal, maxVal, step, x, y, initialValue, width)
end

function UI:CreateDropdown(parent, name, x, y, width, initialText)
    return FrameUtils.CreateDropdown(parent, name, x, y, width, initialText)
end

function UI:CreateScrollFrame(parent)
    return FrameUtils.CreateScrollFrame(parent)
end

function UI:CreateFrame(name, parent, width, height, backdrop)
    return FrameUtils.CreateFrame(name, parent, width, height, backdrop)
end

function UI:CreateButton(parent, name, text, x, y, width, height, onClick)
    return FrameUtils.CreateButton(parent, name, text, x, y, width, height, onClick)
end

function UI:CreateColorPicker(parent, name, label, x, y, initialColor, onChange)
    return FrameUtils.CreateColorPicker(parent, name, label, x, y, initialColor, onChange)
end

function UI:CreateSeparator(parent, x, y, width)
    return FrameUtils.CreateSeparator(parent, x, y, width)
end

-- Set up OOP-like behavior
setmetatable(UI, UIMetatable)

return UI
