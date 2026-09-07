local addonName, PDS = ...

--------------------------------------------------------------------------------
-- Edit Mode
--
-- The bars are placed and configured in Blizzard's Edit Mode. All of the
-- machinery lives in PeaversCommons; what is here is the list of settings and
-- how to apply one after it changes.
--
-- The per-stat settings are the awkward part: sixteen stats, each with a
-- visibility toggle and two colours, which is forty-eight rows if listed flat.
-- The Stats group names one at a time with a selector instead, and the stat it
-- points at arrives as the context.
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons

local EditMode = {}
PDS.EditMode = EditMode

--------------------------------------------------------------------------------
-- Applying a change
--------------------------------------------------------------------------------

local function RefreshBars()
    if PDS.BarManager and PDS.Core and PDS.Core.contentFrame then
        PDS.BarManager:CreateBars(PDS.Core.contentFrame)
        PDS.Core:AdjustFrameHeight()
    end
end

-- Repaint one stat's bar without rebuilding the rest.
local function RecolourBar(statType, textOnly, r, g, b)
    if not (PDS.BarManager and PDS.BarManager.bars) then return end

    for _, bar in ipairs(PDS.BarManager.bars) do
        if bar.statType == statType then
            if textOnly then
                if bar.textManager then bar.textManager:SetTextColor(r, g, b) end
            else
                bar:UpdateColor()
            end
        end
    end
end

function PDS.ApplySetting(key, value)
    local Config = PDS.Config

    -- Per-stat settings carry their stat in the key.
    local statType = key:match("^stat%.[a-z]+%.(.+)$")
    if statType then
        if key:find("^stat%.show%.") then
            RefreshBars()
        elseif key:find("^stat%.bar%.") then
            RecolourBar(statType, false)
        elseif key:find("^stat%.text%.") then
            local c = value or {}
            RecolourBar(statType, true, c.r, c.g, c.b)
        end
        return
    end

    if key == "frameX" or key == "frameY" then
        if PDS.Core and PDS.Core.ApplyFramePosition then
            PDS.Core:ApplyFramePosition()
        end
        return
    end

    if key == "frameWidth" then
        -- The bars sit inside the frame, so their width follows it.
        Config.barWidth = value - 20
        if PDS.Core and PDS.Core.frame then
            PDS.Core.frame:SetWidth(value)
            if PDS.BarManager then PDS.BarManager:ResizeBars() end
        end
    elseif key == "bgAlpha" or key == "bgColor" then
        if PDS.Core and PDS.Core.frame then
            local color = Config.bgColor or { r = 0, g = 0, b = 0 }
            local alpha = Config.bgAlpha or 0.8
            PDS.Core.frame:SetBackdropColor(color.r, color.g, color.b, alpha)
            PDS.Core.frame:SetBackdropBorderColor(0, 0, 0, alpha)
            if PDS.Core.titleBar then
                PDS.Core.titleBar:SetBackdropColor(color.r, color.g, color.b, alpha)
                PDS.Core.titleBar:SetBackdropBorderColor(0, 0, 0, alpha)
            end
        end
    elseif key == "lockPosition" then
        if PDS.Core then PDS.Core:UpdateFrameLock() end
    elseif key == "showTitleBar" then
        if PDS.Core then PDS.Core:UpdateTitleBarVisibility() end
    elseif key == "barAlpha" or key == "barBgAlpha" or key == "barTexture" or key == "textAlpha" then
        if PDS.BarManager then PDS.BarManager:ResizeBars() end
    elseif key == "displayMode" or key == "hideOutOfCombat" or key == "showOnLogin" then
        if PDS.Core and PDS.Core.UpdateFrameVisibility then
            PDS.Core:UpdateFrameVisibility()
        end
    else
        -- Everything else changes what a bar shows or how it is drawn.
        RefreshBars()
    end
end

--------------------------------------------------------------------------------
-- Groups
--------------------------------------------------------------------------------

