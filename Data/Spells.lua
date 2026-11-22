local _, ns = ...

-- ==========================================
-- CONTROL DE MASAS Y SU CATEGORIA DE DR
-- ==========================================
-- [spellID] = { categoria, segundos a duracion completa }.
-- Categorias: las de WoW Classic Era (Forever es vanilla), segun DRList-1.0
-- (wardz), la lista que usan Gladius y Diminish: Golpe en los rinones, Choque
-- de Escarcha y Control mental solo comparten DR consigo mismos; los
-- aturdimientos y raices por probabilidad (talentos, armas) van aparte; los
-- silencios, desarmes, Ceguera, Expulsar y Encadenar no tienen DR en Classic.
-- Los segundos son los de Classic sin talentos; el addon aprende la duracion
-- real en cuanto ve el aura (db.learned).
-- aura = true: no es un lanzamiento sobre el objetivo (trampa, efecto de la
--   mascota, talento o arma); solo cuenta cuando se ve su aura.
-- aoe = true: sin objetivo propio; el lanzamiento cuenta sobre tu objetivo.
-- ponytail: IDs de Classic sin verificar en Forever; los nuevos de Forever
-- (otro ID) no se ven hasta anadirlos aqui.

ns.CATEGORIES = { "stun", "kidney_shot", "random_stun", "incapacitate", "fear", "root", "random_root",
    "frost_shock", "mind_control" }

ns.CATEGORY_ICON = {
    stun = "Interface\\Icons\\Ability_CheapShot",
    kidney_shot = "Interface\\Icons\\Ability_Rogue_KidneyShot",
    random_stun = "Interface\\Icons\\INV_Mace_01",
    incapacitate = "Interface\\Icons\\Spell_Nature_Polymorph",
    fear = "Interface\\Icons\\Spell_Shadow_Possession",
    root = "Interface\\Icons\\Spell_Nature_StrangleVines",
    random_root = "Interface\\Icons\\Ability_ShockWave",
    frost_shock = "Interface\\Icons\\Spell_Frost_FrostShock",
    mind_control = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate",
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
Add("stun", 3, { 853 })                       -- Martillo de justicia
Add("stun", 4, { 5588 })
Add("stun", 5, { 5589 })
Add("stun", 6, { 10308 })
Add("stun", 2, { 5211 })                      -- Azote
Add("stun", 3, { 6798 })
Add("stun", 4, { 8983 })
Add("stun", 2, { 9005, 9823, 9827 })          -- Abalanzarse
Add("stun", 1, { 7922 }, "aura")              -- Cargar (el aturdimiento)
Add("stun", 3, { 20252, 20616, 20617 })       -- Interceptar
Add("stun", 3, { 20253, 20614, 20615 }, "aura") -- Interceptar (el aturdimiento)
Add("stun", 5, { 12809 })                     -- Conmocion
Add("stun", 3, { 19577 })                     -- Intimidacion
Add("stun", 3, { 24394 }, "aura")             -- Intimidacion (la mascota)
Add("stun", 2, { 20549 }, "aoe")              -- Pisoteo de guerra

-- Golpe en los rinones: DR propio en Classic, no comparte con Golpe bajo
Add("kidney_shot", 5, { 408 })                -- rango 1
Add("kidney_shot", 6, { 8643 })               -- rango 2

-- Aturdimientos por probabilidad (talentos y armas)
Add("random_stun", 3, { 16922 }, "aura")      -- Foco celestial (Fuego estelar mejorado)
Add("random_stun", 3, { 19410 }, "aura")      -- Disparo conmocionador mejorado
Add("random_stun", 2, { 12355 }, "aura")      -- Impacto
Add("random_stun", 2, { 20170 }, "aura")      -- Sello de justicia
Add("random_stun", 3, { 15269 }, "aura")      -- Apagon
Add("random_stun", 3, { 18093 }, "aura")      -- Piroclasmo
Add("random_stun", 3, { 12798 }, "aura")      -- Revancha mejorada
Add("random_stun", 3, { 5530 }, "aura")       -- Especializacion en mazas
Add("random_stun", 2, { 56, 15283, 21152 }, "aura") -- Armas

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
Add("incapacitate", 4, { 19503 })             -- Disparo de dispersion
Add("incapacitate", 10, { 3355 }, "aura")     -- Trampa congelante
Add("incapacitate", 15, { 14308 }, "aura")
Add("incapacitate", 20, { 14309 }, "aura")

-- Miedos
Add("fear", 10, { 5782 })                     -- Miedo
Add("fear", 15, { 6213 })
Add("fear", 20, { 6215 })
Add("fear", 10, { 5484 }, "aoe")              -- Aullido de terror
Add("fear", 15, { 17928 }, "aoe")
Add("fear", 8, { 8122, 8124, 10888, 10890 }, "aoe") -- Alarido psiquico
Add("fear", 8, { 5246 }, "aoe")               -- Grito intimidatorio
Add("fear", 10, { 1513 })                     -- Asustar bestia
Add("fear", 15, { 14326 })
Add("fear", 20, { 14327 })
Add("fear", 15, { 6358 })                     -- Seduccion (sucubo)

-- Raices
Add("root", 8, { 122, 865, 6131, 10230 }, "aoe") -- Nova de Escarcha
Add("root", 12, { 339 })                      -- Raices enredadoras
Add("root", 15, { 1062 })
Add("root", 18, { 5195 })
Add("root", 21, { 5196 })
Add("root", 24, { 9852 })
Add("root", 27, { 9853 })
Add("root", 12, { 19975, 19974, 19973, 19972, 19971, 19970 }, "aura") -- Garras de la naturaleza
Add("root", 5, { 19306, 20909, 20910 })       -- Contraataque

-- Raices por probabilidad (talentos)
Add("random_root", 5, { 19229 }, "aura")      -- Cortar alas mejorado
Add("random_root", 5, { 23694 }, "aura")      -- Seccionar mejorado

-- Solo comparten DR consigo mismos
Add("frost_shock", 8, { 8056, 8058, 10472, 10473 }) -- Choque de Escarcha
Add("mind_control", 60, { 605, 10911, 10912 }) -- Control mental
