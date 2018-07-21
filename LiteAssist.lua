--
-- LiteAssist World of Warcraft Addon
--
-- Copyright 2008-2015 Mike "Xodiv" Battersby
--
-- A simple addon that lets you set three keybindings, one to learn
-- an assist (aka MA) unit from your current target, one to learn an
-- assist from the unit your mouse is hovered over, and another to
-- assist the learned unit.
--

local Debug = false
local MacroName = "LiteAssistMacro"
local MacroMagicName = "{LiteAssistUnit}"
local MacroMagicId = "{LiteAssistUnitId}"

local CurrentName = nil
local QueuedName = nil
local CurrentId = nil
local OnTarget = false

local UpdateFrequency = TOOLTIP_UPDATE_TIME
local TimeSinceLastUpdate = 0
local UpdateQueued = nil

local AssistEventCallbacks = {}


-- ----------------------------------------------------------------------------
-- Debugging and other development functions
--

local function DebugMsg(msg)
    if not Debug then
        return
    end

    local msg = "|cff00ff00"..LITEASSIST_MODNAME..":|r "..msg.." (debug)"
    DEFAULT_CHAT_FRAME:AddMessage(msg, 0.5, 1, 0.5, 1)
end

function LiteAssist_SetDebug(val)
    if val and val ~= 0 then
        Debug = true
        DebugMsg("Debugging enabled")
    else
        DebugMsg("Debugging disabled")
        Debug = false
    end
end


-- ----------------------------------------------------------------------------
-- Version settings upgrade functions
--

local function UpgradeBindingNames()

    local BindingMap = {
        ["CLICK LiteAssistLearnTarget"] = "CLICK LiteAssistLearnTarget:LeftButton",
        ["CLICK LiteAssistLearnHover"] = "CLICK LiteAssistLearnHover:LeftButton",
        ["CLICK LiteAssistDo"] = "CLICK LiteAssistDo:LeftButton",
        ["LITEASSIST_LEARNTARGET"] = "CLICK LiteAssistLearnTarget:LeftButton",
        ["LITEASSIST_LEARNHOVER"] = "CLICK LiteAssistLearnHover:LeftButton",
        ["LITEASSIST_DO"] = "CLICK LiteAssistDo:LeftButton",
    }

    for old,new in pairs(BindingMap) do
        for _, keystr in ipairs({ GetBindingKey(old) }) do
            if keystr and keystr ~= "" then
                SetBinding(keystr, new)
            end
        end
    end

end


-- ----------------------------------------------------------------------------
-- Event handling functions
--

local function EnableEventHandling()

    DebugMsg("Enabling event handling.")

    local this = LiteAssist
    this:RegisterEvent("PLAYER_TARGET_CHANGED")
    this:RegisterEvent("GROUP_ROSTER_UPDATE")
    this:RegisterEvent("PLAYER_FOCUS_CHANGED")
    this:RegisterEvent("UNIT_PET")
    this:RegisterEvent("UPDATE_MACROS")
    this:RegisterEvent("PLAYER_REGEN_ENABLED")
    this:SetScript("OnUpdate", LiteAssist_OnUpdate)
end


local function DisableEventHandling()

    DebugMsg("Disabling event handling.")

    local this = LiteAssist
    this:UnregisterEvent("PLAYER_TARGET_CHANGED")
    this:UnregisterEvent("GROUP_ROSTER_UPDATE")
    this:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    this:UnregisterEvent("UNIT_PET")
    this:UnregisterEvent("UPDATE_MACROS")
    this:UnregisterEvent("PLAYER_REGEN_ENABLED")
    this:SetScript("OnUpdate", nil)
    LiteAssistTargetFrameIndicator:Hide()
end


-- ----------------------------------------------------------------------------
-- On-screen message box functions
--

local function Alert(msg)
    DebugMsg("Putting alert message on the screen: "..msg)
    LiteAssist:AddMessage(msg, 1.0, 1.0, 1.0, 1.0)
end


-- ----------------------------------------------------------------------------
-- Functions for Unit Id and Name manipulation
--

local function UnitIdToAssistName(id)

    if not UnitExists(id) then
        return nil
    elseif UnitIsUnit("pet", id) then
        return "pet"
    else
        return UnitName(id)
    end

end

