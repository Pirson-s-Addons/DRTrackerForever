local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- OPCIONES
-- ==========================================
-- Raiz "Acerca de" (UI/About.lua) y, colgando de ella, "General" con los
-- ajustes: panel propio con la plantilla de todos los addons de Pirson
-- (titulo, logo con version, secciones en morado y "Valores por defecto").

local HEADER = "|cffC47FF3"
local LOGO = "Interface\\AddOns\\DRTrackerForever\\img\\logo_drf"
local X = 16
-- Lo que devuelve "Valores por defecto": los ajustes del panel, no la posicion
local PANEL_KEYS = { "showTarget", "showFocus", "showPlayer", "npcs", "group", "resetTime", "locked", "size", "showText" }

local function AddTooltip(widget, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Header(panel, y, text)
    local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", X, y)
    fs:SetText(HEADER .. text .. "|r")
end

local function Separator(panel, y)
    local line = panel:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.1)
    line:SetSize(580, 1)
    line:SetPoint("TOPLEFT", X, y)
end

-- Devuelve la subcategoria General (destino de /drf)
function ns.CreateOptions()
    local db = ns.db
    local panel = CreateFrame("Frame")
    panel:Hide() -- nace oculto: si no, el Show() al abrir la categoria no dispara OnShow
    local widgets = {}

    local function Checkbox(key, label, tooltip, y)
        local cb = CreateFrame("CheckButton", "DRTrackerForever_" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", X, y)
        _G[cb:GetName() .. "Text"]:SetText(label)
        cb:SetScript("OnClick", function(self)
            db[key] = self:GetChecked() and true or false
            ns.ApplyDisplay()
        end)
        AddTooltip(cb, tooltip)
        cb.Refresh = function(self) self:SetChecked(db[key]) end
        widgets[#widgets + 1] = cb
    end

    local function Slider(key, label, tooltip, y, min, max, step, format)
        local slider = CreateFrame("Slider", "DRTrackerForever_" .. key, panel, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", X + 10, y)
        slider:SetWidth(400)
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        local name = slider:GetName()
        _G[name .. "Low"]:SetText(format(min))
        _G[name .. "High"]:SetText(format(max))
        local function Label() _G[name .. "Text"]:SetText(label .. ": " .. format(db[key])) end
        slider:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value / step + 0.5) * step
            if value == db[key] then return end
            db[key] = value
            Label()
            ns.ApplyDisplay()
        end)
        AddTooltip(slider, tooltip)
        slider.Refresh = function(self)
            self:SetValue(db[key])
            Label()
        end
        widgets[#widgets + 1] = slider
    end

    local function Seconds(value) return string.format("%d s", value) end
    local function Pixels(value) return string.format("%d px", value) end

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", X, -16)
    title:SetText(L.OPTIONS_TITLE)

    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(110, 110)
    logo:SetPoint("TOPRIGHT", -38, -5)
    logo:SetTexture(LOGO)

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOP", logo, "BOTTOM", 0, -2)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    Header(panel, -56, L.SHOW_HEADER)
    Checkbox("showTarget", L.SHOW_TARGET, L.SHOW_TARGET_TOOLTIP, -81)
    Checkbox("showFocus", L.SHOW_FOCUS, L.SHOW_FOCUS_TOOLTIP, -111)
    Checkbox("showPlayer", L.SHOW_PLAYER, L.SHOW_PLAYER_TOOLTIP, -141)
    Separator(panel, -176)

    Header(panel, -196, L.TRACK_HEADER)
    Checkbox("npcs", L.NPCS, L.NPCS_TOOLTIP, -221)
    Checkbox("group", L.GROUP, L.GROUP_TOOLTIP, -251)
    Slider("resetTime", L.RESET_TIME, L.RESET_TIME_TOOLTIP, -305, 15, 20, 1, Seconds)
    Separator(panel, -345)

    Header(panel, -365, L.LOOK_HEADER)
    Checkbox("locked", L.LOCK, L.LOCK_TOOLTIP, -390)
    Checkbox("showText", L.SHOW_TEXT, L.SHOW_TEXT_TOOLTIP, -420)
    Slider("size", L.SIZE, L.SIZE_TOOLTIP, -474, 20, 48, 1, Pixels)
    Separator(panel, -514)

    local function Refresh()
        for _, widget in ipairs(widgets) do widget:Refresh() end
    end
    panel:SetScript("OnShow", Refresh)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetPoint("TOPLEFT", X, -534)
    reset:SetText(L.DEFAULTS)
    reset:SetScript("OnClick", function()
        for _, key in ipairs(PANEL_KEYS) do db[key] = ns.DEFAULTS[key] end
        ns.ResetPositions()
        Refresh()
    end)

    local preview = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    preview:SetSize(180, 26)
    preview:SetPoint("LEFT", reset, "RIGHT", 12, 0)
    preview:SetText(L.PREVIEW)
    preview:SetScript("OnClick", function() ns.Preview(20) end)
    AddTooltip(preview, L.PREVIEW_TOOLTIP)

    local root = ns.CreateAbout({
        name = "DR Tracker Forever",
        logo = LOGO,
        github = "https://github.com/Pirson-s-Addons/DRTrackerForever",
        curseforge = "https://www.curseforge.com/wow/addons/dr-tracker-forever",
        commands = {
            { "/drf", L.CMD_OPEN },
            { "/drf unlock", L.CMD_UNLOCK },
            { "/drf lock", L.CMD_LOCK },
            { "/drf test", L.CMD_TEST },
            { "/drf clear", L.CMD_CLEAR },
        },
    })
    return Settings.RegisterCanvasLayoutSubcategory(root, panel, L.GENERAL_HEADER)
end
