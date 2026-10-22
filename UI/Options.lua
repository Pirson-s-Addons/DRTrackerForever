local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- OPCIONES
-- ==========================================
-- Raiz "Acerca de" (UI/About.lua) y, colgando de ella, una pestana por cosa:
-- General, Seguimiento, Apariencia y Posicion. Cada una es un panel propio con
-- la plantilla de todos los addons de Pirson (titulo, logo con version,
-- seccion en morado y "Valores por defecto" de lo suyo).

local HEADER = "|cffC47FF3"
local LOGO = "Interface\\AddOns\\DRTrackerForever\\img\\logo_drf"
local X = 16

local function AddTooltip(widget, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Separator(panel, y)
    local line = panel:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.1)
    line:SetSize(580, 1)
    line:SetPoint("TOPLEFT", X, y)
end

local function Seconds(value) return string.format("%d s", value) end
local function Pixels(value) return string.format("%d px", value) end

local pages = {}

-- Pestana con titulo, logo y cabecera; los controles se anaden con sus metodos
-- y Finish(y) pone el separador y los botones debajo del ultimo
local function NewPage(header, keys)
    local db = ns.db
    local page = { widgets = {}, keys = keys }
    local panel = CreateFrame("Frame")
    panel:Hide() -- nace oculto: si no, el Show() al abrir la categoria no dispara OnShow
    page.panel = panel

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

    local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", X, -56)
    fs:SetText(HEADER .. header .. "|r")

    function page:Refresh()
        for _, widget in ipairs(self.widgets) do widget:Refresh() end
    end
    panel:SetScript("OnShow", function() page:Refresh() end)

    function page:Checkbox(key, label, tooltip, y)
        local cb = CreateFrame("CheckButton", "DRTrackerForever_" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", X, y)
        _G[cb:GetName() .. "Text"]:SetText(label)
        cb:SetScript("OnClick", function(self)
            db[key] = self:GetChecked() and true or false
            ns.ApplyDisplay()
        end)
        AddTooltip(cb, tooltip)
        cb.Refresh = function(self) self:SetChecked(db[key]) end
        self.widgets[#self.widgets + 1] = cb
    end

    -- key: un ajuste de db, o { name, get, set } para lo que no se guarda tal cual
    function page:Slider(key, label, tooltip, y, min, max, step, format)
        local get = type(key) == "table" and key.get or function() return db[key] end
        local set = type(key) == "table" and key.set or function(value) db[key] = value end
        local name = "DRTrackerForever_" .. (type(key) == "table" and key.name or key)
        local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", X + 10, y)
        slider:SetWidth(400)
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        _G[name .. "Low"]:SetText(format(min))
        _G[name .. "High"]:SetText(format(max))
        local function Label() _G[name .. "Text"]:SetText(label .. ": " .. format(get())) end
        slider:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value / step + 0.5) * step
            if value == get() then return end
            set(value)
            Label()
            ns.ApplyDisplay()
        end)
        AddTooltip(slider, tooltip)
        slider.Refresh = function(self)
            self:SetValue(get())
            Label()
        end
        self.widgets[#self.widgets + 1] = slider
    end

    -- Etiqueta + desplegable; items = { { valor, texto } }, get/set del valor
    function page:Dropdown(name, label, tooltip, y, items, get, set)
        local text = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("TOPLEFT", X, y)
        text:SetText(label)
        local dropdown = CreateFrame("Frame", "DRTrackerForever_" .. name, panel, "UIDropDownMenuTemplate")
        dropdown:SetPoint("LEFT", text, "RIGHT", 0, -2)
        UIDropDownMenu_SetWidth(dropdown, 140)
        AddTooltip(dropdown, tooltip)
        local function TextOf(value)
            for _, item in ipairs(items) do
                if item[1] == value then return item[2] end
            end
        end
        UIDropDownMenu_Initialize(dropdown, function()
            for _, item in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = item[2]
                info.checked = get() == item[1]
                info.func = function()
                    set(item[1])
                    ns.ApplyDisplay()
                    page:Refresh()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        dropdown.Refresh = function(self) UIDropDownMenu_SetText(self, TextOf(get())) end
        self.widgets[#self.widgets + 1] = dropdown
    end

    function page:Finish(y)
        Separator(panel, y)
        local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        reset:SetSize(180, 26)
        reset:SetPoint("TOPLEFT", X, y - 20)
        reset:SetText(L.DEFAULTS)
        reset:SetScript("OnClick", function()
            for _, key in ipairs(self.keys) do db[key] = ns.DEFAULTS[key] end
            if self.resetPositions then ns.ResetPositions() else ns.ApplyDisplay() end
            self:Refresh()
        end)

        local preview = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        preview:SetSize(180, 26)
        preview:SetPoint("LEFT", reset, "RIGHT", 12, 0)
        preview:SetText(L.PREVIEW)
        preview:SetScript("OnClick", function() ns.Preview(20) end)
        AddTooltip(preview, L.PREVIEW_TOOLTIP)
    end

    pages[#pages + 1] = page
    return page
end

-- Al arrastrar una fila con las opciones abiertas, los deslizadores la siguen
function ns.RefreshOptions()
    for _, page in ipairs(pages) do
        if page.panel:IsVisible() then page:Refresh() end
    end
end

-- Devuelve la subcategoria General (destino de /drf)
function ns.CreateOptions()
    local db = ns.db

    local general = NewPage(L.SHOW_HEADER, { "showTarget", "showFocus", "showPlayer" })
    general:Checkbox("showTarget", L.SHOW_TARGET, L.SHOW_TARGET_TOOLTIP, -81)
    general:Checkbox("showFocus", L.SHOW_FOCUS, L.SHOW_FOCUS_TOOLTIP, -111)
    general:Checkbox("showPlayer", L.SHOW_PLAYER, L.SHOW_PLAYER_TOOLTIP, -141)
    general:Finish(-176)

    local track = NewPage(L.TRACK_HEADER, { "npcs", "group", "resetTime" })
    track:Checkbox("npcs", L.NPCS, L.NPCS_TOOLTIP, -81)
    track:Checkbox("group", L.GROUP, L.GROUP_TOOLTIP, -111)
    track:Slider("resetTime", L.RESET_TIME, L.RESET_TIME_TOOLTIP, -165, 15, 20, 1, Seconds)
    track:Finish(-205)

    local look = NewPage(L.LOOK_HEADER, { "locked", "showText", "size", "grow" })
    look:Checkbox("locked", L.LOCK, L.LOCK_TOOLTIP, -81)
    look:Checkbox("showText", L.SHOW_TEXT, L.SHOW_TEXT_TOOLTIP, -111)
    look:Slider("size", L.SIZE, L.SIZE_TOOLTIP, -165, 20, 48, 1, Pixels)
    local directions = {}
    for _, key in ipairs(ns.GROW_ORDER) do directions[#directions + 1] = { key, L["GROW_" .. key] } end
    look:Dropdown("grow", L.GROW, L.GROW_TOOLTIP, -213, directions,
        function() return db.grow end, function(value) db.grow = value end)
    look:Finish(-245)

    -- Posicion al pixel de una fila (ademas de arrastrarla desbloqueada)
    local position = NewPage(L.POSITION_HEADER, {})
    position.resetPositions = true
    local editUnit = "target"
    local rows = {}
    for _, info in ipairs(ns.BARS) do rows[#rows + 1] = { info.unit, L[info.label] } end
    position:Dropdown("row", L.POS_ROW, L.POS_ROW_TOOLTIP, -86, rows,
        function() return editUnit end, function(value) editUnit = value end)
    local halfW = math.floor(UIParent:GetWidth() / 2)
    local halfH = math.floor(UIParent:GetHeight() / 2)
    position:Slider({
        name = "posX",
        get = function() return (ns.GetBarOffset(editUnit)) end,
        set = function(value) ns.SetBarOffset(editUnit, value, nil) end,
    }, L.POS_X, L.POS_TOOLTIP, -137, -halfW, halfW, 1, Pixels)
    position:Slider({
        name = "posY",
        get = function() return select(2, ns.GetBarOffset(editUnit)) end,
        set = function(value) ns.SetBarOffset(editUnit, nil, value) end,
    }, L.POS_Y, L.POS_TOOLTIP, -187, -halfH, halfH, 1, Pixels)
    position:Finish(-227)

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
    local category = Settings.RegisterCanvasLayoutSubcategory(root, general.panel, L.GENERAL_HEADER)
    Settings.RegisterCanvasLayoutSubcategory(root, track.panel, L.TRACK_HEADER)
    Settings.RegisterCanvasLayoutSubcategory(root, look.panel, L.LOOK_HEADER)
    Settings.RegisterCanvasLayoutSubcategory(root, position.panel, L.POSITION_HEADER)
    return category
end
