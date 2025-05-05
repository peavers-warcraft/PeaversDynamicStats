local addonName, PDS = ...

-- Initialize SaveGuard namespace
PDS.SaveGuard = {}
local SaveGuard = PDS.SaveGuard

-- Timer to control save frequency
local saveTimer = nil

-- Last save time to avoid too frequent saving
local lastSaveTime = 0

-- Queue a save operation with throttling
function SaveGuard:QueueSave()
    -- Cancel any pending timer
    if saveTimer then
        saveTimer:Cancel()
        saveTimer = nil
    end
    
    -- Only save if more than 2 seconds since last save
    local currentTime = GetTime()
    if (currentTime - lastSaveTime) < 2 then
        -- Schedule delayed save
        saveTimer = C_Timer.NewTimer(2, function()
            self:ForceSave()
            saveTimer = nil
        end)
    else
        -- Save immediately
        self:ForceSave()
    end
end

-- Force immediate save
function SaveGuard:ForceSave()
    if PDS.Config then
        PDS.Config:Save()
        lastSaveTime = GetTime()
    end
end

-- Load saved settings
function SaveGuard:LoadSettings()
    if PDS.Config and PDS.Config.Load then
        PDS.Config:Load()
    end
end

-- Initialize the save guard system
function SaveGuard:Initialize()
    -- Create frame to catch events
    local frame = CreateFrame("Frame")
    
    -- Register for critical events
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD") 
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("VARIABLES_LOADED")
    
    -- Set up event handler
    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_LOGOUT" then
            -- Always force save on logout
            SaveGuard:ForceSave()
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Handle UI reload
            C_Timer.After(0.5, function()
                -- Load first, then save to ensure persistence
                SaveGuard:LoadSettings()
                SaveGuard:ForceSave()
            end)
        elseif event == "ADDON_LOADED" and arg1 == addonName then
            -- Initialize save system when our addon loads
            C_Timer.After(1, function()
                -- Make sure we have the latest settings when our addon loads
                SaveGuard:LoadSettings()
                -- Then save to ensure persistence
                SaveGuard:ForceSave()
            end)
        elseif event == "VARIABLES_LOADED" then
            -- Make sure we save after variables are loaded
            SaveGuard:QueueSave()
        end
    end)
    
    -- Add a repeating timer to periodically save settings
    C_Timer.NewTicker(30, function()
        SaveGuard:QueueSave()
    end)
    
    -- Hook the Settings UI if it exists
    if Settings then
        if Settings.CloseUI then
            hooksecurefunc(Settings, "CloseUI", function()
                SaveGuard:ForceSave()
            end)
        end
    end
    
    -- For older clients
    if InterfaceOptionsFrame then
        InterfaceOptionsFrame:HookScript("OnHide", function()
            SaveGuard:ForceSave()
        end)
    end
end

return SaveGuard