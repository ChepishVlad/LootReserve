# LootReserves

**LootReserves** is a World of Warcraft addon for managing loot reservations during raids. It allows players to reserve items via whisper commands and provides the raid leader with tools to view, announce, and manage reserved items.

---

## Features

- **Whisper Commands**: Players can reserve, cancel, and check reserved items via in-game whispers.
- **Customizable Reservation Limits**: Configure the maximum number of items a player can reserve (1, 2, or 3).
- **Reservation Clearing**: Clear all reservations with a single command or button.
- **GUI Integration**: Manage reservations, players, and settings via an intuitive tab-based interface.
- **Announcements**:
   - Share loot rules directly with the raid.
   - Announce reserved items or loot lists to the raid group.
- **Real-Time Updates**: View and edit reservations dynamically during a raid.
- **Slash Commands**: Convenient commands for managing reservations and the addon interface.

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
    - Ability to close or open reservations

---

## How It Works

1. Players whisper commands to reserve items.
2. The addon tracks reservations and enforces limits.
3. The raid leader can view and manage all reservations through the interface or commands.

---


Enjoy efficient loot management with **LootReserves**! 🎉
