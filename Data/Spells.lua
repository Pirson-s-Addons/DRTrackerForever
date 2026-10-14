local _, ns = ...

-- ==========================================
-- CONTROL DE MASAS Y SU CATEGORIA DE DR
-- ==========================================
-- [spellID] = { categoria, segundos a duracion completa }.
-- Categorias: las de Blizzard en Forever (Enum.SpellDiminishCategory). Que
-- hechizo va en cual no lo publica nadie para Forever: se sigue la asignacion
-- moderna de cada efecto de Classic. Los segundos son los de Classic sin
-- talentos; el addon aprende la duracion real en cuanto ve el aura (db.learned).
-- aura = true: no es un lanzamiento sobre el objetivo (trampa, efecto de la
--   mascota, silencio de un talento); solo cuenta cuando se ve su aura.
-- aoe = true: sin objetivo propio; el lanzamiento cuenta sobre tu objetivo.
-- ponytail: IDs de Classic sin verificar en Forever; los nuevos de Forever
-- (otro ID) no se ven hasta anadirlos aqui.

ns.CATEGORIES = { "stun", "incapacitate", "disorient", "silence", "root", "disarm" }

ns.CATEGORY_ICON = {
    stun = "Interface\\Icons\\Ability_Rogue_KidneyShot",
    incapacitate = "Interface\\Icons\\Spell_Nature_Polymorph",
    disorient = "Interface\\Icons\\Spell_Shadow_Possession",
    silence = "Interface\\Icons\\Spell_Shadow_ImpPhaseShift",
    root = "Interface\\Icons\\Spell_Nature_StrangleVines",
    disarm = "Interface\\Icons\\Ability_Warrior_Disarm",
}

local S = {}
ns.SPELLS = S

local function Add(category, seconds, ids, flags)
    for _, id in ipairs(ids) do
        S[id] = { category, seconds, aura = flags == "aura", aoe = flags == "aoe" }
    end
end

-- Aturdimientos
Add("stun", 4, { 1833 })                      -- Golpe bajo
Add("stun", 5, { 408 })                       -- Golpe en los rinones (rango 1)
Add("stun", 6, { 8643 })                      -- Golpe en los rinones (rango 2)
Add("stun", 3, { 853 })                       -- Martillo de justicia
Add("stun", 4, { 5588 })
Add("stun", 5, { 5589 })
Add("stun", 6, { 10308 })
Add("stun", 2, { 5211 })                      -- Azote
Add("stun", 3, { 6798 })
Add("stun", 4, { 8983 })
Add("stun", 2, { 9005, 9823, 9827 })          -- Abalanzarse
Add("stun", 3, { 20252, 20616, 20617 })       -- Interceptar
Add("stun", 3, { 20253, 20614, 20615 }, "aura") -- Interceptar (el aturdimiento)
Add("stun", 5, { 12809 })                     -- Conmocion
Add("stun", 3, { 19577 })                     -- Intimidacion
Add("stun", 3, { 24394 }, "aura")             -- Intimidacion (la mascota)
Add("stun", 2, { 20549 }, "aoe")              -- Pisoteo de guerra

-- Incapacitaciones
Add("incapacitate", 20, { 118 })              -- Polimorfia
Add("incapacitate", 30, { 12824 })
Add("incapacitate", 40, { 12825 })
Add("incapacitate", 50, { 12826, 28270, 28271, 28272 })
Add("incapacitate", 25, { 6770 })             -- Porrazo
Add("incapacitate", 35, { 2070 })
Add("incapacitate", 45, { 11297 })
Add("incapacitate", 4, { 1776, 1777, 8629, 11285, 11286 }) -- Gubia
Add("incapacitate", 6, { 20066 })             -- Arrepentimiento
Add("incapacitate", 12, { 19386, 24132, 24133 }) -- Picadura de dracoleon
Add("incapacitate", 20, { 2637 })             -- Hibernar
Add("incapacitate", 30, { 18657 })
Add("incapacitate", 40, { 18658 })
Add("incapacitate", 30, { 9484 })             -- Encadenar no-muerto
Add("incapacitate", 40, { 9485 })
Add("incapacitate", 50, { 10955 })
Add("incapacitate", 10, { 3355 }, "aura")     -- Trampa congelante
Add("incapacitate", 15, { 14308 }, "aura")
Add("incapacitate", 20, { 14309 }, "aura")

-- Desorientaciones (miedos y parecidos)
Add("disorient", 10, { 5782 })                -- Miedo
Add("disorient", 15, { 6213 })
Add("disorient", 20, { 6215 })
Add("disorient", 10, { 5484 }, "aoe")         -- Aullido de terror
Add("disorient", 15, { 17928 }, "aoe")
Add("disorient", 8, { 8122, 8124, 10888, 10890 }, "aoe") -- Alarido psiquico
Add("disorient", 8, { 5246 }, "aoe")          -- Grito intimidatorio
Add("disorient", 10, { 2094 })                -- Ceguera
Add("disorient", 10, { 1513 })                -- Asustar bestia
Add("disorient", 15, { 14326 })
Add("disorient", 20, { 14327 })
Add("disorient", 10, { 2878 })                -- Expulsar no-muertos
Add("disorient", 15, { 5627 })
Add("disorient", 20, { 10326 })
Add("disorient", 15, { 6358 })                -- Seduccion (sucubo)
Add("disorient", 4, { 19503 })                -- Disparo de dispersion

-- Silencios
Add("silence", 5, { 15487 })                  -- Silencio
Add("silence", 3, { 19244 })                  -- Bloqueo de hechizo (manafago)
Add("silence", 4, { 19647 })
Add("silence", 4, { 18469 }, "aura")          -- Contrahechizo mejorado

-- Raices
Add("root", 8, { 122, 865, 6131, 10230 }, "aoe") -- Nova de Escarcha
Add("root", 12, { 339 })                      -- Raices enredadoras
Add("root", 15, { 1062 })
Add("root", 18, { 5195 })
Add("root", 21, { 5196 })
Add("root", 24, { 9852 })
Add("root", 27, { 9853 })
Add("root", 4, { 19675 }, "aura")             -- Cargar salvaje (la inmovilizacion)

-- Desarmes
Add("disarm", 10, { 676 })                    -- Desarmar
