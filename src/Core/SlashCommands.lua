local _, PDS = ...
local Core = PDS.Core

-- Register slash command handler for /pds
SLASH_PEAVERSDYNAMICSTATS1 = "/pds"
SlashCmdList["PEAVERSDYNAMICSTATS"] = function(msg)
	if msg == "config" or msg == "options" then
		-- Open configuration panel
		if PDS.Config.OpenOptionsCommand then
			PDS.Config.OpenOptionsCommand()
		else
			-- Fallback to direct category opening
			if Settings and Settings.OpenToCategory then
				Settings.OpenToCategory("PeaversDynamicStats")
			else
				InterfaceOptionsFrame_OpenToCategory("PeaversDynamicStats")
				InterfaceOptionsFrame_OpenToCategory("PeaversDynamicStats")
			end
		end
	else
		-- Toggle main frame visibility
		if Core.frame:IsShown() then
			Core.frame:Hide()
		else
			Core.frame:Show()
		end
	end
end
