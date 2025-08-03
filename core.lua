local addonName, addonTable = ...

local LootReserves = LibStub("AceAddon-3.0"):NewAddon("LootReserves", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local LootReservesGUI = LibStub("AceGUI-3.0")
local LootReservesDB = LibStub("AceDB-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local reserves = {}
local members = {}
local councilLoot = {}
--local guildRankReserves = {}

local LootReservesLDB = LDB:NewDataObject("LootReserves", {
    type = "launcher",
    text = "Loot Reserves",
    icon = "Interface\\AddOns\\LootReserve\\ico.tga",
    OnClick = function(_, button)
        if button == "LeftButton" then
            LootReserves:ToggleMainFrame()
        elseif button == "RightButton" then
            LootReserves:OpenSettings()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Loot Reserves")
        tooltip:AddLine("Left-click: Open main frame", 1, 1, 1)
        tooltip:AddLine("Right-click: Open settings", 1, 1, 1)
    end,
})

function LootReserves:OnInitialize()
    self.db = LootReservesDB:New("LootReservesDB", {
        profile = {
            isReserveOpen = false,
            Reserves = {},
            Members = {},
            CouncilLoot = {},
            guildRankReserves = {},
            minimap = { hide = false },
            MaxReserves = 0,
        }
    }, true)
    reserves = self.db.profile.Reserves
    members = self.db.profile.Members
    councilLoot = self.db.profile.CouncilLoot
    --guildRankReserves = self.db.profile.guildRankReserves

    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        local _, itemLink = tooltip:GetItem()
        if not itemLink then return end

        local itemID = itemLink:match("|Hitem:(%d+)")
        if not itemID then return end

        if councilLoot[itemID] then
            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFF0000Reserved for council loot|r")
        end

        local reservedPlayers = reserves[itemID]
        if reservedPlayers and #reservedPlayers > 0 then
            tooltip:AddLine(" ") -- Пустая строка для разделения
            tooltip:AddLine("|cFF00FF00Reserved by:|r")
            for _, player in ipairs(reservedPlayers) do
                tooltip:AddLine("  - " .. player)
            end
        end
    end)

    if not LDBIcon:IsRegistered("LootReserves") then
        LDBIcon:Register("LootReserves", LootReservesLDB, self.db.profile.minimap)
    end
    LDBIcon:Refresh("LootReserves", self.db.profile.minimap)

    self:CreateMainFrame()
    self:RegisterChatCommand("rdrop", "ClearAllReserves")
    self:RegisterChatCommand("rshow", "ShowFrame")
    self:RegisterChatCommand("rannounce", "AnnounceReserves")
    self:RegisterChatCommand("showmembers", "ShowMembersReservations")
    self:RegisterChatCommand("showreserves", "ShowReservedItems")
    self:RegisterChatCommand("addcouncil", "AddCouncil")
    self:RegisterChatCommand("showcouncil", "ShowCouncil")
    self:RegisterChatCommand("clearcouncil", "ClearCouncil")
    self:RegisterChatCommand("removecouncil", "RemoveCouncil")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_RAID_WARNING")
end

function LootReserves:ToggleMainFrame()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function LootReserves:OpenSettings()
    print("Settings menu would open here (to be implemented).")
end

----------------------------------
----------- Back part ------------
----------------------------------

function LootReserves:CHAT_MSG_RAID_WARNING(event, message, sender)
    -- Проверяем права отправителя (лидер/офицер)
    local isLeaderOrOfficer = false
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if name == sender and (rank == 2 or rank == 1) then  -- 2 = офицер, 1 = лидер
                isLeaderOrOfficer = true
                break
            end
        end
    end
    if not isLeaderOrOfficer then return end

    -- Ищем ссылку на предмет в сообщении
    local itemLink = message:match("(|Hitem:%d+:.-|h.-|h)")
    if not itemLink then return end

    -- Проверяем резервы
    local itemID = itemLink:match("|Hitem:(%d+)")
    local reservedPlayers = itemID and reserves[itemID] or nil
    if not reservedPlayers or #reservedPlayers == 0 then return end

    -- Отправляем ТОЛЬКО список игроков через запятую
    SendChatMessage(table.concat(reservedPlayers, ", "), "RAID_WARNING")
end


function LootReserves:CHAT_MSG_WHISPER(event, message, sender)
    -- Получаем информацию о гильдии и звании
    local guildName, guildRankName = self:GetPlayerGuildInfo(sender)
    local playerInfo = string.format("|cff00ff00%s|r", sender)

    if guildName then
        playerInfo = playerInfo..string.format(" from |cff00ccff%s|r", guildName)
        if guildRankName then
            playerInfo = playerInfo..string.format(" (|cffffcc00%s|r)", guildRankName)
        end
    end

    -- Выводим информацию об отправителе
    --print(string.format("Message from %s: %s", playerInfo, message))


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

function LootReserves:GetPlayerGuildInfo(playerName)
    local guildName, guildRankName, guildRankIndex
    -- Проверяем игроков в рейде
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank, _, _, _, _, _, _, _, _, _, guild = GetRaidRosterInfo(i)
            if name == playerName then
                guildName = guild
                guildRankName = rank == 0 and "Leader" or rank == 1 and "Officer" or "Member"
                guildRankIndex = rank
                break
            end
        end
    end

    -- Если не нашли в рейде, проверяем гильдию (если игрок в нашей гильдии)
    if not guildName and IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local name, _, rankIndex, _, _, _, _, _, _, _, _, _, _, _, _, guild = GetGuildRosterInfo(i)
            if name == playerName then
                guildName = guild or GetGuildInfo("player")
                guildRankName = GuildControlGetRankName(rankIndex + 1)
                guildRankIndex = rankIndex
                break
            end
        end
    end

    return guildName, guildRankName, guildRankIndex
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

    if councilLoot[itemID] then
        SendChatMessage("This item is reserved for council loot and cannot be reserved.", "WHISPER", nil, sender)
        return
    end

    local maxReserves = self:GetPlayerMaxReserves(sender)

    if maxReserves == 0 then
        SendChatMessage("Sorry you can't reserve items", "WHISPER", nil, sender)
        return
    end

    if members[sender] and self:GetTableSize(members[sender]) >= maxReserves then
        SendChatMessage(string.format("You can't reserve more than %d items.", maxReserves), "WHISPER", nil, sender)
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

    --SendChatMessage("You have reserved: " .. itemLink, "WHISPER", nil, sender)
    SendChatMessage(string.format("You have reserved: %s (%d/%d)", itemLink, self:GetTableSize(members[sender]), maxReserves), "WHISPER", nil, sender)
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

function LootReserves:GetPlayerMaxReserves(playerName)
    if not IsInGuild() then
        return self.db.profile.MaxReserves or 0
    end

    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local name, _, rankIndex = GetGuildRosterInfo(i)
            if name == playerName then
                local rankLimit = self.db.profile.guildRankReserves[rankIndex + 1] -- rankIndex начинается с 0
                return rankLimit or (self.db.profile.MaxReserves or 2)
            end
        end
    end

    return self.db.profile.MaxReserves or 0
end


function LootReserves:ShowPlayerReserves(sender)
    --if not members[sender] or next(members[sender]) == nil then
    --    SendChatMessage("You don't have any reserves.", "WHISPER", nil, sender)
    --    return
    --end
    local maxReserves = self:GetPlayerMaxReserves(sender)
    local currentReserves = members[sender] and self:GetTableSize(members[sender]) or 0

    if maxReserves == 0 then
        SendChatMessage("Sorry you can't reserve items", "WHISPER", nil, sender)
        return
    end

    if currentReserves == 0 then
        SendChatMessage(string.format("You don't have any reserves (%d/%d available).", maxReserves - currentReserves, maxReserves), "WHISPER", nil, sender)
        return
    end

    local reservedItemsList = ""
    for itemName, itemLink in pairs(members[sender]) do
        reservedItemsList = reservedItemsList .. itemLink .. ", "
    end
    reservedItemsList = reservedItemsList:sub(1, -3)

    SendChatMessage(string.format("Your reserved items (%d/%d): %s", currentReserves, maxReserves, reservedItemsList), "WHISPER", nil, sender)
end

function LootReserves:CheckReserve(itemLink, sender)
    if not itemLink or not itemLink:match("|Hitem:(%d+)") then
        SendChatMessage("You need to use an item link. Example: !checkreserve [item link]", "WHISPER", nil, sender)
        return
    end

    local itemID = itemLink:match("|Hitem:(%d+)")
    local reservedPlayers = reserves[itemID]
    local maxReserves = self:GetPlayerMaxReserves(sender)

    if not reservedPlayers or #reservedPlayers == 0 then
        SendChatMessage(string.format("There is no reserves for this item %s (your limit: %d)", itemLink, maxReserves), "WHISPER", nil, sender)
    else
        SendChatMessage(string.format("%d players have reserved this item %s (your limit: %d)", #reservedPlayers, itemLink, maxReserves), "WHISPER", nil, sender)
    end
end


function LootReserves:ShowReservedItems()
    for itemID, players in pairs(reserves) do
        print("Item ID " .. itemID .. " reserved by: " .. table.concat(players, ", "))
    end
end

function LootReserves:AddCouncil(msg)
    local itemLink = msg:match("|c%x+|Hitem:.-|h.-|h|r") or msg:match("|Hitem:.-|h.-|h") or msg:match("%[.-%]")
    local itemID = itemLink:match("|Hitem:(%d+)")

    -- Добавляем в список council loot
    councilLoot[itemID] = itemLink
    self.db.profile.CouncilLoot = councilLoot
    print("Added to council loot: " .. (select(2, GetItemInfo(itemID)) or itemLink))
end


function LootReserves:RemoveCouncil(msg)
    local itemLink = msg:match("|c%x+|Hitem:.-|h.-|h|r") or msg:match("|Hitem:.-|h.-|h") or msg:match("%[.-%]")
    local itemID = itemLink:match("|Hitem:(%d+)")

    if councilLoot[itemID] then
        local removedItem = councilLoot[itemID]
        councilLoot[itemID] = nil
        self.db.profile.CouncilLoot = councilLoot

        print("Removed from council loot: " .. removedItem)
    else
        print("Item not found in council loot.")
    end
end


function LootReserves:ShowCouncil()
    if not next(councilLoot) then
        print("Council loot list is empty.")
        return
    end

    print("Council loot items:")
    for itemID, itemLink in pairs(councilLoot) do
        print("- " .. itemLink)
    end

    if IsInRaid() then
        SendChatMessage("=== Council Loot ===", "RAID_WARNING")
        for itemID, itemLink in pairs(councilLoot) do
            SendChatMessage(itemLink, "RAID_WARNING")
        end
    end
end

function LootReserves:ClearCouncil()
    wipe(councilLoot)
    self.db.profile.CouncilLoot = councilLoot
    print("Council loot list has been cleared.")
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

    ---- Объявляем лимиты
    --SendChatMessage("=== Reserve Limits ===", "RAID_WARNING")
    --SendChatMessage(string.format("Default limit: %d items", self.db.profile.MaxReserves or 2), "RAID_WARNING")
    --
    --if IsInGuild() then
    --    for i = 1, math.min(10, GuildControlGetNumRanks()) do -- Ограничиваем показ 10 рангами
    --        local rankName = GuildControlGetRankName(i)
    --        local limit = self.db.profile.guildRankReserves[i] or self.db.profile.MaxReserves or 2
    --        SendChatMessage(string.format("%s: %d items", rankName, limit), "RAID_WARNING")
    --    end
    --end

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
    frame:SetWidth(400)
    frame:SetHeight(500)
    frame:Hide()
    self.frame = frame

    frame.frame:SetResizable(false)

    local tabGroup = LootReservesGUI:Create("TabGroup")
    tabGroup:SetLayout("Flow")
    tabGroup:SetTabs({
        {text = "Items", value = "items"},
        {text = "Members", value = "members"},
        {text = "Settings", value = "settings"},
        {text = "Guild", value = "guild"}
    })

    tabGroup:SetCallback("OnGroupSelected", function(container, _, tab)
        container:ReleaseChildren()
        if tab == "items" then
            self:CreateItemsTab(container)
        elseif tab == "members" then
            self:CreateMembersTab(container)
        elseif tab == "guild" then
            self:CreateGuildTab(container)
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
    dropdown:SetList({
        [0] = "0 (no reserves)",
        [1] = "1 reserve",
        [2] = "2 reserves",
        [3] = "3 reserves"
    })
    dropdown:SetValue(self.db.profile.MaxReserves or 0)
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

    local announceCouncilButton = LootReservesGUI:Create("Button")
    announceCouncilButton:SetText("Announce Council")
    announceCouncilButton:SetFullWidth(true)
    announceCouncilButton:SetCallback("OnClick", function()
        LootReserves:ShowCouncil()
    end)
    container:AddChild(announceCouncilButton)

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

--function LootReserves:CreateGuildTab(container)
--    local scrollContainer = LootReservesGUI:Create("SimpleGroup")
--    scrollContainer:SetLayout("Fill")
--    scrollContainer:SetFullWidth(true)
--    scrollContainer:SetFullHeight(true)
--    container:AddChild(scrollContainer)
--
--    local scroll = LootReservesGUI:Create("ScrollFrame")
--    scroll:SetLayout("List")
--    scrollContainer:AddChild(scroll)
--
--    if not IsInGuild() then
--        local noGuildLabel = LootReservesGUI:Create("Label")
--        noGuildLabel:SetText("You aren't in a guild")
--        noGuildLabel:SetFontObject(GameFontNormalLarge)
--        noGuildLabel:SetColor(1, 0.2, 0.2) -- Красный цвет
--        noGuildLabel:SetFullWidth(true)
--        scroll:AddChild(noGuildLabel)
--        return
--    end
--
--    local guildName = GetGuildInfo("player")
--    local guildHeader = LootReservesGUI:Create("Label")
--    guildHeader:SetText("Guild: "..guildName)
--    guildHeader:SetFontObject(GameFontNormalLarge)
--    guildHeader:SetColor(0, 1, 1) -- Голубой цвет
--    guildHeader:SetFullWidth(true)
--    scroll:AddChild(guildHeader)
--
--    local ranksHeader = LootReservesGUI:Create("Label")
--    ranksHeader:SetText("Guild Ranks:")
--    ranksHeader:SetFontObject(GameFontNormal)
--    ranksHeader:SetColor(1, 1, 0) -- Желтый цвет
--    ranksHeader:SetFullWidth(true)
--    scroll:AddChild(ranksHeader)
--
--    -- Получаем количество званий в гильдии
--    local numRanks = GuildControlGetNumRanks()
--
--    for i = 1, numRanks do
--        local rankName = GuildControlGetRankName(i)
--        local rankFrame = LootReservesGUI:Create("SimpleGroup")
--        rankFrame:SetLayout("Flow")
--        rankFrame:SetFullWidth(true)
--
--        local rankIndexLabel = LootReservesGUI:Create("Label")
--        rankIndexLabel:SetText(i..".")
--        rankIndexLabel:SetWidth(30)
--        rankFrame:AddChild(rankIndexLabel)
--
--        local rankNameLabel = LootReservesGUI:Create("Label")
--        rankNameLabel:SetText(rankName)
--        rankNameLabel:SetWidth(200)
--
--        -- Цвета для разных рангов
--        if i == 1 then
--            rankNameLabel:SetColor(1, 0.5, 0) -- Оранжевый для лидера
--        elseif i <= 3 then
--            rankNameLabel:SetColor(1, 1, 0.5) -- Светло-желтый для офицеров
--        else
--            rankNameLabel:SetColor(1, 1, 1) -- Белый для рядовых членов
--        end
--
--        rankFrame:AddChild(rankNameLabel)
--        scroll:AddChild(rankFrame)
--    end
--
--    -- Добавляем информацию о количестве членов гильдии
--    local numMembers = GetNumGuildMembers()
--    local membersLabel = LootReservesGUI:Create("Label")
--    membersLabel:SetText(string.format("Total members: %d", numMembers))
--    membersLabel:SetFontObject(GameFontNormal)
--    membersLabel:SetColor(0.5, 1, 0.5) -- Зеленый цвет
--    membersLabel:SetFullWidth(true)
--    scroll:AddChild(membersLabel)
--end

function LootReserves:CreateGuildTab(container)
    local scrollContainer = LootReservesGUI:Create("SimpleGroup")
    scrollContainer:SetLayout("Fill")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    container:AddChild(scrollContainer)

    local scroll = LootReservesGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scrollContainer:AddChild(scroll)

    if not IsInGuild() then
        local noGuildLabel = LootReservesGUI:Create("Label")
        noGuildLabel:SetText("You aren't in a guild")
        noGuildLabel:SetFontObject(GameFontNormalLarge)
        noGuildLabel:SetColor(1, 0.2, 0.2)
        noGuildLabel:SetFullWidth(true)
        scroll:AddChild(noGuildLabel)
        return
    end

    local guildName = GetGuildInfo("player")
    local guildHeader = LootReservesGUI:Create("Label")
    guildHeader:SetText("Guild: "..guildName)
    guildHeader:SetFontObject(GameFontNormalLarge)
    guildHeader:SetColor(0, 1, 1)
    guildHeader:SetFullWidth(true)
    scroll:AddChild(guildHeader)

    local ranksHeader = LootReservesGUI:Create("Label")
    ranksHeader:SetText("Guild Ranks and Reserve Limits:")
    ranksHeader:SetFontObject(GameFontNormal)
    ranksHeader:SetColor(1, 1, 0)
    ranksHeader:SetFullWidth(true)
    scroll:AddChild(ranksHeader)

    self.guildRankDropdowns = {}

    local numRanks = GuildControlGetNumRanks()

    for i = 1, numRanks do
        local rankName = GuildControlGetRankName(i)
        local rankFrame = LootReservesGUI:Create("SimpleGroup")
        rankFrame:SetLayout("Flow")
        rankFrame:SetFullWidth(true)

        local rankIndexLabel = LootReservesGUI:Create("Label")
        rankIndexLabel:SetText(i..".")
        rankIndexLabel:SetWidth(30)
        rankFrame:AddChild(rankIndexLabel)

        local rankNameLabel = LootReservesGUI:Create("Label")
        rankNameLabel:SetText(rankName)
        rankNameLabel:SetWidth(150)

        if i == 1 then
            rankNameLabel:SetColor(1, 0.5, 0)
        elseif i <= 3 then
            rankNameLabel:SetColor(1, 1, 0.5)
        else
            rankNameLabel:SetColor(1, 1, 1)
        end

        rankFrame:AddChild(rankNameLabel)

        local dropdown = LootReservesGUI:Create("Dropdown")
        dropdown:SetList({
            [0] = "0 (no reserves)",
            [1] = "1 reserve",
            [2] = "2 reserves",
            [3] = "3 reserves"
        })
        dropdown:SetValue(0)
        dropdown:SetWidth(150)
        dropdown:SetCallback("OnValueChanged", function(_, _, value)
            self.db.profile.guildRankReserves[i] = value
            print(string.format("Set %s (%d) reserve limit to %d", rankName, i, value))
        end)

        if self.db.profile.guildRankReserves[i] then
            dropdown:SetValue(self.db.profile.guildRankReserves[i])
        end

        rankFrame:AddChild(dropdown)
        self.guildRankDropdowns[i] = dropdown

        scroll:AddChild(rankFrame)
    end

    local numMembers = GetNumGuildMembers()
    local membersLabel = LootReservesGUI:Create("Label")
    membersLabel:SetText(string.format("Total members: %d", numMembers))
    membersLabel:SetFontObject(GameFontNormal)
    membersLabel:SetColor(0.5, 1, 0.5)
    membersLabel:SetFullWidth(true)
    scroll:AddChild(membersLabel)


    local saveButton = LootReservesGUI:Create("Button")
    saveButton:SetText("Save Reserve Limits")
    saveButton:SetFullWidth(true)
    saveButton:SetCallback("OnClick", function()
        print("Guild reserve limits saved!")
    end)
    scroll:AddChild(saveButton)
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

function LootReserves:ToggleMinimapIcon()
    local shouldHide = not self.db.profile.minimap.hide
    self.db.profile.minimap.hide = shouldHide
    if shouldHide then
        LDBIcon:Hide("LootReserves")
    else
        LDBIcon:Show("LootReserves")
    end
end

LootReserves:OnInitialize()