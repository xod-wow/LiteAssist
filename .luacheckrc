exclude_files = {
    "libs/",
}

ignore = {
    "11./BINDING_.*", -- Setting an undefined (Keybinding) global variable
    "631", -- line too long
}

globals = {
    "LITEASSIST_BROKERTOOLTIP",
    "LITEASSIST_CANTASSISTNAME",
    "LITEASSIST_CLEAR",
    "LITEASSIST_COMBATCLEAR",
    "LITEASSIST_COMBATNOLEARN",
    "LITEASSIST_COMBATSET",
    "LiteAssist_GetAssistName",
    "LiteAssist_LearnPreClick",
    "LITEASSIST_MACROTOOLONG",
    "LiteAssist_OnEvent",
    "LiteAssist_OnLoad",
    "LITEASSIST_PET",
    "LiteAssist_RegisterCallback",
    "LITEASSIST_SET",
    "LiteAssist_SetDebug",
    "LiteAssist_UnregisterCallback",
    "LiteAssist",
    "LiteAssistDo",
    "LiteAssistLearnHover",
    "LiteAssistLearnTarget",
    "LiteAssistMB",
}

read_globals = {
    "DEFAULT_CHAT_FRAME",
    "WOW_PROJECT_ID",
    "NameUtil",
    "GetMacroInfo",
    "UnitExists",
    "UnitName",
    "InCombatLockdown",
    "GetLocale",
    "LibStub",
    "GameTooltip",
    "PET",
    "UnitCanAssist",
    "UnitIsUnit",
}