local function UnitNameToId(name)

    -- Some code relies on this returning nil for nil
    if name == nil then
        return nil
    end

    if UnitName("player") == name then
        return "player"
    end

    if UnitName("pet") == name then
        return "pet"
    end

    if UnitName("focus") == name then
        return "focus"
    end

    local u

    for i = 1,4,1 do
        u = "party"..i
        if UnitName(u) == name then
            return u
        end
    end

    for i = 1,40,1 do
        u = "raid"..i
        if UnitName(u) == name then
            return u
        end
    end

    for i = 1,4,1 do
        u = "partypet"..i
        if UnitName(u) == name then
            return u
        end
    end

    for i = 1,40,1 do
        u = "raidpet"..i
        if UnitName(u) == name then
            return u
        end
    end

    return nil
end


-- ----------------------------------------------------------------------------
-- Macro functions
--

local function GetMacroText(name)
    local _, _, mtext, _ = GetMacroInfo(MacroName)

    DebugMsg("Checking to see if a "..MacroName.." macro exists.")

    if mtext ~= nil then
        DebugMsg("Found a macro named "..MacroName)
        DebugMsg("Macro text before substitution: ")
        DebugMsg(mtext)

        if string.find(mtext, MacroMagicName) then
            mtext = string.gsub(mtext, MacroMagicName, name)
            mtext = string.gsub(mtext, MacroMagicId, CurrentId or "none")
            DebugMsg("Macro text after substitution: ")
            DebugMsg(mtext)
        else
            DebugMsg("Macro text does not contain string "..MacroMagicName)
            mtext = nil
        end
    else
        DebugMsg("No macro found.")
    end
    
    if mtext == nil then
        mtext = "/assist "..name
        DebugMsg("Using default macro text: "..mtext)
    end

    if string.len(mtext) > 255 then
        Alert(LITEASSIST_MACROTOOLONG)
    end

    return mtext
end


-- ----------------------------------------------------------------------------
-- Functions for updating the OnTarget indicator (following assist)
--

local function SetOnTarget(playerChanged)

    if not CurrentId then
        if OnTarget then
            -- Must have cleared the assist
            LiteAssistTargetFrameIndicator:Hide()
            OnTarget = false
        end
        return
    end

    if UnitIsUnit("target", CurrentId.."target") then
        if not OnTarget then
            OnTarget = true
            LiteAssistTargetFrameIndicator:Show()
        end
    elseif OnTarget then
        OnTarget = false
        LiteAssistTargetFrameIndicator:Hide()
    end

end


-- ----------------------------------------------------------------------------
-- Functions for interacting with other addons
--

function LiteAssist_RegisterCallback(fn)

    DebugMsg("Registering callback.")

    table.insert(AssistEventCallbacks, fn)
end


function LiteAssist_UnregisterCallback(fn)

    DebugMsg("Unregistering callback.")

    for i, v in ipairs(AssistEventCallbacks) do
        if v == fn then
            table.remove(AssistEventCallbacks, i)
            return
        end
    end
end


local function DispatchCallbacks()

    DebugMsg("Dispatching Callbacks.")

    for _, fn in ipairs(AssistEventCallbacks) do
        pcall(fn, CurrentName, OnTarget)
    end
end


function LiteAssist_GetAssistName()
    DebugMsg("Current assist name requested by another addon.")
    return CurrentName
end


-- ----------------------------------------------------------------------------
-- Functions for learning the assist
--

local function UpdateId()
    local name = CurrentName

    if name == "pet" then
        DebugMsg("Unit is pet, using pet as unit id.")
        CurrentId = "pet"
    else
        -- Note: UnitNameToId(nil) == nil
        DebugMsg("Trying to find unit id for name "..(name or "nil"))
        CurrentId = UnitNameToId(name)
        DebugMsg("Unit id for "..(name or "nil").." is "..(CurrentId or "nil"))
    end
end


local function UpdateMacro()
    local name = CurrentName

    LiteAssistDo:SetAttribute("macrotext", GetMacroText(name or "target"))

    DebugMsg("Set assist to " .. (name or "target") .. " / " .. (CurrentId or "none"))
    
end


local function AssistChangeAlert(name)
    if name == nil then
        Alert(LITEASSIST_CLEAR)
    elseif name == "pet" then
        Alert(LITEASSIST_SET..LITEASSIST_PET)
    else
        Alert(LITEASSIST_SET..name)
    end
