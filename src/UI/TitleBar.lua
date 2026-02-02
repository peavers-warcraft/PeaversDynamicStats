local addonName, PDS = ...

--------------------------------------------------------------------------------
-- PDS TitleBar - Uses PeaversCommons.TitleBar
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons

-- Initialize TitleBar namespace
PDS.TitleBar = {}
local TitleBar = PDS.TitleBar

-- Creates the title bar using PeaversCommons.TitleBar
function TitleBar:Create(parentFrame)
    return PeaversCommons.TitleBar:Create(parentFrame, PDS.Config, {
        title = "PDS",
        version = PDS.version or "1.0.0",
        leftPadding = 5
    })
end

return TitleBar
