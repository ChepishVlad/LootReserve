# LootReserves

**LootReserves** is a World of Warcraft addon for managing loot reservations during raids. It allows players to reserve items via whisper commands and provides the raid leader with tools to view, announce, and manage reserved items.

---

## Features

- **Whisper Commands**: Players can reserve, cancel, and check reserved items via in-game whispers.
- **Customizable Limit**: Set a limit on the maximum number of items each player can reserve.
- **GUI Integration**: View reserved items, players, and settings through an intuitive interface.
- **Announcement Tools**: Announce loot rules and reserved items directly to the raid.
- **Command Shortcuts**: Handy slash commands for quick access to key features.

---

## Commands

### Player Commands
- `!addreserve [item link]`: Reserve an item.
- `!cancelreserve [item link]`: Cancel a reservation.
- `!showreserve me`: Display all items reserved by you.
- `!checkreserve [item link]`: Check if an item is reserved and by how many players.

### Raid Leader Commands
- `/rdrop`: Clear all reservations.
- `/rshow`: Show the main addon frame.
- `/rannounce`: Announce reserved items in raid chat.
- `/showmembers`: Print a list of all players with their reserved items.
- `/showreserves`: Print all reserved items and their reserving players.

---

## Installation

1. Download the addon and extract it into your World of Warcraft `Interface/Addons` folder.
2. Restart your game or reload your UI using `/reload`.

---

## User Interface

The addon includes a tab-based interface with three main sections:

1. **Items**:
    - View a dropdown of reserved items.
    - See a list of players who reserved the selected item.

2. **Members**:
    - View a dropdown of players who reserved items.
    - See a list of items reserved by the selected player.

3. **Settings**:
    - Configure the maximum number of items players can reserve.
    - Clear all reservations.
    - Announce loot rules to the raid.
    - Announce current reservations.

---

## How It Works

1. Players whisper commands to reserve items.
2. The addon tracks reservations and enforces limits.
3. The raid leader can view and manage all reservations through the interface or commands.

---


Enjoy efficient loot management with **LootReserves**! 🎉
