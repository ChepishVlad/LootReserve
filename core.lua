local addonName, addonTable = ...

local LootReserves = LibStub("AceAddon-3.0"):NewAddon("LootReserves", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local LootReservesGUI = LibStub("AceGUI-3.0")
local LootReservesDB = LibStub("AceDB-3.0")

local reserves = {}
local members = {}

function LootReserves:OnInitialize()
    self.db = LootReservesDB:New("LootReservesDB", {
        profile = {
            isReserveOpen = false,
            Reserves = {},
            Members = {}
        }
    }, true)
    reserves = self.db.profile.Reserves
    members = self.db.profile.Members
    self:CreateMainFrame()
    self:RegisterChatCommand("rdrop", "ClearAllReserves")
    self:RegisterChatCommand("rshow", "ShowFrame")
    self:RegisterChatCommand("rannounce", "AnnounceReserves")
    self:RegisterChatCommand("showmembers", "ShowMembersReservations")
    self:RegisterChatCommand("showreserves", "ShowReservedItems")
    self:RegisterEvent("CHAT_MSG_WHISPER")
end

----------------------------------
----------- Back part ------------
----------------------------------

function LootReserves:CHAT_MSG_WHISPER(event, message, sender)
    local command, itemLink = message:match("!(%w+)%s+(.+)")

    if command == "addreserve" then
        self:AddReserve(itemLink, sender)
    elseif command == "cancelreserve" then
        self:CancelReserve(itemLink, sender)
    elseif command == "showreserve" then
        self:ShowPlayerReserves(sender)
    elseif command == "checkreserve" then
        self:CheckReserve(itemLink, sender)
    end
end

function LootReserves:AddReserve(itemLink, sender)
    if not self.db.profile.isReserveOpen then
        SendChatMessage("Reservations are closed now.", "WHISPER", nil, sender)
        return
    end

    if not itemLink or not itemLink:match("|Hitem:(%d+)") then
        SendChatMessage("You need to use an item link. Example: !reserve [item link]", "WHISPER", nil, sender)
        return
    end

    local itemID = itemLink:match("|Hitem:(%d+)")
    local itemName = itemLink:match("%[(.-)%]")

    if members[sender] and self:GetTableSize(members[sender]) >= (self.db.profile.MaxReserves or 2) then
        SendChatMessage("You can't reserve more than " .. (self.db.profile.MaxReserves or 2) .. " items.", "WHISPER", nil, sender)
        return
    end

    if members[sender] and members[sender][itemName] then
        SendChatMessage("You have already reserved this item.", "WHISPER", nil, sender)
        return
    end

    members[sender] = members[sender] or {}
    members[sender][itemName] = itemLink

    reserves[itemID] = reserves[itemID] or {}
    if not self:tContains(reserves[itemID], sender) then
        table.insert(reserves[itemID], sender)
    end

    SendChatMessage("You have reserved: " .. itemLink, "WHISPER", nil, sender)
end

function LootReserves:CancelReserve(itemLink, sender)
    if not itemLink or not itemLink:match("|Hitem:(%d+)") then
        SendChatMessage("You need to use an item link. Example: !cancelreserve [item link]", "WHISPER", nil, sender)
        return
    end

    local itemID = itemLink:match("|Hitem:(%d+)")
    local itemName = itemLink:match("%[(.-)%]")

    if not members[sender] or not members[sender][itemName] then
        SendChatMessage("You haven't reserved this item yet.", "WHISPER", nil, sender)
        return
    end

    members[sender][itemName] = nil

    if reserves[itemID] then
        for i, player in ipairs(reserves[itemID]) do
            if player == sender then
                table.remove(reserves[itemID], i)
                break
            end
        end
    end

    SendChatMessage("Reserve was removed.", "WHISPER", nil, sender)
end


function LootReserves:ShowPlayerReserves(sender)
    if not members[sender] or next(members[sender]) == nil then
        SendChatMessage("You don't have any reserves.", "WHISPER", nil, sender)
        return
    end

    local reservedItemsList = ""
    for itemName, itemLink in pairs(members[sender]) do
        reservedItemsList = reservedItemsList .. itemLink .. ", "
    end
    reservedItemsList = reservedItemsList:sub(1, -3)
    SendChatMessage("Your reserved items: " .. reservedItemsList, "WHISPER", nil, sender)
end

function LootReserves:CheckReserve(itemLink, sender)
    if not itemLink or not itemLink:match("|Hitem:(%d+)") then
        SendChatMessage("You need to use an item link. Example: !checkreserve [item link]", "WHISPER", nil, sender)
        return
    end

    local itemID = itemLink:match("|Hitem:(%d+)")
    local reservedPlayers = reserves[itemID]

    if not reservedPlayers or #reservedPlayers == 0 then
        SendChatMessage("There is no reserves for this item " .. itemLink, "WHISPER", nil, sender)
    else
        SendChatMessage(#reservedPlayers .. " players have reserved this item " .. itemLink, "WHISPER", nil, sender)
    end
end


function LootReserves:ShowReservedItems()
    for itemID, players in pairs(reserves) do
        print("Item ID " .. itemID .. " reserved by: " .. table.concat(players, ", "))
    end
end

function LootReserves:ShowMembersReservations()
    for player, items in pairs(members) do
        local reservedItemsList = {}
        for _, itemLink in pairs(items) do
            table.insert(reservedItemsList, itemLink)
        end
        print(player .. " has reserved: " .. table.concat(reservedItemsList, ", "))
    end
end

function LootReserves:tContains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function LootReserves:GetTableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function LootReserves:AnnounceReserves()
    if not LootReserves:IsInRaid() then
        print("You must be in a raid group to announce reserves.")
        return
    end

    if not next(reserves) then
        SendChatMessage("No items have been reserved.", "RAID_WARNING")
        return
    end

    SendChatMessage("Reserved items:", "RAID_WARNING")

    for itemID, players in pairs(reserves) do
        local itemLink = select(2, GetItemInfo(itemID)) -- Получаем ссылку на предмет
        local count = #players

        if count > 0 then
            if count <= 3 then
                local playerList = table.concat(players, ", ")
                if itemLink then
                    SendChatMessage(string.format("%s: Reserved by %s", itemLink, playerList), "RAID_WARNING")
                else
                    SendChatMessage(string.format("Item ID %d: Reserved by %s", itemID, playerList), "RAID_WARNING")
                end
            else
                if itemLink then
                    SendChatMessage(string.format("%s: %d players", itemLink, count), "RAID_WARNING")
                else
                    SendChatMessage(string.format("Item ID %d: %d players", itemID, count), "RAID_WARNING")
                end
            end
        end
    end
end

function LootReserves:IsInRaid()
    return GetNumRaidMembers() > 0
end

function LootReserves:OpenReserves()
    self.db.profile.isReserveOpen = true
    SendChatMessage("Reservations are opened", "RAID_WARNING")
    local maxReserves = self.db.profile.MaxReserves or 2
    SendChatMessage("You can reserve " .. maxReserves .. " items for this raid.", "RAID_WARNING")
    print("LootReserves: Reservations are now open!")
end

function LootReserves:CloseReserves()
    self.db.profile.isReserveOpen = false
    SendChatMessage("Reservations are now closed.", "RAID_WARNING")
    print("LootReserves: Reservations are now closed!")
end

----------------------------------
----------- Front part -----------
----------------------------------

function LootReserves:CreateMainFrame()
    local frame = LootReservesGUI:Create("Frame")
    frame:SetTitle(addonName)
    frame:SetStatusText("")
    frame:SetLayout("Fill")
    frame:SetWidth(300)
    frame:SetHeight(400)
    frame:Hide()
    self.frame = frame

    frame.frame:SetResizable(false)

    local tabGroup = LootReservesGUI:Create("TabGroup")
    tabGroup:SetLayout("Flow")
    tabGroup:SetTabs({
        {text = "Items", value = "items"},
        {text = "Members", value = "members"},
        {text = "Settings", value = "settings"}
    })

    tabGroup:SetCallback("OnGroupSelected", function(container, _, tab)
        container:ReleaseChildren()
        if tab == "items" then
            self:CreateItemsTab(container)
        elseif tab == "members" then
            self:CreateMembersTab(container)
        elseif tab == "settings" then
            self:CreateSettingsTab(container)
        end
    end)
    tabGroup:SelectTab("items")
    frame:AddChild(tabGroup)
end

function LootReserves:CreateItemsTab(container)
    local itemsDropdown = LootReservesGUI:Create("Dropdown")
    itemsDropdown:SetLabel("Select Item:")
    itemsDropdown:SetFullWidth(true)
    itemsDropdown:SetList(self:GetReservedItemsList())
    itemsDropdown:SetCallback("OnValueChanged", function(_, _, itemID)
        self:DisplayReservesInfo(itemID)
    end)
    container:AddChild(itemsDropdown)
    self.itemsDropdown = itemsDropdown

    local reservesInfoGroup = LootReservesGUI:Create("InlineGroup")
    reservesInfoGroup:SetFullWidth(true)
    reservesInfoGroup:SetHeight(300)
    container:AddChild(reservesInfoGroup)
    self.reservesInfoGroup = reservesInfoGroup
end

function LootReserves:CreateMembersTab(container)
    local membersDropdown = LootReservesGUI:Create("Dropdown")
    membersDropdown:SetLabel("Select Member:")
    membersDropdown:SetFullWidth(true)
    membersDropdown:SetList(self:GetReservedPlayersList())
    membersDropdown:SetCallback("OnValueChanged", function(_, _, playerName)
        self:DisplayItemsInfo(playerName)
    end)
    container:AddChild(membersDropdown)
    self.membersDropdown = membersDropdown

    local itemsInfoGroup = LootReservesGUI:Create("InlineGroup")
    itemsInfoGroup:SetFullWidth(true)
    itemsInfoGroup:SetHeight(300)
    container:AddChild(itemsInfoGroup)
    self.itemsInfoGroup = itemsInfoGroup
end

function LootReserves:CreateSettingsTab(container)
    local dropdown = LootReservesGUI:Create("Dropdown")
    dropdown:SetLabel("Max reserves per player:")
    dropdown:SetFullWidth(true)
    dropdown:SetList({1, 2, 3})
    dropdown:SetValue(self.db.profile.MaxReserves or 2)
    dropdown:SetCallback("OnValueChanged", function(_, _, value)
        self.db.profile.MaxReserves = value
    end)
    container:AddChild(dropdown)

    local removeButton = LootReservesGUI:Create("Button")
    removeButton:SetText("Remove Reserves")
    removeButton:SetFullWidth(true)
    removeButton:SetCallback("OnClick", function()
        LootReserves:ClearAllReserves()
    end)
    container:AddChild(removeButton)

    local announceRulesButton = LootReservesGUI:Create("Button")
    announceRulesButton:SetText("Announce Rules")
    announceRulesButton:SetFullWidth(true)
    announceRulesButton:SetCallback("OnClick", function()
        local maxReserves = self.db.profile.MaxReserves or 2
        SendChatMessage("You can reserve " .. maxReserves .. " items for this raid.", "RAID_WARNING")
    end)
    container:AddChild(announceRulesButton)

    local announceReservesButton = LootReservesGUI:Create("Button")
    announceReservesButton:SetText("Announce Reserves")
    announceReservesButton:SetFullWidth(true)
    announceReservesButton:SetCallback("OnClick", function()
        LootReserves:AnnounceReserves()
    end)
    container:AddChild(announceReservesButton)

    local openButton = LootReservesGUI:Create("Button")
    openButton:SetText("Open Reserves")
    openButton:SetFullWidth(true)
    openButton:SetCallback("OnClick", function()
        self:OpenReserves()
    end)
    container:AddChild(openButton)

    local closeButton = LootReservesGUI:Create("Button")
    closeButton:SetText("Close Reserves")
    closeButton:SetFullWidth(true)
    closeButton:SetCallback("OnClick", function()
        self:CloseReserves()
    end)
    container:AddChild(closeButton)

end

function LootReserves:DisplayReservesInfo(itemID)
    self.reservesInfoGroup:ReleaseChildren()
    local players = reserves[itemID] or {}

    local scrollContainer = LootReservesGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetHeight(150)
    scrollContainer:SetLayout("Fill")
    self.reservesInfoGroup:AddChild(scrollContainer)

    local scrollFrame = LootReservesGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetHeight(120)
    scrollContainer:AddChild(scrollFrame)

    local headerGroup = LootReservesGUI:Create("SimpleGroup")
    headerGroup:SetLayout("Flow")
    headerGroup:SetFullWidth(true)
    scrollFrame:AddChild(headerGroup)

    local indexHeader = LootReservesGUI:Create("Label")
    indexHeader:SetText("№")
    indexHeader:SetWidth(30)
    headerGroup:AddChild(indexHeader)

    local nameHeader = LootReservesGUI:Create("Label")
    nameHeader:SetText("Name")
    nameHeader:SetWidth(150)
    headerGroup:AddChild(nameHeader)

    for i, name in ipairs(players) do
        local rowGroup = LootReservesGUI:Create("SimpleGroup")
        rowGroup:SetLayout("Flow")
        rowGroup:SetFullWidth(true)
        scrollFrame:AddChild(rowGroup)

        local indexLabel = LootReservesGUI:Create("Label")
        indexLabel:SetText(tostring(i))
        indexLabel:SetWidth(30)
        rowGroup:AddChild(indexLabel)

        local nameLabel = LootReservesGUI:Create("Label")
        nameLabel:SetText(name)
        nameLabel:SetWidth(150)
        rowGroup:AddChild(nameLabel)
    end
end

function LootReserves:DisplayItemsInfo(playerName)
    self.itemsInfoGroup:ReleaseChildren()
    local items = {}

    for itemID, players in pairs(reserves) do
        for _, player in ipairs(players) do
            if player == playerName then
                local itemName = select(1, GetItemInfo(itemID))
                table.insert(items, itemName or ("Item ID " .. itemID))
            end
        end
    end

    local scrollContainer = LootReservesGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetHeight(150)
    scrollContainer:SetLayout("Fill")
    self.itemsInfoGroup:AddChild(scrollContainer)

    local scrollFrame = LootReservesGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetHeight(120)
    scrollContainer:AddChild(scrollFrame)

    local headerGroup = LootReservesGUI:Create("SimpleGroup")
    headerGroup:SetLayout("Flow")
    headerGroup:SetFullWidth(true)
    scrollFrame:AddChild(headerGroup)

    local indexHeader = LootReservesGUI:Create("Label")
    indexHeader:SetText("№")
    indexHeader:SetWidth(30)
    headerGroup:AddChild(indexHeader)

    local itemHeader = LootReservesGUI:Create("Label")
    itemHeader:SetText("Item")
    itemHeader:SetWidth(150)
    headerGroup:AddChild(itemHeader)

    for i, itemName in ipairs(items) do
        local rowGroup = LootReservesGUI:Create("SimpleGroup")
        rowGroup:SetLayout("Flow")
        rowGroup:SetFullWidth(true)
        scrollFrame:AddChild(rowGroup)

        local indexLabel = LootReservesGUI:Create("Label")
        indexLabel:SetText(tostring(i))
        indexLabel:SetWidth(30)
        rowGroup:AddChild(indexLabel)

        local itemLabel = LootReservesGUI:Create("Label")
        itemLabel:SetText(itemName)
        itemLabel:SetWidth(150)
        rowGroup:AddChild(itemLabel)
    end
end

function LootReserves:GetReservedItemsList()
    local itemList = {}
    for itemID, players in pairs(reserves) do
        local itemName = select(1, GetItemInfo(itemID))
        itemList[itemID] = itemName or ("Item ID " .. itemID)
    end
    return itemList
end

function LootReserves:GetReservedPlayersList()
    local playerList = {}
    for _, players in pairs(reserves) do
        for _, player in ipairs(players) do
            playerList[player] = player
        end
    end
    return playerList
end

function LootReserves:ShowFrame()
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function LootReserves:ClearAllReserves()
    wipe(reserves)
    wipe(members)

    if self.frame and self.frame:IsShown() then
        self.itemsDropdown:SetList(self:GetReservedItemsList())
        self.membersDropdown:SetList(self:GetReservedPlayersList())
        self.reservesInfoGroup:ReleaseChildren()
        self.itemsInfoGroup:ReleaseChildren()
    end

    print("Все резервы были очищены.")
end


LootReserves:OnInitialize()