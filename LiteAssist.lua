--
-- LiteAssist World of Warcraft Addon
--
-- Copyright 2008 Mike "Xodiv" Battersby
--
-- A simple addon that lets you set three keybindings, one to learn
-- an assist (aka MA) unit from your current target, one to learn an
-- assist from the unit your mouse is hovered over, and another to
-- assist the learned unit.
--

local Debug = false
local MacroName = "LiteAssistMacro"
local MacroMagicName = "{LiteAssistUnit}"
local MacroMagicToken = "{LiteAssistUnitId}"

local CurrentUnitName = nil
local QueuedUnitName = nil
local CurrentUnitToken = nil

local UpdateQueued = nil

local AssistEventCallbacks = {}


-- ----------------------------------------------------------------------------
-- Debugging and other development functions
--

local function DebugMsg(msg)
    if not Debug then
        return
    end

    msg = "|cff00ff00"..LITEASSIST_MODNAME..":|r "..msg.." (debug)"
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
-- Event handling functions
--

local function EnableEventHandling()

    DebugMsg("Enabling event handling.")

    local this = LiteAssist
    this:RegisterEvent("GROUP_ROSTER_UPDATE")
    this:RegisterEvent("PLAYER_FOCUS_CHANGED")
    this:RegisterEvent("UNIT_PET")
    this:RegisterEvent("UPDATE_MACROS")
    this:RegisterEvent("PLAYER_REGEN_ENABLED")
end


local function DisableEventHandling()

    DebugMsg("Disabling event handling.")

    local this = LiteAssist
    this:UnregisterEvent("GROUP_ROSTER_UPDATE")
    this:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    this:UnregisterEvent("UNIT_PET")
    this:UnregisterEvent("UPDATE_MACROS")
    this:UnregisterEvent("PLAYER_REGEN_ENABLED")
end


-- ----------------------------------------------------------------------------
-- On-screen message box functions
--

local function Alert(msg)
    DebugMsg("Putting alert message on the screen: "..msg)
    LiteAssist:AddMessage(msg, 1.0, 1.0, 1.0, 1.0)
end


-- ----------------------------------------------------------------------------
-- Functions for Unit Token and Name manipulation
--

local function UnitAssistName(unitToken)

    if not UnitExists(unitToken) then
        return nil
    elseif UnitIsUnit("pet", unitToken) then
        return "pet"
    elseif WOW_PROJECT_ID == 18 then
        return NameUtil.GetUnmodifiedUnitFullName(unitToken)
    else
        return UnitName(unitToken)
    end

end

local function AssistNameToUnitToken(name)

    -- Some code relies on this returning nil for nil
    if name == nil then
        return nil
    end

    if UnitAssistName("player") == name then
        return "player"
    end

    if UnitAssistName("pet") == name then
        return "pet"
    end

    if UnitAssistName("focus") == name then
        return "focus"
    end

    local u

    for i = 1,4,1 do
        u = "party"..i
        if UnitAssistName(u) == name then
            return u
        end
    end

    for i = 1,40,1 do
        u = "raid"..i
        if UnitAssistName(u) == name then
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
            mtext = string.gsub(mtext, MacroMagicToken, CurrentUnitToken or "none")
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
        pcall(fn, CurrentUnitName)
    end
end


function LiteAssist_GetAssistName()
    DebugMsg("Current assist name requested by another addon.")
    return CurrentUnitName
end


-- ----------------------------------------------------------------------------
-- Functions for learning the assist
--

local function UpdateUnitToken()
    local name = CurrentUnitName

    if name == "pet" then
        DebugMsg("Unit is pet, using pet as unit id.")
        CurrentUnitToken = "pet"
    else
        -- Note: AssistNameToUnitToken(nil) == nil
        DebugMsg("Trying to find unit id for name "..(name or "nil"))
        CurrentUnitToken = AssistNameToUnitToken(name)
        DebugMsg("Unit id for "..(name or "nil").." is "..(CurrentUnitToken or "nil"))
    end
end


