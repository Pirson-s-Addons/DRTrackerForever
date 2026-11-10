local _, ns = ...
local L = ns.L

-- ==========================================
-- ICONOS DE DR
-- ==========================================
-- Tres filas de iconos: encima del marco del objetivo, del foco y del tuyo.
-- Cada icono es una categoria con DR activo: el ultimo hechizo de esa
-- categoria, el borde y el texto de debajo dicen cuanto dura el SIGUIENTE
-- (50 %, 25 % o 0 % = inmune) y la espiral, cuanto falta para el reinicio.

local MAX_ICONS = #ns.CATEGORIES
local GAP = 4
local TEXT_GAP = 14 -- en vertical, sitio para el texto de debajo del icono
-- Direccion de crecimiento: punto del primer icono y sentido de los siguientes
local GROW = {
    RIGHT = { "LEFT", 1, 0 },
    LEFT = { "RIGHT", -1, 0 },
    DOWN = { "TOP", 0, -1 },
    UP = { "BOTTOM", 0, 1 },
}
ns.GROW_ORDER = { "RIGHT", "LEFT", "UP", "DOWN" }
local BARS = {
    { unit = "target", option = "showTarget", frame = "TargetFrame", label = "SHOW_TARGET" },
    { unit = "focus", option = "showFocus", frame = "FocusFrame", label = "SHOW_FOCUS" },
    { unit = "player", option = "showPlayer", frame = "PlayerFrame", label = "SHOW_PLAYER" },
}
ns.BARS = BARS
-- Por controles que lleva: texto y color del borde
local STAGES = {
    { "50%", 0.25, 1, 0.25 },
    { "25%", 1, 0.6, 0 },
    { "0%", 1, 0.15, 0.15 },
}
local bars, barsByUnit = {}, {}

local function CreateIcon(bar)
    local icon = CreateFrame("Frame", nil, bar)
    icon.border = icon:CreateTexture(nil, "BACKGROUND")
    icon.border:SetPoint("TOPLEFT", -2, 2)
    icon.border:SetPoint("BOTTOMRIGHT", 2, -2)
    icon.border:SetColorTexture(1, 1, 1)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints()
    icon.cooldown:SetDrawEdge(false)
    icon.text = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    icon.text:SetPoint("TOP", icon, "BOTTOM", 0, -3)
    return icon
end

local function SavePosition(bar)
    local point, _, relative, x, y = bar:GetPoint()
    ns.db.pos[bar.unit] = { point, relative, x, y }
end

-- Puntos del marco a los que se puede pegar la fila (los puntos de Posicion)
-- y el punto de la fila que va pegado a cada uno, para que quede por fuera
ns.ANCHOR_POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local OUTSIDE = {
    TOPLEFT = { "BOTTOMLEFT", 0, 4 }, TOP = { "BOTTOM", 0, 4 }, TOPRIGHT = { "BOTTOMRIGHT", 0, 4 },
    LEFT = { "RIGHT", -4, 0 }, RIGHT = { "LEFT", 4, 0 },
    BOTTOMLEFT = { "TOPLEFT", 0, -4 }, BOTTOM = { "TOP", 0, -4 }, BOTTOMRIGHT = { "TOPRIGHT", 0, -4 },
}
ns.OUTSIDE = OUTSIDE

-- Los 8 puntos sobre un marco (la muestra de Posicion y el marco de verdad);
-- devuelve la funcion que marca el punto actual de la fila
function ns.CreateAnchorDots(parent, getUnit)
    local dots = {}
    for _, at in ipairs(ns.ANCHOR_POINTS) do
        local dot = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
        dot:SetPoint("CENTER", parent, at)
        dot:SetScript("OnClick", function()
            ns.SetBarAnchor(getUnit(), at)
            if ns.RefreshOptions then ns.RefreshOptions() end
        end)
        dot:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L.POS_ANCHOR_TOOLTIP, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        dot:SetScript("OnLeave", function() GameTooltip:Hide() end)
        dots[at] = dot
    end
    return function()
        local current = ns.GetBarAnchor(getUnit())
        for at, dot in pairs(dots) do dot:SetChecked(at == current) end
    end
