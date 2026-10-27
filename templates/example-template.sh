# Template: Example Template - HowTo

DEFAULT_WINE="11.15" # Optional - uses wpm script defaults if not set, can be overwritten by the user using the --wine param
DEFAULT_ARCH="64"    # Optional - uses wpm script defaults if not set, can be overwritten by the user using the --arch param

################## DEFAULT_WINE Variable Logic ################################
# The DEFAULT_WINE Variable can contain: <version|path|url>
# this should allow you to use ANY runner you want

# version
# (Kron4ek version name, default: per-template or 11.11)
# Auto Downloads a runner from https://github.com/Kron4ek/Wine-Builds/releases
# Supports vanilla (e.g. 11.11), staging (e.g. staging-11.11)
# and proton (e.g. proton-9.0, proton-exp-11.0) from Kron4ek Repo.

# path
# to a custom Wine binary (e.g. /opt/cxoffice/bin/wine),

# url
# or a direct http(s) URL to a .tar.xz / .tar.gz Wine build.

##############################################################################

WINETRICKS_DEPS="dotnet35" # Optional as well

# :::::::::::::::::::::::: OPTIONAL - ADVANCED SCRIPTING ::::::::::::::::::::

# ---------------------------------------------------------------------------
# prepare_extra() – optional post-winetricks steps
# This function is called automatically after WINETRICKS_DEPS have been installed.
# It receives two arguments:
#   $1 = full path to the prefix   (e.g. $HOME/Wine/Prefixes/myoffice)
#   $2 = full path to the wine binary that belongs to this prefix
#
# You can do almost anything here: registry edits, DLL overrides/replacements,
# extra winetricks calls, running installers, copying files, etc.

# EXAMPLES BELOW
# ---------------------------------------------------------------------------
# prepare_extra() {
#     local prefix_path="$1"
#     local wine_bin="$2"
#
#     # ------------------------------------------------------------------
#     # 1. Registry change (example: force a specific Direct3D setting)
#     # ------------------------------------------------------------------
#     # WINEPREFIX="$prefix_path" WINE="$wine_bin" "$wine_bin" reg add \
#     #     'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
#     #     /v MaxVersionGL /t REG_DWORD /d 0x30002 /f
#
#     # ------------------------------------------------------------------
#     # 2. Replace / override a DLL
#     #    a) Copy a native DLL into the prefix
#     #    b) Tell Wine to prefer the native version
#     # ------------------------------------------------------------------
#     # mkdir -p "$prefix_path/drive_c/windows/system32"
#     # cp /path/to/your/native/d3d9.dll "$prefix_path/drive_c/windows/system32/"
#     # WINEPREFIX="$prefix_path" WINE="$wine_bin" "$wine_bin" reg add \
#     #     'HKEY_CURRENT_USER\Software\Wine\DllOverrides' \
#     #     /v d3d9 /t REG_SZ /d native,builtin /f
#
#     # ------------------------------------------------------------------
#     # 3. Run any command / executable inside the prefix
#     # ------------------------------------------------------------------
#     # WINEPREFIX="$prefix_path" WINE="$wine_bin" "$wine_bin" winecfg
#     # WINEPREFIX="$prefix_path" WINE="$wine_bin" "$wine_bin" \
#     #     "C:\\Program Files\\SomeApp\\setup.exe" /quiet
#
#     # ------------------------------------------------------------------
#     # 4. Call winetricks again (for packages that need a second pass
#     #    or that you deliberately left out of WINETRICKS_DEPS)
#     # ------------------------------------------------------------------
#     # export W_CACHE="$HOME/.cache/winetricks"
#     # WINEPREFIX="$prefix_path" WINE="$wine_bin" \
#     #     "$HOME/Wine/deps/winetricks" -q corefonts vcrun2019
#
#     # ------------------------------------------------------------------
#     # 5. Simple file / directory operations
#     # ------------------------------------------------------------------
#     # mkdir -p "$prefix_path/drive_c/users/Public/Documents"
#     # echo "Hello from prepare_extra" > "$prefix_path/drive_c/hello.txt"
# }

