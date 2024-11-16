# LootReserves Addon

## Description
LootReserves is a World of Warcraft addon designed to help raid leaders manage reserved items and player reservations efficiently. The addon allows reserving items, canceling reservations, announcing reserved items to the raid, and displaying who has reserved specific items.

---

## Commands

### **Admin Commands**
1. **`/rshow`**  
   Opens or closes the main LootReserves frame for managing reservations.

2. **`/rdrop`**  
   Clears all current reserves and resets the addon.  
   **Output:** `All reserves have been cleared.`
   
3. **`/rannounce`**  
   Announces all reserved items to the raid.
   - If an item is reserved by **3 or fewer players**, their names are listed.\
     **Output Example:**
     `[Shadowmourne]: Reserved by Player1, Player2, Player3`
   - If reserved by **more than 3 players**, only the total number of players is displayed.  
     **Output Example:**
     `[Invincible's Reins]: 5 players`

---

### **Player Commands (Whisper to Raid Leader)**
1. **`!addreserve [item link]`**  
   Reserves an item for the player.
   - Each player can reserve up to **2 items**.
   - Requires an item link in the message.  
     **Response:** `You have reserved: [Item Name]`

2. **`!cancelreserve [item link]`**  
   Cancels the reservation for the specified item.
   - Requires an item link in the message.  
     **Response:**  Reserve was removed.`

3. **`!showreserve me`**  
   Displays all items the player has reserved.  
   **Response:**  `Your reserved items: [Item 1], [Item 2]`
4. **`!checkreserve [item link]`**  
      Checks how many players have reserved the specified item.
   - If no one has reserved it:\
     **Response:** `There is no reserve for this item [Item Name]`
   - If players have reserved it:\
     **Response:** `[Number] players have reserved this item [Item Name]`

---
## Features
- Manage item reservations directly via commands or GUI.
- View reserved items and players' reservations in a simple tabbed interface.
- Whisper-based commands for players to reserve or cancel items.
- Automatic raid announcements for reserved items with detailed or summarized information.

---

## Notes
- Make sure to use proper item links (`[Item Name]`) in chat commands where required.
- This addon is designed for raid groups and will notify you if you're not in a raid when attempting to announce reserves.  
  **Message:** `You must be in a raid group to announce reserves.`