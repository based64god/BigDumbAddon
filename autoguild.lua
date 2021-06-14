require("libs/autoinv")
require("libs/autopurge")
require("libs/autoadvert")
require("libs/utils")

-- upvalue the globals
local _G = getfenv(0)
local LibStub = _G.LibStub
local pairs = _G.pairs
local GuildInvite = _G.GuildInvite
local InviteUnit = _G.C_PartyInfo.InviteUnit or _G.InviteUnit
local StaticPopupDialogs = _G.StaticPopupDialogs

local addonName = "autoguild"

local AG = LibStub('AceAddon-3.0'):NewAddon(addonName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0');
if not AG then return end

local defaultGuildPurgeDays = 30

local warriorRepr = {"warrior", "war"}
local warriorSpecs = {"arms", "fury", "protection", "prot"}

local mageRepr = {"mage"}
local mageSpecs = {"fire", "frost", "arcane"}

local hunterRepr = {"hunter", "hunt"}
local hunterSpecs = {"beast master", "marksman", "survival"}

local rogueRepr = {"rogue", "rog", "rouge"}
local rogueSpecs = {"combat", "assassination", "sublety"}

local warlockRepr = {"warlock", "lock"}
local warlockSpecs = {"demonology", "destruction", "affliction"}

local priestRepr = {"priest"}
local priestSpecs = {"holy", "shadow", "discipline"}

local paladinRepr = {"paladin", "pala"}
local paladinSpecs = {"protection", "holy", "retribution"}

local shamanRepr = {"shaman", "sham"}
local shamanSpecs = {"restoration", "elemental", "enhancement"}

local druidRepr = {"druid", "drood"}
local druidSpecs = {"restoration", "feral", "balance"}

local validClasses = {
    table.unpack(warriorRepr),
    table.unpack(mageRepr),
    table.unpack(hunterRepr),
    table.unpack(rogueRepr),
    table.unpack(warlockRepr),
    table.unpack(priestRepr),
    table.unpack(paladinRepr),
    table.unpack(shamanRepr),
    table.unpack(druidRepr)
}

local classSpecMap = {}

AGDB = AGDB or {}

function AG:OnInitialize()
    self.DB = AGDB
    for x in warriorSpecs do
        classSpecMap[x] = warriorRepr
    end
    for x in mageSpecs do
        classSpecMap[x] = mageRepr
    end
    for x in hunterSpecs do
        classSpecMap[x] = hunterRepr
    end
    for x in rogueSpecs do
        classSpecMap[x] = rogueRepr
    end

    self:InitDefaults()
    self.Config:Initialize()

    self:RegisterEvent("CHAT_MSG_BN_WHISPER", function(_, message, _, _, _, _, _, _, _, _, _, _, _, bnetIDAccount, _)
        self:HandleBnetWhisper(message, bnetIDAccount, false)
    end)
    self:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM", function(_, message, _, _, _, _, _, _, _, _, _, _, _, bnetIDAccount, _)
        self:HandleBnetWhisper(message, bnetIDAccount, true)
    end)
    self:RegisterEvent("CHAT_MSG_WHISPER", function(_, message, characterName, _)
        self:HandleWhisper(message, characterName, false)
    end)
    self:RegisterEvent("CHAT_MSG_WHISPER_INFORM", function(_, message, characterName, _)
        self:HandleWhisper(message, characterName, true)
    end)
    self:RegisterChatCommand('ag', self.Config.OpenConfig)

    StaticPopupDialogs["AGguildinvPopup"] = {
        text = "Do you want to invite %s to your guild (they appear to be a %s %s)?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(_, characterName)
            GuildInvite(characterName)
        end,
        OnCancel = function() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["AGgroupinvPopup"] = {
        text = "Do you want to invite %s to your party/raid (they appear to be a %s %s)?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(_, characterName)
            InviteUnit(characterName)
        end,
        OnCancel = function() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function AG:InitDefaults()
    local defaults = {
        ginv = {
            ginv = true,
            guildinv = true,
            ginvite = true
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

    for property, value in pairs(defaults) do
        if self.DB[property] == nil then
            self.DB[property] = value
        end
    end
end

