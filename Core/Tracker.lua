local _, ns = ...

-- ==========================================
-- CONTADOR DE DR (sin API del juego)
-- ==========================================
-- Por enemigo (clave: GUID o nombre) y categoria: cuantos control de masas
-- seguidos lleva y cuando se reinicia. El 1.o dura entero, el 2.o la mitad, el
-- 3.o un cuarto y a partir del 4.o es inmune. Se reinicia resetTime() segundos
-- despues de que acabe el ultimo. Un control lanzado sobre un inmune no hace
-- nada y no alarga el reinicio.
-- count = controles que ya lleva: 1 -> el siguiente dura la mitad, 2 -> un
-- cuarto, 3 -> inmune.

local MERGE = 1 -- s: el lanzamiento y el aura del mismo control son una sola vez

function ns.NewTracker(resetTime)
    local units = {}
    local tracker = {}

    local function Get(key, category, now)
        local u = units[key]
        local s = u and u[category]
        if s and now >= s.resetAt then
            u[category] = nil
            s = nil
        end
        return s
    end

    -- at: cuando empezo el control. duration: lo que dura entero (exact = false)
    -- o lo que dura de verdad, ya reducido (exact = true, del aura).
    -- stage: controles anteriores que deduce quien llama (por la duracion del
    -- aura); corrige el contador si se perdio alguno.
    -- Devuelve el estado y si se junto con el anterior.
    function tracker:Apply(key, category, at, duration, spellID, exact, stage)
        local s = Get(key, category, at)
        if s and math.abs(at - s.at) <= MERGE then
            if exact then
                s.ccEnd = at + duration
                s.resetAt = s.ccEnd + resetTime()
            end
            return s, true
        end
        if s and s.count >= 3 and not exact then return s, false end
        local prev = s and { count = s.count, at = s.at, ccEnd = s.ccEnd, resetAt = s.resetAt, spellID = s.spellID }
        s = s or { count = 0 }
        if stage then s.count = stage end
        if not exact then duration = duration * 0.5 ^ s.count end
        s.count = math.min(s.count + 1, 3)
        s.at, s.spellID, s.prev = at, spellID, prev
        s.ccEnd = at + duration
        s.resetAt = s.ccEnd + resetTime()
        units[key] = units[key] or {}
        units[key][category] = s
        return s, false
    end

    -- El control acabo antes de tiempo (aura quitada): el reinicio cuenta desde ya
    function tracker:End(key, category, now)
        local s = Get(key, category, now)
        if s and now < s.ccEnd then
            s.ccEnd = now
            s.resetAt = now + resetTime()
        end
    end

    -- El control que se aplico en "at" fallo (esquivado, resistido): se deshace
    function tracker:Undo(key, category, at)
        local s = units[key] and units[key][category]
        if not s or s.at ~= at then return end
        if s.prev then
            for field, value in pairs(s.prev) do s[field] = value end
            s.prev = nil
        else
            units[key][category] = nil
        end
    end

    -- El juego dijo "Inmune": ya llevaba tres. Si no lo sabiamos, el reinicio es
    -- una estimacion desde ahora.
    function tracker:Immune(key, category, now)
        local s = Get(key, category, now)
        if not s then
            units[key] = units[key] or {}
            s = { at = now, ccEnd = now, resetAt = now + resetTime() }
            units[key][category] = s
        end
        s.count, s.prev = 3, nil
    end

    -- Las categorias activas de un enemigo, en el orden de ns.CATEGORIES
    function tracker:States(key, now)
        local list = {}
        if not units[key] then return list end
        for _, category in ipairs(ns.CATEGORIES) do
            local s = Get(key, category, now)
            if s then
                list[#list + 1] = { category = category, count = s.count, at = s.at,
                    ccEnd = s.ccEnd, resetAt = s.resetAt, spellID = s.spellID }
            end
        end
        return list
    end

    function tracker:Clear() units = {} end

    return tracker
end
