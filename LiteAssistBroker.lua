--
-- LiteAssistBroker
--
-- Copyright 2008 Mike "Xodiv" Battersby
--
-- Adds LibDataBroker support to LiteAssist
--

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

local dataobj = ldb:NewDataObject("LiteAssist",
	{
	    type = "data source",
	    label = "LiteAssist",
	    text = LiteAssist_GetAssistName() or 'target',
	    icon = "Interface\\Icons\\Ability_DualWield",
            OnTooltipShow = function (tooltip) tooltip:AddLine(LITEASSIST_BROKERTOOLTIP) end,
	}
    )

local function UpdateName(name)
    dataobj.text = name or 'target'
end

LiteAssist_RegisterCallback(UpdateName)
