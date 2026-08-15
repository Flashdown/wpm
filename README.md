# wpm – a bash-based Wine Prefix Manager

**A transparent, Bash-based Wine prefix manager with template support.**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

> A fully working **Command & Conquer Gold** (Wine 11.15, 64-bit) template with multiplayer via CnCNet is included as a real-world example, plus a detailed `example-template` that shows how to create your own.

---
![WPM Screenshot](https://github.com/Flashdown/wpm/blob/main/screenshots/wpm-list_templates_create.png)
## Why this exists

I come from a time where it was normal to manually configure Wine within a single instance, non-prefixed world, to run Office 2007 and/or Photoshop, with DLL overrides and registry hacks. Nowadays my Linux Desktop usage increased and at one point I came to the conclusion that it would be useful to have my own bash based wine prefix manager, that does exactly what I need the way I want, so I can comfortably manage prefixes and runners and understand exactly what is going on, so can you, which is why I have choosen BASH as foundation for this script.

I tried Bottles and a few other GUI prefix managers. They work, but at some point they all feel like **black boxes**.  

What I really wanted was a tool that does **exactly** what I would need when testing and building Wine prefixes:

* a transparent, readable Bash script I fully understand and can modify, to stay independent
* an interactive shell inside any prefix for quick testing, debugging and manual tweaks,
* simple creation of clean, working prefixes,
* and the ability to turn a successful setup into a reusable template.

So I built **wpm** – a bash based prefix manager that stays out of the way, does what I expect, and is easy to extend.

---

## Features

* Create, list, inspect, delete and run commands inside isolated Wine prefixes
* **Interactive shell** (`wpm shell <name>`) – drop into a fully prepared environment for testing, debugging and manual work
* Automatic download & caching of Wine / Proton builds from [Kron4ek/Wine-Builds](https://github.com/Kron4ek/Wine-Builds/releases)
* Support for any custom Wine binary (path) or direct download URL
* Template system – turn a working prefix setup workflow into a reusable template
* Bundled, up-to-date winetricks (downloaded on first use)
* Works on any Linux distribution that provides Bash + common tools (no distribution-specific package managers required)

---

## Requirements

* Bash
* `wget` (or `curl` for some template actions)
* `cabextract` (needed by many winetricks packages)
* `unzip` (used by some templates)
* Optional but recommended: `xdg-open` (for templates that open download pages)

If `cabextract` is missing, `wpm` will print a clear warning with the install commands for the most common distributions.

---

## Installation

```bash
# Clone the repository
git clone https://github.com/Flashdown/wpm.git
cd wpm

# Move the script where you want to store it

# Make the script executable
chmod +x wpm.sh

# Recommended: create an alias that points to the script when running wpm
# (add this line to your ~/.bashrc or ~/.zshrc)
# Replace the path with the real location of where you keep the wpm.sh script
alias wpm='/path/to/wpm/wpm.sh'

# Reload your shell configuration
source ~/.bashrc   # or: source ~/.zshrc
```

The first time you run any command that needs them, `wpm` will automatically create if missing:

```
~/Wine/
├── versions/          # cached Wine / Proton builds
├── Prefixes/          # your prefixes
├── deps/              # winetricks
└── templates/         # default templates are written here on first run
```

You can change the base directory by editing the `WINE_BASE` variable at the top of the script.

---

## Quick start

```bash
# Create a new 64-bit prefix (defaults to Wine 11.15)
wpm create myapp

# Create a prefix using the ready-made Command & Conquer Gold template
wpm create cnc --template cnc-gold

# Create a 32-bit prefix with a specific Wine version
wpm create oldgame --arch 32 --wine 9.0

# Use a Proton build
wpm create mygame --wine proton-exp-11.0

# Use any custom Wine binary (e.g. CrossOver)
wpm create office --wine /opt/cxoffice/bin/wine

# Download and use a Wine build from a direct URL
wpm create fancy --wine https://example.com/wine-fancy-amd64.tar.xz
```

### Running things inside a prefix

```bash
wpm run myapp winecfg
wpm run myapp regedit
wpm run myapp explorer
wpm run myapp winetricks corefonts vcrun2022
wpm run myapp /path/to/setup.exe
wpm run myapp 'C:\Program Files\MyApp\app.exe'

# Interactive shell (PATH already contains wine + winetricks)
wpm shell myapp
# inside the shell you can just type:
#   winecfg
#   winetricks ...
#   wine /path/to/my.exe
```

### Managing prefixes

```bash
wpm list
wpm info myapp
wpm delete myapp
wpm templates          # show available templates
```

---

## Templates

Templates live as simple Bash files in `~/Wine/templates/`.

A template can define:

```bash
# Template: TEMPLATE DESCRIPTION that is shown in the "wpm templates" listing
DEFAULT_WINE="11.15"          # Kron4ek version, absolute path, or URL
DEFAULT_ARCH="64"             # 32 or 64
WINETRICKS_DEPS="dotnet35 corefonts ..."

prepare_extra() {
    local prefix_path="$1"
    local wine_bin="$2"
    # any extra steps: registry, DLL overrides, installers, …
}
```

### Built-in examples

| Template            | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `cnc-gold`          | Fully working Command & Conquer Gold (1.06c) + cnc-ddraw (github.com/FunkyFr3sh/cnc-ddraw) + CnCNet Multiplayer |
| `example-template`  | Documented skeleton that shows every available hook                         |

These two are shipped inside the main script and are written to `~/Wine/templates/` on first run. They will probably always stay as the only default examples provided by the script itself so we dont polute the main script with more templates.

### Adding more templates

1. Browse the [`templates/`](templates/) folder of this repository.
2. Download the `.sh` file you want.
3. Place it in `~/Wine/templates/`.
4. Use it with `wpm create <name> --template <filename-without-.sh>`.

A download helper for community templates may be added later. Until then the manual method above is the way to go.

**Pull requests that add new templates to the `templates/` directory are very welcome!**  
Just open a PR – we keep the two built-in examples in the main script, everything else lives in the repository’s `templates/` folder for the community.

See [`templates/README.md`](templates/README.md) for more details.

---

## DEMO Screenshots

**The screenshots below show a complete Command & Conquer Gold installation from beginning to end that has been created via the `cnc-gold` template**

![WPM Screenshot](https://github.com/Flashdown/wpm/blob/main/screenshots/wpm-list_templates_create.png)
![cnc-gold #1](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_game_download.png)
![cnc-gold #2](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_game_download_videopack_german.png)
![cnc-gold #3](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_game_install.png)
![cnc-gold #4](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_game_install_blackscreen_apply_fix_via_taskbar_icon_click.png)
![cnc-gold #5](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_game_install_blackscreen_fixed_via_taskbar_icon_click.png)
![cnc-gold #6](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_game_install_in_progress.png)
![cnc-gold #7](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_game_install_is_finished.png)
![cnc-gold #8](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_game_install_resolution_selection.png)
![cnc-gold #9](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_game_resolution_update_res_to_1440x960_for_my_1080p_screen.png)
![cnc-gold #10](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_videopack_german_install.png)
![cnc-gold #11](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_videopack_german_install_blackscreen.png)
![cnc-gold #12](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_videopack_german_install_blackscreen_fixed_by_taskbar_icon_click.png)
![cnc-gold #13](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_videopack_install_running.png)
![cnc-gold #14](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_videpack_install_finished.png)
![cnc-gold #15](https://github.com/Flashdown/wpm/blob/main/screenshots/cnc-gold/cnc-gold_z_setup_fully_completed.png)




---

## License

This project is licensed under the **GNU General Public License v3.0**.  
See the [LICENSE](LICENSE) file or <https://www.gnu.org/licenses/gpl-3.0> for details.

---

## Contributing

* Bug reports and feature requests → open an issue
* New templates → open a pull request that adds the file to the `templates/` directory
* Improvements to the core script → also very welcome

Keep it simple, keep it transparent. That’s the whole point of `wpm`.
