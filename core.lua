local addonName, addonTable = ...

local LootReserves = LibStub("AceAddon-3.0"):NewAddon("LootReserves", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local LootReservesGUI = LibStub("AceGUI-3.0")
local LootReservesDB = LibStub("AceDB-3.0")

local reservedItems = {}
local reserves = {}

function LootReserves:OnInitialize()
    self.db = LootReservesDB:New("RaidMailDB", {
        profile = {
            Reserves = {}
        }
    }, true)
    reserves = self.db.profile.Reserves
    self:CreateMainFrame()
    self:RegisterChatCommand("rshow", "ShowFrame")
    self:RegisterEvent("CHAT_MSG_WHISPER")
end

function LootReserves:CHAT_MSG_WHISPER(event, message, sender)
    local command, itemName = message:match("!(%w+)%s+(.+)")

    if command == "reserve" and itemName then
        if not reservedItems[itemName] then
            reservedItems[itemName] = {}
        end
        table.insert(reservedItems[itemName], sender)
        SendChatMessage("You have reserved: " .. itemName, "WHISPER", nil, sender)
    end
end

-- Example command to print the reserved items list
function LootReserves:ShowReservedItems()
    for item, players in pairs(reservedItems) do
        print(item .. " reserved by: " .. table.concat(players, ", "))
    end
end


function LootReserves:CreateMainFrame()
    local frame = LootReservesGUI:Create("Frame")
    frame:SetTitle(addonName)
    frame:SetStatusText("")
    frame:SetLayout("Fill")
    frame:SetWidth(500)
    frame:SetHeight(580)
    frame:Hide()
    self.frame = frame

    -- TODO сейчас тут вызывается исключение - не нашёл способа сделать без него
    frame.frame:SetResizable(false)
end


-- Main window visibility
function LootReserves:ShowFrame()
    self.frame:Show()
end

LootReserves:OnInitialize()