EditMode.SECTIONS = {
    { key = "frame", label = "Frame" },
    { key = "position", label = "Position" },
    { key = "bars", label = "Bars" },
    { key = "text", label = "Text" },
    {
        key = "stats", label = "Stats",
        -- Sixteen stats with three settings each. The settings page listed them
        -- all; naming one at a time is the only way this fits anywhere.
        selector = {
            label = "Stat",
            values = function()
                local out = {}
                for _, statType in ipairs(PDS.Stats.STAT_ORDER or {}) do
                    out[#out + 1] = { value = statType, label = PDS.Stats:GetName(statType) or statType }
                end
                return out
            end,
        },
    },
    { key = "behaviour", label = "Behaviour" },
}

-- Stats:GetColor hands back three numbers rather than a table.
local function DefaultBarColour(statType)
    local r, g, b = PDS.Stats:GetColor(statType)
    return { r = r or 1, g = g or 1, b = b or 1 }
end

EditMode.ENTRIES = {
    ----------------------------------------------------------------- frame ---
    { key = "frameWidth", section = "frame" },
    { key = "showTitleBar", section = "frame" },
    { key = "bgColor", section = "frame" },
    { key = "bgAlpha", section = "frame" },
    { key = "lockPosition", section = "frame" },

    -------------------------------------------------------------- position ---
    { key = "frameX", section = "position", kind = "number" },
    { key = "frameY", section = "position", kind = "number" },

    ------------------------------------------------------------------ bars ---
    { key = "barHeight", section = "bars" },
    { key = "barSpacing", section = "bars" },
    { key = "barAlpha", section = "bars" },
    { key = "barBgAlpha", section = "bars" },
    { key = "barTexture", section = "bars", height = 300 },
    {
        key = "growthAnchor", label = "Grow From", kind = "dropdown", section = "bars",
        fallback = "TOPLEFT",
        values = {
            { value = "TOPLEFT", label = "The top" },
            { value = "BOTTOMLEFT", label = "The bottom" },
        },
    },

    ------------------------------------------------------------------ text ---
    { key = "fontFace", section = "text", height = 300 },
    { key = "fontSize", section = "text" },
    { key = "fontOutline", section = "text" },
    { key = "fontShadow", section = "text" },
    { key = "textAlpha", section = "text" },
    {
        key = "showStatNames", label = "Show Stat Names", kind = "checkbox",
        section = "text", default = true,
    },
    {
        key = "showRatings", label = "Show Rating Values", kind = "checkbox",
        section = "text", default = true,
    },

    ----------------------------------------------------------------- stats ---
    -- All three are read and written against whichever stat the selector names.
    {
        key = "statShow", label = "Show This Stat", kind = "checkbox",
        section = "stats", default = true,
        getValue = function(config, statType)
            return (config.showStats or {})[statType] ~= false
        end,
        setValue = function(config, statType, value)
            config.showStats = config.showStats or {}
            config.showStats[statType] = value
        end,
    },
    {
        key = "statBarColour", label = "Bar Colour", kind = "color", section = "stats",
        default = { r = 1, g = 1, b = 1 },
        getValue = function(config, statType)
            return (config.customColors or {})[statType] or DefaultBarColour(statType)
        end,
        setValue = function(config, statType, value)
            config.customColors = config.customColors or {}
            config.customColors[statType] = value
        end,
    },
    {
        key = "statTextColour", label = "Text Colour", kind = "color", section = "stats",
        default = { r = 1, g = 1, b = 1 },
        getValue = function(config, statType)
            return (config.customTextColors or {})[statType] or { r = 1, g = 1, b = 1 }
        end,
        setValue = function(config, statType, value)
            config.customTextColors = config.customTextColors or {}
            config.customTextColors[statType] = value
        end,
    },

    ------------------------------------------------------------- behaviour ---
    { key = "showOnLogin", section = "behaviour" },
    { key = "hideOutOfCombat", section = "behaviour" },
    { key = "displayMode", section = "behaviour" },
    {
        key = "combatUpdateInterval", label = "Combat Update Interval", kind = "slider",
        section = "behaviour", min = 0.1, max = 1.0, step = 0.05, default = 0.2,
    },
    {
        key = "autoHideZeroStats", label = "Hide Stats At Zero", kind = "checkbox",
        section = "behaviour", default = true,
    },
    {
        key = "showOverflowBars", label = "Show Overflow Bars", kind = "checkbox",
        section = "behaviour", default = true,
        desc = "Lets a bar read past 100% rather than stopping at full.",
    },
    {
        key = "showStatChanges", label = "Show Stat Changes", kind = "checkbox",
        section = "behaviour", default = true,
    },
    {
        key = "persistStatChanges", label = "Keep Changes Between Sessions",
        kind = "checkbox", section = "behaviour", default = false,
    },
    {
        key = "showRawValues", label = "Fill By Raw Rating", kind = "checkbox",
        section = "behaviour", default = false, revealsOthers = true,
    },
    {
        key = "rawValueMax", label = "Maximum Rating", kind = "slider",
        section = "behaviour", min = 0, max = 20000, step = 100, default = 0,
        desc = "Zero picks the maximum from whichever bar is currently highest.",
        hidden = function(cfg) return not cfg.showRawValues end,
    },
    {
        key = "sortBarsByRating", label = "Sort By Rating", kind = "checkbox",
        section = "behaviour", default = false,
    },
    {
        key = "showTooltips", label = "Show Tooltips", kind = "checkbox",
        section = "behaviour", default = true,
    },
    {
        key = "enableTalentAdjustments", label = "Adjust For Talents", kind = "checkbox",
        section = "behaviour", default = true,
    },
    {
        key = "highlightHighestRating", label = "Highlight The Highest Stat",
        kind = "checkbox", section = "behaviour", default = false, revealsOthers = true,
    },
    {
        key = "highlightStyle", label = "Highlight Style", kind = "dropdown",
        section = "behaviour", fallback = "SUBTLE",
        hidden = function(cfg) return not cfg.highlightHighestRating end,
        values = {
            { value = "STATIC", label = "Static border" },
            { value = "SUBTLE", label = "Marching dots (subtle)" },
            { value = "GLOW", label = "Marching dots (glow)" },
            { value = "BRIGHT", label = "Marching dots (bright)" },
        },
    },
    {
        key = "highlightShowIcon", label = "Highlight With An Icon", kind = "checkbox",
        section = "behaviour", default = false,
        hidden = function(cfg) return not cfg.highlightHighestRating end,
    },
}

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

-- Edit Mode reports an anchor point and an offset, which is exactly what this
-- addon already stores. Nothing to convert, nothing to migrate.
local function SavePosition(_, point, x, y)
    PDS.Config.framePoint = point
    PDS.Config.frameX = x
    PDS.Config.frameY = y
    PDS.Config:Save()
end

-- The frame drags itself when unlocked, and Edit Mode drags it through its own
-- overlay. Both at once means two systems answering one drag.
local function ReleaseDragging(frame)
    for _, target in ipairs({ frame, PDS.Core.contentFrame }) do
        if target then
            target:RegisterForDrag()
            target:SetScript("OnDragStart", nil)
            target:SetScript("OnDragStop", nil)
        end
    end
end

function EditMode:BuildSchema()
    if self.schema then return self.schema end

    self.schema = PeaversCommons.SettingsSchema:New({
        config = PDS.Config,
        sections = self.SECTIONS,
        entries = self.ENTRIES,
        apply = function(entry, context, value)
            -- Per-stat settings need to say which stat they were for.
            local key = entry.key
            if context and entry.getValue then
                if key == "statShow" then key = "stat.show." .. context
                elseif key == "statBarColour" then key = "stat.bar." .. context
                elseif key == "statTextColour" then key = "stat.text." .. context
                end
            end
            PDS.ApplySetting(key, value)
        end,
    })

    return self.schema
end

function EditMode:Register()
    if not PeaversCommons.EditMode or not PeaversCommons.EditMode.available then
        return false
    end
    if not PDS.Core or not PDS.Core.frame then return false end

    PeaversCommons.EditMode:Register({
        frame = PDS.Core.frame,
        name = "Peavers Dynamic Stats",
        schema = self:BuildSchema(),
        default = {
            point = PDS.Config.defaults and PDS.Config.defaults.framePoint or "RIGHT",
            x = PDS.Config.defaults and PDS.Config.defaults.frameX or -20,
            y = PDS.Config.defaults and PDS.Config.defaults.frameY or 0,
        },
        onPositionChanged = SavePosition,
        onEnter = function(frame)
            ReleaseDragging(frame)
            -- The bars can be hidden by the visibility rules, and a hidden frame
            -- takes its own Edit Mode handle down with it.
            frame:Show()
        end,
        onExit = function()
            if PDS.Core.UpdateFrameLock then PDS.Core:UpdateFrameLock() end
            if PDS.Core.UpdateFrameVisibility then PDS.Core:UpdateFrameVisibility() end
        end,
    })

    return true
end

return EditMode
