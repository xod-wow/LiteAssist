--
-- LiteAssist Localisation Strings
-- Copyright 2008 Mike "Xodiv" Battersby
--

local locale = GetLocale()

-- ----------------------------------------------------------------------
-- Default / enUS locale

BINDING_HEADER_LITEASSIST_TITLE = "LiteAssist"
_G["BINDING_NAME_CLICK LiteAssistLearnTarget:LeftButton"] = "Learn Assist From Target"
_G["BINDING_NAME_CLICK LiteAssistLearnHover:LeftButton"] = "Learn Assist From MouseOver"
_G["BINDING_NAME_CLICK LiteAssistDo:LeftButton"] = "Assist Learned Unit"

LITEASSIST_SET = "Assist set: "
LITEASSIST_CLEAR = "Assist cleared"
LITEASSIST_COMBATNOLEARN = "Can't learn assist in combat"
LITEASSIST_COMBATSET = "Assist queued for combat end: "
LITEASSIST_COMBATCLEAR = "Assist clear queued for combat end"
LITEASSIST_CANTASSISTNAME = "Can't assist "
LITEASSIST_MACROTOOLONG = "LiteAssistMacro ends up longer than 255 characters"
LITEASSIST_BROKERTOOLTIP = "Displays your current LiteAssist unit"
LITEASSIST_PET = PET

-- ----------------------------------------------------------------------
-- Russian (ruRU) ZamestoTV

if locale == "ruRU" then

BINDING_HEADER_LITEASSIST_TITLE = "LiteAssist"
_G["BINDING_NAME_CLICK LiteAssistLearnTarget:LeftButton"] = "Запомнить цель для ассиста"
_G["BINDING_NAME_CLICK LiteAssistLearnHover:LeftButton"] = "Запомнить цель под курсором"
_G["BINDING_NAME_CLICK LiteAssistDo:LeftButton"] = "Ассист запомненной цели"

LITEASSIST_SET = "Установлен ассист для: "
LITEASSIST_CLEAR = "Ассист сброшен"
LITEASSIST_COMBATNOLEARN = "Нельзя сменить цель ассиста в бою"
LITEASSIST_COMBATSET = "Смена ассиста отложена до окончания боя: "
LITEASSIST_COMBATCLEAR = "Сброс ассиста отложен до окончания боя"
LITEASSIST_CANTASSISTNAME = "Невозможно ассистировать цели "
LITEASSIST_MACROTOOLONG = "Макрос LiteAssistMacro превышает длину в 255 символов"
LITEASSIST_PET = "Питомец"

end
