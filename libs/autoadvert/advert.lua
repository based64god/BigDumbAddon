local _G = getfenv(0)
local LibStub = _G.LibStub

local addonName = "autoguild"

local AG = LibStub('AceAddon-3.0'):NewAddon(addonName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0');
if not AG then return end

function AG:TimedRecruitmentMessage(message)

end