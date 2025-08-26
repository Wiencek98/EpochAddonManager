# Epoch Addon Manager

A Wrath of the Lich King (3.3.5 / Project Epoch) AddOn that adds an **AddOns** button to the ESC Game Menu and lets you enable/disable addons in-game. It only shows **Reload UI** after you change something, and it remembers window position **per character**.

## Features
- Adds **AddOns** button to the ESC menu.
- Lists all installed addons with checkboxes.
- Enable/Disable per character; prompts Reload UI only when needed.
- Slash command: `/eam`
- Draggable window; remembers position (per character).
- UI styled like Blizzard’s dialog/ESC menu (with fallback if `SetBackdrop` is unavailable).

## Compatibility
- Target: **Wrath of the Lich King 3.3.5a** clients (e.g., Project Epoch).
- Not intended for modern Retail clients.

## Installation
1. Download the latest **Release** ZIP from the Releases page (or click **Code → Download ZIP**).
2. Extract the ZIP.
3. Move the **`EpochAddonManager`** folder into your WoW AddOns directory:
4. Restart WoW.
5. Open with **ESC → AddOns** or type **`/eam`** in chat.

## Usage
- Check/uncheck addons to enable/disable them for your current character.
- The **Reload UI** button appears only after you make changes.
- Drag the window by holding **Left Click** on any empty area; position is saved per character.

## Troubleshooting
- **Addon doesn’t appear in the AddOns list at character select**  
Make sure the folder name matches the `.toc` file name (`EpochAddonManager`) and the TOC has `## Interface: 30300`.
- **No window appears**  
Type `/console scriptErrors 1`, `/reload`, then try `/eam` again and note any error messages.
- **ESC button doesn’t show**  
Open **ESC**, then **Options** once, close it, and open **ESC** again (forces Blizzard to layout the menu).  
Also try `/eam` to open the manager directly.

## Building / Developing
- The addon is a single-file Lua + TOC. No build step required.
- For debugging, toggle prints inside the code via the `DEBUG` flag.

## Security
- No external code execution and no bundled binaries.
- Uses only Blizzard UI APIs and textures.
- See [`SECURITY.md`](SECURITY.md) for reporting procedures.

## License
This project is licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

## Credits
- Author: **Supplied**  
- Thanks to Project Epoch community for testing.

