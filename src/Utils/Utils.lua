--------------------------------------------------------------------------------
-- PeaversDynamicStats Utils
-- Thin wrapper around PeaversCommons.Utils for addon-specific functionality
--------------------------------------------------------------------------------

local addonName, PDS = ...

-- Access PeaversCommons utilities
local PeaversCommons = _G.PeaversCommons
local CommonUtils = PeaversCommons.Utils

-- Initialize Utils namespace
PDS.Utils = {}
local Utils = PDS.Utils

-- Print a message to the chat frame with addon prefix
function Utils.Print(message)
    if not message then return end
    CommonUtils.Print(PDS, message)
end

-- Debug print only when debug mode is enabled
function Utils.Debug(message)
    if not message then return end
    CommonUtils.Debug(PDS, message)
end

-- Delegate common utility functions to PeaversCommons.Utils
Utils.FormatPercent = CommonUtils.FormatPercent
Utils.FormatChange = CommonUtils.FormatChange
Utils.FormatTime = CommonUtils.FormatTime
Utils.Round = CommonUtils.Round
Utils.TableContains = CommonUtils.TableContains
Utils.GetPlayerInfo = CommonUtils.GetPlayerInfo
Utils.GetCharacterKey = CommonUtils.GetCharacterKey
Utils.DeepCopy = CommonUtils.DeepCopy
Utils.MergeDefaults = CommonUtils.MergeDefaults

return Utils
