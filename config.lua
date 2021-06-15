local _G = getfenv(0)
local LibStub = _G.LibStub
local GetAddOnMetadata = _G.GetAddOnMetadata
local InterfaceOptionsFrame_OpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory
local coroutine = _G.coroutine

local addonName = "DumbAddon"

local DA = LibStub("AceAddon-3.0"):GetAddon(addonName)
if not DA then return end

DA.Config = DA.Config or {}
local Config = DA.Config

Config.Version = GetAddOnMetadata(addonName, "Version") or ""

-- count(int, int) provides a coroutine-wrapped counter that increments each time you call it
-- starts at 1 and increments by 1 by default
-- returns number
local function count(start, increment)
    start = start or 1
    increment = increment or 1
    return coroutine.wrap(
        function ()
            local count = start
            while true do
                count = count + increment
                coroutine.yield(count)
            end
        end
    )
end

function Config:GetOptions()
    local counter = count()
    local options = {
        type = 'group',
        get = function(info) return Config:GetConfig(info[#info]); end,
        set = function(info, value) return Config:SetConfig(info[#info], value); end,
        args = {
            version = {
                order = counter(),
                type = "description",
                name = "Version: " .. self.version
            },
            triggerOutgoingGInv = {
                order = counter(),
                name = "Trigger on outgoing whispers for Guild invites",
                descStyle = 'inline',
                width = "full",
                type = "toggle",
            },
            triggerOutgoingInv = {
                order = counter(),
                name = "Trigger on outgoing whispers for Group invites",
                descStyle = 'inline',
                width = "full",
                type = "toggle",
            },
        }
    }
end