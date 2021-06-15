-- upvalue the globals
local _G = getfenv(0)
local LibStub = _G.LibStub
local BNGetFriendInfoByID = _G.BNGetFriendInfoByID
local BNGetGameAccountInfo = _G.BNGetGameAccountInfo
local GuildInvite = _G.GuildInvite
local PartyInvite = _G.C_PartyInfo.InviteUnit or _G.InviteUnit
local StaticPopupDialogs = _G.StaticPopupDialogs
local StaticPopup_Show = _G.StaticPopup_Show
local GetGuildRosterInfo = _G.GetGuildRosterInfo
local GetNumGuildMembers = _G.GetNumGuildMembers
local GuildRosterSetPublicNote = _G.GuildRosterSetPublicNote
local GetChannelName = _G.GetChannelName
local SendChatMessage = _G.SendChatMessage
local Timer = _G.C_Timer.After
local Ticker = _G.C_Timer.NewTicker


local addonName = "BigDumbAddon"

local BDA = LibStub('AceAddon-3.0'):NewAddon(addonName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0');
if not BDA then return end

-- 
-- UTILS
-- 

-- normalize(string) removes all whitespace from a string
-- returns string
function string.normalize(str)
    return string.gsub(str, "%s+", "")
end

-- split(string, string) turns a string s into a table, delimited by the given delimiter
-- returns table
function string.split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

-- 
-- CUSTOM HANDLES
-- 

-- RespondWithErrorData(string, string) takes a message and a player and sends them a generic error message.
function BDA:RespondWithErrorData(message, player)
    SendChatMessage(string.format("Hi. You sent a message my addon couldn't handle. You sent \"%s\" and I was expecting \"inv SPEC CLASS\" or \"ginv SPEC CLASS PROF1 PROF2\"", tostring(message)), "WHISPER", nil, player)
end

-- 
function BDA:SetGuildNote(player, note)
    local index = self:FindGuildIndex(player)
    if (index == -1) then
        self:Print("Player", player, "not found.")
        return
    end
    self:Print("Attempting to set guild note:", index, player, note)
    GuildRosterSetPublicNote(index, note)
end

-- FindGuildIndex(string) returns the guild index of the player with the matching name
function BDA:FindGuildIndex(player)
    for i = 1, GetNumGuildMembers(), 1
    do
        local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(i)
        if (name == player) then
            return i
        end
    end
    return -1
end

-- ProcessGuildInvite(table, string) determines if query is a valid request,
-- and then issues the invite
-- returns nil
function BDA:ProcessGuildInvite(query, player)
    local invQuery = query[1]
    local classSpecProfs = string.format("%s %s %s %s", query[2], query[3], query[4], query[5])
    if BDADB.defaults.ginv[invQuery] then
        local dialog = StaticPopup_Show("BDAGuildInvPopup", player, classSpecProfs)
        if (dialog) then
            dialog.data = player
        end
        Timer(10, function() self:SetGuildNote(player, classSpecProfs) end)
    end
end

-- ProcessRaidInvite()
function BDA:ProcessRaidInvite(query, player)
    local invQuery = query[1]
    local classSpec = string.format("%s %s", query[2], query[3])
    if BDADB.defaults.inv[invQuery] then
        if(BDADB.defaults.confirm) then
            local dialog = StaticPopup_Show("BDAGroupInvPopup", player, classSpec)
            if (dialog) then
                dialog.data = player
            end
        else
            self:Print("Trying to invite " .. player .." to your party/raid")
            PartyInvite(player)
        end
    end
end

-- ProcessMessage() is the meeting point for the event handlers
-- loosely, it parses a message into
function BDA:ProcessMessage(outgoing, message, playerName, guid)
    self:Print("entering ProcessMessage", outgoing, message, playerName, guid)
    if (outgoing) then
        return
    end
    message = string.split(message, " ")
    if (#message == 5) then
        self:ProcessGuildInvite(message, playerName)
        return
    elseif (#message == 3) then
        self:ProcessRaidInvite(message, playerName)
        return
    elseif (#message == 1) then
        self:ProcessInfoRequest(message, playerName)
        return
    end
    self:RespondWithErrorData(message, playerName)
    return
end


-- WhisperHandler() processes the player's message, playerName, and guid
-- into a guild invite (include guild note), or party/raid invite
function BDA:WhisperHandler(outgoing, message, playerName, guid)
    self:ProcessMessage(outgoing, message, playerName, guid)
end

-- BNWhisperHandler() is like WhisperHandler() except it processes BNet messages,
-- so we must provide it a BNet ID
function BDA:BNWhisperHandler(outgoing, message, playerName, guid, bnSenderID)
    local characterName = self:GetPlayerFromBNID(bnSenderID)
    if (characterName) then
        self:ProcessMessage(outgoing, message, characterName, guid)
    end
end



function BDA:GetPlayerFromBNID(bnSenderID)
    -- retail
    if(C_BattleNet and C_BattleNet.GetAccountInfoByID) then
        local accountInfo = C_BattleNet.GetAccountInfoByID(bnSenderID);
        if(accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName and accountInfo.gameAccountInfo.realmName) then
            return accountInfo.gameAccountInfo.characterName .. '-' .. accountInfo.gameAccountInfo.realmName;
        end
    -- classic/tbc
    elseif(BNGetFriendInfoByID and BNGetGameAccountInfo) then
        local _, _, _, _, _, bnetIDGameAccount, _ = BNGetFriendInfoByID(bnSenderID);
        local _, characterName, _, realmName, _  = BNGetGameAccountInfo(bnetIDGameAccount);
        return characterName .. '-' .. realmName;
    end
    return nil;
end

-- 
-- GETTERS/SETTERS
-- 

function BDA:GetWindow(info)
    return BDADB.inactivityWindow
end

function BDA:SetWindow(info, newValue)
    BDADB.inactivityWindow = tonumber(newValue)
end

function BDA:GetAdContent(info)
    return BDADB.adContent
end

function BDA:SetAdContent(info, val)
    BDADB.adContent = val
end

function BDA:GetAdChannels(info)
    return BDADB.adChannels
end

function BDA:SetAdChannels(info, val)
    BDADB.adChannels = string.split(val)
end

function BDA:GetAdDelay(info)
    return BDADB.adDelayTime
end

function BDA:SetAdDelay(info, val)
    BDADB.adDelayTime = tonumber(val)
end

function BDA:GetDebug(info)
    return BDADB.debugLogging
end

function BDA:SetDebug(info, val)
    val = val:lower()
    if (val=="true") then
        BDADB.debugLogging = true
    elseif (val=="false") then
        BDADB.debugLogging = false
    end
end

-- 
-- WOWAPI HANDLES
-- 

function BDA:OnInitialize()
    BDADB = BDADB or {}
    BDADB.inactivityWindow = BDADB.inactivityWindow or 30
    BDADB.adContent = BDADB.adContent or "join my guild pls"
    BDADB.adDelayTime = BDADB.adDelayTime or 15
    BDADB.adChannels = BDADB.adChannels or {"general"}
    BDADB.debugLogging = BDADB.debugLogging or false
    BDADB.advertising = BDADB.advertising or false
    BDADB.defaults = {
        ginv = {
            ginv = true,
            guildinv = true,
            ginvite = true,
            guildinivte = true,
        },
        inv = {
            inv = true,
            invite = true
        },
        confirm = true,
        keywordMatchMiddle = true,
        triggerOutgoingGInv = true,
        triggerOutgoingInv = false,
    }

    local options = {
        name = "BigDumbAddon",
        handler = BDA,
        type = 'group',
        args = {
            purge = {
                type = "input",
                name = "Purge Window",
                desc = string.format("Default inactivity time in days.\nCurrently: %s.\n\n", BDADB.inactivityWindow),
                usage = "<time in days>",
                get = "GetWindow",
                set = "SetWindow",
            },
            debug = {
                type = "input",
                name = "Toggle debug logging",
                desc = string.format("Don't enable this unless you know what you're doing.\nCurrently: %s.\n\n", tostring(BDADB.debugLogging)),
                usage = "<toggle debugging>",
                cmdHidden = true,
                get = "GetDebug",
                set = "SetDebug",
            },
        }
    }

    StaticPopupDialogs["BDAGuildInvPopup"] = {
        text = "Do you want to invite %s to your guild (they appear to be a %s)?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(_, characterName)
            GuildInvite(characterName)
        end,
        OnCancel = function() end,
        timeout = 5,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["BDAGroupInvPopup"] = {
        text = "Do you want to invite %s to your party/raid (they appear to be a %s)?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(_, characterName)
            PartyInvite(characterName)
        end,
        OnCancel = function() end,
        timeout = 5,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options, {"bda"})

    self:RegisterEvent("CHAT_MSG_BN_WHISPER", function(event, text, playerName, languageName,
            channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName,
            unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)

        if (BDADB.debugLogging) then
            self:Print("---DEBUGGING---\n", event, text, playerName, languageName,
            channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName,
            unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)
        end
        self:BNWhisperHandler(false, text, playerName, guid, bnSenderID)
    end)

    self:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM", function(event, text, playerName, languageName,
            channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName,
            unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)

        if (BDADB.debugLogging) then
            self:Print("---DEBUGGING---\n", event, text, playerName, languageName,
            channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName,
            unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)
        end
        self:BNWhisperHandler(true, text, playerName, guid, bnSenderID)
    end)

    self:RegisterEvent("CHAT_MSG_WHISPER", function(event, text, playerName, languageName,
            channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName,
            unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)

        if (BDADB.debugLogging) then
            self:Print("---DEBUGGING---\n", event, text, playerName, languageName,
            channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName,
            unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)
        end
        self:WhisperHandler(false, text, playerName, guid)
    end)

    self:RegisterEvent("CHAT_MSG_WHISPER_INFORM", function(event, text, playerName, languageName,
            channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName,
            unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)

        if (BDADB.debugLogging) then
            self:Print("---DEBUGGING---\n", event, text, playerName, languageName,
            channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName,
            unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)
        end
        self:WhisperHandler(true, text, playerName, guid)
    end)
end

function BDA:OnEnable()
    -- Called when the addon is enabled
    local flavor = {
        "hates vegans",
        "now 76% bigger and dumber",
        "thinks Nathan is small",
        "has the VTEC",
        "busy playing Battlefield",
        "Chris' other gay mom",
        "still isn't attuned",
        "wonders when Zack will stop showing up to raid",
        "Chinese malware",
        "now with extra Kratom",
        "secretly packed with intrusive homoerotic thoughts",
        "Emmett's boyfriend",
        "made from the blood of dead memes",
        "Space Monke will rise again",
        "on the front page of /r/ambien",
        "available on the 5G network",
        "needs Jesus",
        "built different",
    }
    self:Print("See /bda for details")
    self:Print(flavor[math.random(#flavor)])
end

function BDA:OnDisable()
    -- Called when the addon is disabled
end

