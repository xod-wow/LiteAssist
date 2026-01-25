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
	    icon = "Interface\\Icons\\Ability_DualWield.blp"
	}
    )


function dataobj:OnTooltipShow()
    GameTooltip:AddLine("Displays your current LiteAssist unit")
end

local function UpdateName(name)
    dataobj.text = name or 'target'
end

LiteAssist_RegisterCallback(UpdateName)