end

-- Con Posicion abierta: puntos encima del marco de verdad de la fila elegida
local overlay, refreshOverlay
local function UpdateOverlay()
    if not overlay then return end
    local anchor = ns.editing and _G[barsByUnit[ns.editing].anchorName]
    overlay:SetShown(anchor ~= nil)
    if not anchor then return end
    overlay:ClearAllPoints()
    overlay:SetAllPoints(anchor)
    refreshOverlay()
end

-- Largo de la fila para n iconos
local function Fit(bar, n)
    local length = n * bar.step - (bar.step - bar.size)
    if bar.vertical then bar:SetSize(bar.size, length) else bar:SetSize(length, bar.size) end
end

local function Place(bar)
    bar:ClearAllPoints()
    local pos = ns.db.pos[bar.unit]
    local anchor = _G[bar.anchorName]
    -- Pegada a su marco, la fila mide lo que sus iconos: asi el grupo queda
    -- alineado con el punto (centrado, a la derecha...). Suelta, mide siempre igual
    bar.fit = anchor and (not pos or pos.at) and true or false
    if not bar.fit then Fit(bar, MAX_ICONS) end
    -- Encima del marco, sitio para el texto de debajo de los iconos
    local textRoom = ns.db.showText and TEXT_GAP or 0
    if pos and pos.at and anchor then
        local o = OUTSIDE[pos.at]
        bar:SetPoint(o[1], anchor, pos.at, o[2], o[3] + (o[3] > 0 and textRoom or 0))
    elseif pos and not pos.at then
        bar:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    elseif anchor then
        bar:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 20, 4 + textRoom)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    end
    UpdateOverlay()
end

local function CreateBar(info)
    local bar = CreateFrame("Frame", "DRTrackerForever_" .. info.unit, UIParent)
    bar.unit, bar.option, bar.anchorName = info.unit, info.option, info.frame
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
        if ns.RefreshOptions then ns.RefreshOptions() end
    end)
    bar.background = bar:CreateTexture(nil, "BACKGROUND")
    bar.background:SetAllPoints()
    bar.background:SetColorTexture(0.77, 0.5, 0.95, 0.35)
    bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.label:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 2)
    bar.label:SetText(L[info.label] .. " - " .. L.DRAG_HINT)
    bar.icons = {}
    for i = 1, MAX_ICONS do bar.icons[i] = CreateIcon(bar) end
    return bar
end

-- Muestra de la vista previa: una categoria en cada estado
function ns.PreviewStates(now)
    return {
        { category = "stun", count = 1, at = now - 2, resetAt = now + 18, spellID = 408 },
        { category = "incapacitate", count = 2, at = now - 5, resetAt = now + 15, spellID = 118 },
        { category = "disorient", count = 3, at = now - 8, resetAt = now + 12, spellID = 5782 },
    }
end

