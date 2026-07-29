# UMU-Hero

A companion tool for [Heroic Games Launcher](https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher) on Linux that adds non-Steam games to Steam with full UMU/Proton prefix support.

![Main Menu](<images/umu-hero - main.png>)

## What is UMU-Hero?

UMU-Hero bridges the gap between Heroic Games Launcher and Steam. It takes games installed via Heroic (from **Epic Games Store**, **GOG**, and **Amazon Games**) and registers them as non-Steam games in your Steam library, with properly configured Wine/Proton prefixes and protonfixes.

## Features

- **Add Heroic games to Steam** -- Automatically detects installed games from Epic, GOG, and Amazon stores via Heroic's config files and adds them to Steam.
- **Windowization** -- Converts Linux game paths to Windows-style paths (`c:\games\...`) so that Windows-native CLI launchers (legendary, gogdl, nile) work inside Proton.
- **UMU prefix creation** -- Searches the [UMU database](https://umu.openwinecomponents.org) for game-specific protonfixes and creates configured Wine prefixes with those fixes applied.
- **Ubisoft Connect support** -- Detects Ubisoft games installed in existing Wine/Proton prefixes and adds them to Steam.
- **Add any executable** -- Pick any `.exe` file and add it to Steam as a non-Steam game.
- **SteamGridDB artwork** -- Automatically downloads horizontal grids, vertical grids, hero images, logos, and icons for newly added games.
- **Protontricks integration** -- Launch protontricks GUI, run executables in specific prefixes, or create empty prefixes.

![Adding a game](<images/umu-hero - add game.png>)

## Requirements

- **Linux** with Steam installed
- **Heroic Games Launcher** (Flatpak or native) with games installed
- **Python 3**
- **curl**
- **Proton / GE-Proton** installed in `~/.local/share/Steam/compatibilitytools.d/`

Optional:
- **protontricks** (standalone or Flatpak) for advanced prefix management
- **SteamGridDB API key** for automatic artwork downloads

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/FranjeGueje/umu-hero.git
   cd umu-hero
   ```

2. Make the script executable:
   ```bash
   chmod +x umu-hero.sh
   ```

3. Run the tool:
   ```bash
   ./umu-hero.sh
   ```

Alternatively, download the latest AppImage from the [Releases](https://github.com/FranjeGueje/umu-hero/releases) page.

## Usage

### Adding games from Heroic

1. Launch UMU-Hero and click **"Add Games!"**
2. Select the store (Epic, GOG, or Amazon) and choose a game.
3. Choose an action:
   - **All-in-one**: Creates a `.bat` runner, adds it to Steam, downloads artwork, and configures the UMU prefix.
   - **Create .bat only**: Generates the batch file for the game.
   - **Create Prefix only**: Creates a UMU prefix with protonfixes for the game.

![Heroic games selection](<images/umu-hero - Heroic.png>)

### UMU Prefix management

1. Click **"UMU Prefix!"** from the main menu.
2. Browse or search the UMU database for your game.
3. Select a Proton version and create the prefix.

![UMU Prefix menu](<images/umu-hero - umu.png>)

### Other options

- **Ubisoft games**: Automatically detected from existing Proton prefixes.
- **File launcher**: Browse for any `.exe` and add it to Steam.
- **Protontricks**: Launch protontricks GUI or run executables in specific prefixes.
- **Options**: Configure Heroic config path, runners directory, SteamGridDB API key, and protontricks path.

## Configuration

Settings are saved to `~/.config/umu-hero.conf`. You can configure:

| Option | Description |
|---|---|
| Heroic config directory | Path to Heroic's config files (auto-detected) |
| Runners directory | Output directory for generated `.bat` files |
| SteamGridDB API key | For downloading game artwork |
| protontricks path | Path to protontricks binary or Flatpak |

## Project Structure

```
umu-hero/
├── umu-hero.sh           # Main application script
├── template.bat          # Windows batch file template
├── bin/
│   ├── jq                # JSON processor
│   ├── yad               # GTK dialog tool
│   ├── shortcutsNameID   # Steam VDF parser
│   └── umu-run           # UMU launcher
├── launchers/
│   ├── legendary.exe     # Epic Games CLI launcher
│   ├── gogdl.exe         # GOG CLI downloader
│   ├── nile.exe          # Amazon CLI launcher
│   └── EpicGamesLauncher.exe
├── assets/               # Icons and splash screens
└── images/               # Documentation screenshots
```

## Author

**Paco Guerrero** (FranjeGueje) -- fjgj1@hotmail.com

## License

MIT License

## Links

- [GitHub Repository](https://github.com/FranjeGueje/umu-hero)
- [UMU Database](https://umu.openwinecomponents.org)
- [Heroic Games Launcher](https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher)
- [SteamGridDB](https://www.steamgriddb.com)
