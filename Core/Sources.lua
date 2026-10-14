local _, ns = ...

-- ==========================================
-- DE DONDE SALE CADA CONTROL DE MASAS
-- ==========================================
-- Forever (API de Retail 12) no deja a los addons ni el registro de combate
-- (ADDON_ACTION_FORBIDDEN) ni su propio sistema de DR (C_SpellDiminish:
-- IsSystemSupported() = false), y en combate las auras de los enemigos son
-- secretas. Medido en la beta (2026-10-14), lo que si llega:
--   - Lanzamientos: UNIT_SPELLCAST_SUCCEEDED del jugador (y del grupo) con su
--     spellID, y el GUID del objetivo, legibles en combate.
--   - Fallos: UNIT_COMBAT del objetivo ("MISS", "RESIST", "IMMUNE"...).
--   - Auras de los hechizos que Blizzard no marca como secretos
--     (C_Secrets.ShouldSpellAuraBeSecret) y todas fuera de combate: duracion
--     exacta y cuando se quitan.
--   - Perdida de control sobre ti (C_LossOfControl), si no es secreta.
-- Regla de todo el fichero: mirar Secret() ANTES de comparar o indexar nada.

local MISSES = { MISS = true, RESIST = true, DODGE = true, PARRY = true, EVADE = true,
    DEFLECT = true, REFLECT = true, IMMUNE = true }
local FEEDBACK_WINDOW = 0.5 -- s tras el lanzamiento en que un fallo es de ese control
local WATCHED = { "target", "focus", "player" }
-- Perdida de control sin hechizo en la lista: su tipo dice la categoria
local LOC_CATEGORY = { STUN = "stun", STUN_MECHANIC = "stun", FEAR = "disorient", FEAR_MECHANIC = "disorient",
    CONFUSE = "incapacitate", SILENCE = "silence", ROOT = "root", DISARM = "disarm" }

local function Secret(value) return issecretvalue ~= nil and issecretvalue(value) end
local function Readable(value) return value ~= nil and not Secret(value) end

local sent, pending, seen, dirty = {}, {}, {}, {}
local scanQueued = false

-- Clave de un enemigo: su GUID o, si es secreto (jugadores dentro de campos de
-- batalla), su nombre completo, que ahi es unico. Nada si no se puede atacar,
-- si es un PNJ (salvo la opcion) o si algo es secreto.
function ns.UnitKey(unit)
    if unit == "player" then return UnitGUID("player"), true end
    local exists = UnitExists(unit)
    if Secret(exists) or not exists then return end
    local hostile = UnitCanAttack("player", unit)
    if Secret(hostile) or not hostile then return end
    local isPlayer = UnitIsPlayer(unit)
    if Secret(isPlayer) or (not isPlayer and not ns.db.npcs) then return end
    local guid = UnitGUID(unit)
    if Readable(guid) then return guid, isPlayer end
    if not isPlayer then return end
    local name, realm = UnitName(unit)
    if not Readable(name) or Secret(realm) then return end
    if realm and realm ~= "" then name = name .. "-" .. realm end
    return "name:" .. name, true
end

local function Duration(id)
    return ns.db.learned[id] or ns.SPELLS[id][2]
end

local function DropPending(key, category)
    for i = #pending, 1, -1 do
        local p = pending[i]
        if p.key == key and p.category == category then table.remove(pending, i) end
    end
end

--------------------------------------------------
-- LANZAMIENTOS
--------------------------------------------------
-- El objetivo se apunta al enviar el hechizo: con tiempo de lanzamiento
-- (Polimorfia, Miedo) puedes cambiar de objetivo antes de que salga.
-- ponytail: un /cast [@focus] cuenta sobre el objetivo; leer el nombre de
-- UNIT_SPELLCAST_SENT si hace falta.
local function OnSent(unit, castGUID)
    if unit ~= "player" or not Readable(castGUID) then return end
    local now = GetTime()
    for guid, entry in pairs(sent) do
        if now - entry.at > 10 then sent[guid] = nil end
    end
    sent[castGUID] = { key = ns.UnitKey("target"), at = now }
end