local function UpdateBar(bar, now)
    local list
    if ns.previewUntil and now < ns.previewUntil then
        list = ns.PreviewStates(ns.previewStart)
    elseif not ns.db.locked or ns.editing == bar.unit then
        -- Desbloqueado: la muestra, para ver donde queda y hacia donde crece
        list = ns.PreviewStates(ns.editStart)
    elseif ns.db[bar.option] then
        local key = ns.UnitKey(bar.unit)
        list = key and ns.tracker:States(key, now)
    end
    list = list or {}
    if bar.fit then Fit(bar, math.max(#list, 1)) end
    for i, icon in ipairs(bar.icons) do
        local s = list[i]
        if s then
            local stage = STAGES[math.min(s.count, 3)]
            icon.texture:SetTexture((s.spellID and C_Spell.GetSpellTexture(s.spellID)) or ns.CATEGORY_ICON[s.category])
            icon.border:SetColorTexture(stage[2], stage[3], stage[4])
            icon.text:SetText(ns.db.showText and stage[1] or "")
            icon.text:SetTextColor(stage[2], stage[3], stage[4])
            -- Solo si cambia: volver a ponerla reinicia la animacion
            if icon.at ~= s.at or icon.resetAt ~= s.resetAt then
                icon.at, icon.resetAt = s.at, s.resetAt
                icon.cooldown:SetCooldown(s.at, s.resetAt - s.at)
            end
            icon:Show()
        else
            icon.at, icon.resetAt = nil, nil
            icon:Hide()
        end
    end
end

function ns.Refresh()
    if not ns.tracker then return end
    local now = GetTime()
    -- La muestra de edicion vuelve a empezar cuando acaban sus espirales
    if not ns.editStart or now - ns.editStart >= 18 then ns.editStart = now end
    for _, bar in ipairs(bars) do UpdateBar(bar, now) end
end

-- Tamano, posicion y si se ve cada fila (al cambiar una opcion)
function ns.ApplyDisplay()
    local size = ns.db.size
    local grow = GROW[ns.db.grow] or GROW.RIGHT
    local point, dx, dy = grow[1], grow[2], grow[3]
    local step = size + (dy == 0 and GAP or GAP + TEXT_GAP)
    for _, bar in ipairs(bars) do
        bar.size, bar.step, bar.vertical = size, step, dy ~= 0
        for i, icon in ipairs(bar.icons) do
            icon:SetSize(size, size)
            icon:ClearAllPoints()
            icon:SetPoint(point, bar, point, (i - 1) * step * dx, (i - 1) * step * dy)
        end
        local unlocked = not ns.db.locked
        bar:EnableMouse(unlocked)
        bar.background:SetShown(unlocked)
        bar.label:SetShown(unlocked)
        local editing = ns.editing == bar.unit
        bar:SetShown(ns.db[bar.option] or unlocked or editing)
        -- Editandola, por encima de la ventana de Opciones
        bar:SetFrameStrata(editing and "FULLSCREEN_DIALOG" or "MEDIUM")
        Place(bar)
    end
    ns.Refresh()
end

function ns.Preview(seconds)
    ns.previewStart = GetTime()
    ns.previewUntil = ns.previewStart + seconds
    ns.Refresh()
    C_Timer.After(seconds + 0.1, ns.Refresh)
end

-- Centro de la fila respecto al centro de la pantalla (deslizadores X/Y)
function ns.GetBarOffset(unit)
    local x, y = barsByUnit[unit]:GetCenter()
    if not x then return 0, 0 end -- ponytail: fila sin colocar aun, sale en 0
    local cx, cy = UIParent:GetCenter()
    return math.floor(x - cx + 0.5), math.floor(y - cy + 0.5)
end

function ns.SetBarOffset(unit, x, y)
    local ox, oy = ns.GetBarOffset(unit)
    ns.db.pos[unit] = { "CENTER", "CENTER", x or ox, y or oy }
    Place(barsByUnit[unit])
end

-- Pegar la fila a un punto de su marco; nil = sin pegar (arrastrada o al pixel)
function ns.SetBarAnchor(unit, at)
    ns.db.pos[unit] = { at = at }
    Place(barsByUnit[unit])
end

function ns.GetBarAnchor(unit)
    local pos = ns.db.pos[unit]
    if not pos then return "TOPLEFT" end -- la de por defecto: encima, a la izquierda
    return pos.at
end

function ns.ResetPositions()
    ns.db.pos = {}
    ns.ApplyDisplay()
end

-- Fila que se esta colocando en Posicion (nil al cerrarla)
function ns.SetEditing(unit)
    ns.editing = unit
    ns.ApplyDisplay()
end

function ns.CreateDisplay()
    for _, info in ipairs(BARS) do
        bars[#bars + 1] = CreateBar(info)
        barsByUnit[info.unit] = bars[#bars]
    end
    overlay = CreateFrame("Frame", nil, UIParent)
    overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    overlay:Hide()
    local tint = overlay:CreateTexture(nil, "BACKGROUND")
    tint:SetAllPoints()
    tint:SetColorTexture(0.77, 0.5, 0.95, 0.15)
    refreshOverlay = ns.CreateAnchorDots(overlay, function() return ns.editing end)
    ns.ApplyDisplay()
    -- Quita los iconos al reiniciarse el DR (y ve cambios de objetivo del grupo)
    C_Timer.NewTicker(0.25, ns.Refresh)
end
