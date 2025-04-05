local addonName, PDS = ...
local Core = PDS.Core

local updateTimer = 0
local inCombat = false

-- Handles WoW events to update the addon state
function Core:OnEvent(event, ...)
	if event == "UNIT_STATS" or event == "UNIT_AURA" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
		PDS.BarManager:UpdateAllBars()
	elseif event == "PLAYER_REGEN_DISABLED" then
		inCombat = true
		-- Always show the frame when entering combat if hideOutOfCombat is enabled
		if PDS.Config.hideOutOfCombat and not PDS.Core.frame:IsShown() then
			PDS.Core.frame:Show()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		inCombat = false
		-- Hide the frame when leaving combat if hideOutOfCombat is enabled
		if PDS.Config.hideOutOfCombat and PDS.Core.frame:IsShown() then
			PDS.Core.frame:Hide()
		end
	end
end

-- Handles periodic updates with different intervals for combat/non-combat
function Core:OnUpdate(elapsed)
	updateTimer = updateTimer + elapsed

	local interval = inCombat and PDS.Config.combatUpdateInterval or 2.0 -- 2 seconds when out of combat

	if updateTimer >= interval then
		PDS.BarManager:UpdateAllBars()

		-- Record stat history if the module is available
		if PDS.StatHistory then
			PDS.StatHistory:RecordStats()
		end

		updateTimer = 0
	end
end
