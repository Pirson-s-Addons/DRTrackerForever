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
local BARS = {
    { unit = "target", option = "showTarget", frame = "TargetFrame", label = "SHOW_TARGET" },
    { unit = "focus", option = "showFocus", frame = "FocusFrame", label = "SHOW_FOCUS" },
    { unit = "player", option = "showPlayer", frame = "PlayerFrame", label = "SHOW_PLAYER" },
}
-- Por controles que lleva: texto y color del borde
local STAGES = {
    { "50%", 0.25, 1, 0.25 },
    { "25%", 1, 0.6, 0 },
    { "0%", 1, 0.15, 0.15 },
}
local bars = {}

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

local function Place(bar)
    bar:ClearAllPoints()
    local pos = ns.db.pos[bar.unit]
    local anchor = _G[bar.anchorName]
    if pos then
        bar:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    elseif anchor then
        bar:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 20, 4)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    end
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
    elseif ns.db[bar.option] then
        local key = ns.UnitKey(bar.unit)
        list = key and ns.tracker:States(key, now)
    end
    list = list or {}
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
    for _, bar in ipairs(bars) do UpdateBar(bar, now) end
end

-- Tamano, posicion y si se ve cada fila (al cambiar una opcion)
function ns.ApplyDisplay()
    local size = ns.db.size
    for _, bar in ipairs(bars) do
        bar:SetSize(MAX_ICONS * (size + GAP) - GAP, size)
        for i, icon in ipairs(bar.icons) do
            icon:SetSize(size, size)
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", bar, "LEFT", (i - 1) * (size + GAP), 0)
        end
        local unlocked = not ns.db.locked
        bar:EnableMouse(unlocked)
        bar.background:SetShown(unlocked)
        bar.label:SetShown(unlocked)
        bar:SetShown(ns.db[bar.option] or unlocked)
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

function ns.ResetPositions()
    ns.db.pos = {}
    ns.ApplyDisplay()
end

function ns.CreateDisplay()
    for _, info in ipairs(BARS) do bars[#bars + 1] = CreateBar(info) end
    ns.ApplyDisplay()
    -- Quita los iconos al reiniciarse el DR (y ve cambios de objetivo del grupo)
    C_Timer.NewTicker(0.25, ns.Refresh)
end