local function OnSucceeded(unit, castGUID, id)
    if not Readable(unit) or not Readable(id) then return end
    local spell = ns.SPELLS[id]
    if not spell or spell.aura then return end
    local key
    if unit == "player" then
        local record = Readable(castGUID) and sent[castGUID]
        if record then sent[castGUID] = nil end
        key = record and record.key or ns.UnitKey("target")
    elseif unit == "pet" then
        key = ns.UnitKey("pettarget")
    elseif ns.db.group and unit:match("^party%d$") and not spell.aoe then
        key = ns.UnitKey(unit .. "target")
    end
    if not key then return end
    local now = GetTime()
    local s = ns.tracker:Apply(key, spell[1], now, Duration(id), id, false)
    -- ponytail: un golpe blanco esquivado en ese medio segundo tambien deshace
    -- el control; el aura (si se ve) lo confirma y lo salva.
    pending[#pending + 1] = { key = key, category = spell[1], at = s.at, time = now }
    ns.Refresh()
end

local function OnCombat(unit, action)
    if not Readable(action) or not MISSES[action] then return end
    local key = ns.UnitKey(unit)
    local now = GetTime()
    for i = #pending, 1, -1 do
        local p = pending[i]
        if now - p.time > FEEDBACK_WINDOW then
            table.remove(pending, i)
        elseif p.key == key then
            table.remove(pending, i)
            if action == "IMMUNE" then
                ns.tracker:Immune(p.key, p.category, now)
            else
                ns.tracker:Undo(p.key, p.category, p.at)
            end
            ns.Refresh()
        end
    end
end

--------------------------------------------------
-- AURAS LEGIBLES
--------------------------------------------------
-- En combate solo se miran los hechizos que Blizzard deja ver; fuera, todos.
-- La lista se rehace al entrar y salir de combate.
local readableIDs
local function ReadableIDs()
    if readableIDs then return readableIDs end
    readableIDs = {}
    local secrets = C_Secrets
    local inCombat = secrets and secrets.ShouldAurasBeSecret()
    for id in pairs(ns.SPELLS) do
        local hidden = inCombat and secrets.ShouldSpellAuraBeSecret(id)
        if not Secret(hidden) and not hidden then readableIDs[#readableIDs + 1] = id end
    end
    return readableIDs
end

-- Controles anteriores segun lo que dura el aura frente a la completa aprendida
local function StageFromDuration(id, duration)
    local full = ns.db.learned[id]
    if not full then return end
    local ratio = duration / full
    if ratio <= 0.35 then return 2 elseif ratio <= 0.62 then return 1 end
    return 0
end

local function ScanUnit(unit)
    local key, isPlayer = ns.UnitKey(unit)
    if not key then seen[unit] = nil; return end
    local state = seen[unit]
    local fresh = not state or state.key ~= key
    if fresh then
        state = { key = key, ids = {} }
        seen[unit] = state
    end
    local now = GetTime()
    for _, id in ipairs(ReadableIDs()) do
        local category = ns.SPELLS[id][1]
        local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, id)
        if ok and Readable(aura) then
            if not state.ids[id] then
                state.ids[id] = true
                local expires, total = aura.expirationTime, aura.duration
                local exact = Readable(expires) and Readable(total) and total > 0
                -- Con los tiempos del aura, un control ya contado se junta solo
                -- (empieza cuando empezo). Sin ellos, al cambiar de objetivo, un
                -- control que sigue activo no es uno nuevo.
                local known = false
                if fresh and not exact then
                    for _, s in ipairs(ns.tracker:States(key, now)) do
                        if s.category == category and now < s.ccEnd + 0.5 then known = true end
                    end
                end
                if not known then
                    local start, duration = now, Duration(id)
                    local stage
                    if exact then
                        start, duration = math.min(now, expires - total), total
                        if isPlayer then
                            stage = StageFromDuration(id, total)
                            if not ns.db.learned[id] or total > ns.db.learned[id] then ns.db.learned[id] = total end
                        end
                    end
                    ns.tracker:Apply(key, category, start, duration, id, exact, stage)
                    DropPending(key, category)
                    ns.Refresh()
                end
            end
        elseif ok and state.ids[id] then
            state.ids[id] = nil
            ns.tracker:End(key, category, now)
            ns.Refresh()
        end
    end
end

-- UNIT_AURA llega muchas veces seguidas: una lectura cada 0,1 s como mucho
local function RunScans()
    scanQueued = false
    for unit in pairs(dirty) do
        dirty[unit] = nil
        ScanUnit(unit)
    end
end
local function QueueScan(unit)
    dirty[unit] = true
    if not scanQueued then
        scanQueued = true
        C_Timer.After(0.1, RunScans)
    end
end

--------------------------------------------------
-- PERDIDA DE CONTROL SOBRE TI
--------------------------------------------------
local function OnLossOfControl()
    local loc = C_LossOfControl
    if not loc or not loc.GetActiveLossOfControlDataCount then return end
    local count = loc.GetActiveLossOfControlDataCount()
    if not Readable(count) then return end
    local key = UnitGUID("player")
    for i = 1, count do
        local data = loc.GetActiveLossOfControlData(i)
        if Readable(data) and Readable(data.spellID) and Readable(data.locType) then
            local spell = ns.SPELLS[data.spellID]
            local category = spell and spell[1] or LOC_CATEGORY[data.locType]
            local start, duration = data.startTime, data.duration
            if category and Readable(start) and Readable(duration) and duration > 0 then
                ns.tracker:Apply(key, category, start, duration, data.spellID, true)
                ns.Refresh()
            end
        end
    end
end

--------------------------------------------------
-- ARRANQUE
--------------------------------------------------
function ns.StartSources()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_SPELLCAST_SENT")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
    -- La unidad sale del registro, nunca de un argumento que pueda ser secreto
    for _, unit in ipairs(WATCHED) do
        local watcher = CreateFrame("Frame")
        watcher:RegisterUnitEvent("UNIT_AURA", unit)
        if unit ~= "player" then watcher:RegisterUnitEvent("UNIT_COMBAT", unit) end
        watcher:SetScript("OnEvent", function(_, event, _, action)
            if event == "UNIT_AURA" then QueueScan(unit) else OnCombat(unit, action) end
        end)
    end
    frame:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
        if event == "UNIT_SPELLCAST_SENT" then
            OnSent(a1, a3)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            OnSucceeded(a1, a2, a3)
        elseif event == "PLAYER_TARGET_CHANGED" then
            QueueScan("target")
            ns.Refresh()
        elseif event == "PLAYER_FOCUS_CHANGED" then
            QueueScan("focus")
            ns.Refresh()
        elseif event == "LOSS_OF_CONTROL_ADDED" then
            OnLossOfControl()
        else
            readableIDs = nil
            for _, unit in ipairs(WATCHED) do QueueScan(unit) end
        end
    end)
    for _, unit in ipairs(WATCHED) do QueueScan(unit) end
end
