local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- AJUSTES, COMANDO Y ARRANQUE
-- ==========================================

local DEFAULTS = {
    showTarget = true, showFocus = true, showPlayer = true,
    npcs = false, group = true, resetTime = 18,
    locked = true, size = 30, showText = true, grow = "RIGHT",
}
ns.DEFAULTS = DEFAULTS

local category -- subcategoria General, destino de /drf

local function Print(text)
    print("|cffd597ffDR Tracker Forever|r: " .. text)
end

local function SetLocked(locked)
    ns.db.locked = locked
    ns.ApplyDisplay()
    Print(locked and L.LOCKED or L.UNLOCKED)
end

local function Command(message)
    local command = (message or ""):lower():match("^%s*(%S*)")
    if command == "unlock" then
        SetLocked(false)
    elseif command == "lock" then
        SetLocked(true)
    elseif command == "test" then
        ns.Preview(20)
    elseif command == "clear" then
        ns.tracker:Clear()
        ns.Refresh()
        Print(L.CLEARED)
    elseif category then
        Settings.OpenToCategory(category:GetID())
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    DRTrackerForeverDB = DRTrackerForeverDB or {}
    local db = DRTrackerForeverDB
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    db.pos = db.pos or {}
    db.learned = db.learned or {}
    ns.db = db
    ns.tracker = ns.NewTracker(function() return db.resetTime end)
    ns.CreateDisplay()
    ns.StartSources()
    category = ns.CreateOptions()
    SLASH_DRTRACKERFOREVER1 = "/drf"
    SlashCmdList.DRTRACKERFOREVER = Command
end)