end

local function AssistChangeCombatAlert(name)
    if name == nil then
        Alert(LITEASSIST_COMBATCLEAR)
    elseif name == "pet" then
        Alert(LITEASSIST_COMBATSET..LITEASSIST_PET)
    else
        Alert(LITEASSIST_COMBATSET..name)
    end
end


local function Learn(token)

    if UnitExists(token) and not UnitCanAssist("player", token) then
        Alert(LITEASSIST_CANTASSISTNAME..UnitName(token))
        return
    end

    local assistname = UnitIdToAssistName(token)

    if InCombatLockdown() then
        AssistChangeCombatAlert(assistname)
        QueuedName = assistname
        UpdateQueued = true
        EnableEventHandling()
        return
    end

    CurrentName = assistname
    AssistChangeAlert(assistname)
    DispatchCallbacks()
    UpdateId()
    UpdateMacro()

    if CurrentName ~= nil then
        EnableEventHandling()
    else
        DisableEventHandling()
    end
end


-- ----------------------------------------------------------------------------
-- Functions called from Secure UI elements
--

function LiteAssist_LearnPreClick(self, button, down)

    local fromtoken = self:GetAttribute("X-realunit")

    DebugMsg("PreClick handler called for unit id "..fromtoken)

    Learn(fromtoken)
end


-- ----------------------------------------------------------------------------
-- Event handlers
--

function LiteAssist_OnLoad(self)

    DebugMsg("OnLoad handler called.")
    DebugMsg("A truckload of debugging output enabled.")

    -- Config upgrades here
    UpgradeBindingNames()

    -- Set up the default options for our assisting (assist target)
    LiteAssistDo:SetAttribute("type", "macro")
    CurrentName = nil
    UpdateId()
    UpdateMacro()

    -- If we don't use unit="none" the button won't trigger if we're
    -- not targeting anything.
    -- This does not stop us using the other units in the macro.
    -- We save the unit we really want as "X-realunit" so we can fetch it
    -- back later from whichever button was clicked.
    LiteAssistLearnTarget:SetAttribute("type", "macro")
    LiteAssistLearnTarget:SetAttribute("X-realunit", "target")
    LiteAssistLearnHover:SetAttribute("type", "macro")
    LiteAssistLearnHover:SetAttribute("X-realunit", "mouseover")

    -- Cause the actions to fire on keydown rather than keyup
    LiteAssistLearnTarget:RegisterForClicks("LeftButtonDown")
    LiteAssistLearnHover:RegisterForClicks("LeftButtonDown")
    LiteAssistDo:RegisterForClicks("LeftButtonDown")

    -- Default message duration on the alert frame
    LiteAssist:SetTimeVisible(3)

end

function LiteAssist_OnEvent(self, event, arg1, ...)

    DebugMsg("Received event: "..event)

    -- if event == "ADDON_LOADED" then
    --     return
    -- end

    if event == "GROUP_ROSTER_UPDATE" or
       event == "UNIT_PET" or
       event == "PLAYER_FOCUS_CHANGED" or
       event == "UPDATE_MACROS" then
        -- Fixes up the CurrentId and reloads/resubs the macro.
        if InCombatLockdown() then
            UpdateQueued = true
        else
            local oldid = CurrentId
            UpdateId()
            if CurrentId ~= oldid then
                UpdateMacro()
            end
        end
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        SetOnTarget(true)
        TimeSinceLastUpdate = 0
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat
        if not UpdateQueued or InCombatLockdown() then
            return
        end

        UpdateQueued = nil

        -- Can trigger because of roster update as well as in-combat learn
        if QueuedName then
            CurrentName = QueuedName
            QueuedName = nil
            AssistChangeAlert(CurrentName)
            DispatchCallbacks()
            if CurrentName ~= nil then
                EnableEventHandling()
            else
                DisableEventHandling()
            end
        end

        UpdateId()
        UpdateMacro()
        return
    end

end

function LiteAssist_OnUpdate(self, elapsed)

    TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed

    if TimeSinceLastUpdate < UpdateFrequency then
        return
    end

    SetOnTarget(false)
    TimeSinceLastUpdate = 0
end