local function UpdateMacro(name, id)
    LiteAssistDo:SetAttribute("macrotext", GetMacroText(name or "target"))
    LiteAssistMB:SetAttribute("unit", name or "target")
    DebugMsg("Set assist to " .. (name or "target") .. " / " .. (id or "none"))
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
        Alert(LITEASSIST_CANTASSISTNAME..UnitAssistName(token))
        return
    end

    local assistname = UnitAssistName(token)

    if InCombatLockdown() then
        AssistChangeCombatAlert(assistname)
        QueuedUnitName = assistname
        UpdateQueued = true
        EnableEventHandling()
        return
    end

    CurrentUnitName = assistname
    AssistChangeAlert(assistname)
    DispatchCallbacks()
    UpdateUnitToken()
    UpdateMacro(CurrentUnitName, CurrentUnitToken)

    if CurrentUnitName ~= nil then
        EnableEventHandling()
    else
        DisableEventHandling()
    end
end


-- ----------------------------------------------------------------------------
-- Functions called from Secure UI elements
--

function LiteAssist_LearnPreClick(self)

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

    -- This makes the box just high enough for one line of text
    local _, h, _ = self:GetFont()
    self:SetHeight(math.ceil(h) + 2)

    -- Set up the default options for our assisting (assist target)
    -- https://github.com/Stanzilla/WoWUIBugs/issues/317#issuecomment-1510847497
    LiteAssistDo:SetAttribute("type", "macro")
    LiteAssistDo:SetAttribute("pressAndHoldAction", true)
    LiteAssistDo:SetAttribute("typeRelease", "macro")
    LiteAssistDo:RegisterForClicks("AnyDown")

    LiteAssistMB:SetAttribute("type", "assist")
    LiteAssistMB:SetAttribute("pressAndHoldAction", true)
    LiteAssistMB:SetAttribute("typeRelease", "assist")
    LiteAssistMB:RegisterForClicks("AnyDown")

    CurrentUnitName = nil
    UpdateUnitToken()
    UpdateMacro()

    -- If we don't use unit="none" the button won't trigger if we're
    -- not targeting anything.
    -- This does not stop us using the other units in the macro.
    -- We save the unit we really want as "X-realunit" so we can fetch it
    -- back later from whichever button was clicked.
    LiteAssistLearnTarget:SetAttribute("X-realunit", "target")
    LiteAssistLearnTarget:SetAttribute("pressAndHoldAction", true)
    LiteAssistLearnHover:SetAttribute("X-realunit", "mouseover")
    LiteAssistLearnHover:SetAttribute("pressAndHoldAction", true)

    -- Cause the actions to fire on keydown rather than keyup
    LiteAssistLearnTarget:RegisterForClicks("AnyDown")
    LiteAssistLearnHover:RegisterForClicks("AnyDown")

    -- Default message duration on the alert frame
    LiteAssist:SetTimeVisible(3)

end

function LiteAssist_OnEvent(_, event)

    DebugMsg("Received event: "..event)

    -- if event == "ADDON_LOADED" then
    --     return
    -- end

    if event == "GROUP_ROSTER_UPDATE" or
       event == "UNIT_PET" or
       event == "PLAYER_FOCUS_CHANGED" or
       event == "UPDATE_MACROS" then
        -- Fixes up the CurrentUnitToken and reloads/resubs the macro.
        if InCombatLockdown() then
            UpdateQueued = true
        else
            local oldUnitToken = CurrentUnitToken
            UpdateUnitToken()
            if CurrentUnitToken ~= oldUnitToken then
                UpdateMacro(CurrentUnitName, CurrentUnitToken)
            end
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat
        if not UpdateQueued or InCombatLockdown() then
            return
        end

        UpdateQueued = nil

        -- Can trigger because of roster update as well as in-combat learn
        if QueuedUnitName then
            CurrentUnitName = QueuedUnitName
            QueuedUnitName = nil
            AssistChangeAlert(CurrentUnitName)
            DispatchCallbacks()
            if CurrentUnitName ~= nil then
                EnableEventHandling()
            else
                DisableEventHandling()
            end
        end

        UpdateUnitToken()
        UpdateMacro(CurrentUnitName, CurrentUnitToken)
        return
    end

end
