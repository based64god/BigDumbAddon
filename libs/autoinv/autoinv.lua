require("../utils")

-- upvalue the globals
local _G = getfenv(0)
local LibStub = _G.LibStub
local pairs = _G.pairs
local InviteUnit = _G.C_PartyInfo.InviteUnit or _G.InviteUnit
local C_BattleNet = _G.C_BattleNet
local BNGetFriendInfoByID = _G.BNGetFriendInfoByID
local BNGetGameAccountInfo = _G.BNGetGameAccountInfo
local StaticPopup_Show = _G.StaticPopup_Show

local addonName = "autoguild"

local validGinvs = {"ginv", "guildinv", "ginvite", "guildinvite"}

local AG = LibStub('AceAddon-3.0'):NewAddon(addonName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0');
if not AG then return end

function AG:HandleWhisper(message, characterName, outgoing)
    self:ProcessMessage(message, characterName, outgoing)
end

function AG:GetCharacterNameFromPresenceID(presenceID)
    if(C_BattleNet and C_BattleNet.GetAccountInfoByID) then
        -- retail
        local accountInfo = C_BattleNet.GetAccountInfoByID(presenceID);
        if(accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName and accountInfo.gameAccountInfo.realmName) then
            return accountInfo.gameAccountInfo.characterName .. '-' .. accountInfo.gameAccountInfo.realmName;
        end
    elseif(BNGetFriendInfoByID and BNGetGameAccountInfo) then
        -- classic
        local _, _, _, _, _, bnetIDGameAccount, _ = BNGetFriendInfoByID(presenceID);
        local _, characterName, _, realmName, _  = BNGetGameAccountInfo(bnetIDGameAccount);
        return characterName .. '-' .. realmName;
    end
    return nil;
end

function AG:HandleBnetWhisper(message, presenceID, outgoing)
    local characterName = self:GetCharacterNameFromPresenceID(presenceID);
    if(characterName) then
        self:ProcessMessage(message, characterName, outgoing);
    end
end

function AG:ProcessMessage(message, characterName, outgoing)
    message = message:lower():trim()

    local characterClass = self:GetClassFromName(characterName);
    local maybeCharacterClass = self:GetClassFromMessage(message);
    if characterClass ~= maybeCharacterClass then print("You got a message from %s claiming to be %s but was actually %s", characterName, maybeCharacterClass, characterClass) end;
    local characterSpec = self:GetSpecFromMessage(message);

    if self.DB.ginv[message] and (not outgoing or self.DB.triggerOutgoingGInv) then
        local dialog = StaticPopup_Show("AGguildinvPopup", characterName, characterClass, characterSpec)
        if (dialog) then
            dialog.data = characterName
        end
        return
    elseif self.DB.inv[message] and (not outgoing or self.DB.triggerOutgoingInv) then
        if(self.DB.confirm) then
            local dialog = StaticPopup_Show("AGgroupinvPopup", characterName, characterClass, characterSpec)
            if (dialog) then
                dialog.data = characterName
            end
        else
            self:Print("Trying to invite" .. characterName .." to your party/raid")
            InviteUnit(characterName)
        end
        return
    end

    if self.DB.keywordMatchMiddle then
        local found = false
        message = ' ' .. message .. ' '
        -- wrapping spaces around message, so that it starts and ends with a non alphabetical letter
        for phrase in pairs(self.DB.ginv) do
            if (not outgoing) and message:find('[^A-z]' .. phrase:lower():trim() .. '[^A-z]') then
                local dialog = StaticPopup_Show("AGguildinvPopup", characterName, characterClass, characterSpec)
                if (dialog) then
                    found = true
                    dialog.data = characterName
                end
                break
            end
        end

        if not found then
            for phrase in pairs(self.DB.inv) do
                if (not outgoing) and message:find('[^A-z]' .. phrase:lower():trim() .. '[^A-z]') then
                    local dialog = StaticPopup_Show("AGgroupinvPopup", characterName, characterClass, characterSpec)
                    if (dialog) then
                        found = true
                        dialog.data = characterName
                    end
                    break
                end
            end
        end

        if found then
            self:Print("An invite keyword was found in the whisper you received. Type \"/ag\" and disable 'Smart Match' if you don't want long whispers to trigger an invite.")
            if(not self.DB.confirm) then
                self:Print("The confirmation dialog cannot be disabled when Smart Match got triggered")
            end
        end
    end
end

function AG:GetClassFromName(characterName)
end

function AG:GetClassFromMessage(message)
    local tabledMessage = split(message, " ")
    local potentialGinv = tabledMessage[1]:lower()
    local classFromMessage = tabledMessage[2]:lower()
    if #tabledMessage < 3 then return "" end
    if not has(validGinvs, potentialGinv) then return "" end
    -- exhaustive
    if #tabledMessage >= 3 then return classFromMessage end
end

function AG:GetSpecFromMessage(message)
    local tabledMessage = split(message, " ")
    -- can't query for spec. need to parse it out.
    -- TODO: validate spec isn't retarded.
    if #tabledMessage < 3 then return "" end
    return tabledMessage[3]
end

function AG:GetProfsFromMessage(message)
    local tabledMessage = split(message, " ")
    -- return nothing, no profs provided
    if #tabledMessage < 3 then return "" end
    -- return both profs
    if #tabledMessage >= 5 then return tabledMessage[4], tabledMessage[5] end
    -- return only 1
    if #tabledMessage >= 4 then return tabledMessage[4] end
end