local ADDON_NAME, ns = ...

-- ==========================================
-- IDIOMA POR DEFECTO (enUS / enGB)
-- ==========================================
-- Este fichero define TODAS las claves. Los demas Locales/<idioma>.lua se
-- cargan despues y sobrescriben las suyas; lo que falte se queda en ingles.

local L = ns.L or {}
ns.L = L

L["GENERAL_HEADER"] = "General"
L["DRAG_HINT"] = "Drag to move"
L["LOCK"] = "Lock position"
L["VERSION"] = "Version:"
L["AUTHOR"] = "Author:"
L["LINKS"] = "Links"
L["COMMANDS"] = "Commands"
L["SELECT"] = "Select"
L["SELECT_TOOLTIP"] = "Selects the whole link so you can copy it with Ctrl+C. WoW does not let addons write to the clipboard, so the last step is yours."
L["CMD_OPEN"] = "Opens the settings."
L["DEFAULTS"] = "Default Values"
L["UNLOCKED"] = "Icons unlocked: drag them, then type /drf lock."
L["LOCKED"] = "Icons locked."
L["CLEARED"] = "Tracked DR cleared."
L["SHOW_HEADER"] = "Show DR on"
L["SHOW_TARGET"] = "Your target"
L["SHOW_TARGET_TOOLTIP"] = "Icons above the target frame. The text and border show how long the next crowd control of that type lasts: 50%, 25% or 0% (immune). The spiral shows when it resets."
L["SHOW_FOCUS"] = "Your focus"
L["SHOW_FOCUS_TOOLTIP"] = "The same icons above the focus frame."
L["SHOW_PLAYER"] = "You"
L["SHOW_PLAYER_TOOLTIP"] = "DR of the crowd control used on you, above your player frame."
L["TRACK_HEADER"] = "Tracking"
L["NPCS"] = "Also track NPCs"
L["NPCS_TOOLTIP"] = "Off: only enemy players. On: also creatures, handy to try the addon out."
L["GROUP"] = "Crowd control from your group"
L["GROUP_TOOLTIP"] = "Also counts the crowd control your party members use on their target, not only yours."
L["RESET_TIME"] = "DR reset"
L["RESET_TIME_TOOLTIP"] = "Seconds after a crowd control ends until the next one lasts in full again."
L["LOOK_HEADER"] = "Appearance"
L["LOCK_TOOLTIP"] = "Unlock to drag the target, focus and player icons anywhere on the screen."
L["SIZE"] = "Icon size"
L["SIZE_TOOLTIP"] = "Size of the DR icons."
L["SHOW_TEXT"] = "Next duration under the icon"
L["SHOW_TEXT_TOOLTIP"] = "50%: the next one lasts half. 25%: a quarter. 0%: immune. The border has the same colour."
L["PREVIEW"] = "Preview"
L["PREVIEW_TOOLTIP"] = "Shows sample icons for 20 seconds."
L["ABOUT_DESC"] = "Diminishing returns (DR) of crowd control on your target, your focus and you, for WoW Forever. Forever hides the combat log from addons, so the DR is counted from your and your group's casts and from the effects the game lets addons see. The settings are in General."
L["CMD_UNLOCK"] = "Unlocks the icons so you can drag them."
L["CMD_LOCK"] = "Locks the icons in place."
L["CMD_TEST"] = "Shows sample icons for 20 seconds."
L["CMD_CLEAR"] = "Forgets every tracked DR."
L["OPTIONS_TITLE"] = "DR Tracker Forever Options"
