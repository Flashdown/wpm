# Template: Command & Conquer Gold - (including multiplayer support via CnCNet)

DEFAULT_WINE="11.15"
DEFAULT_ARCH="64"

WINETRICKS_DEPS="dotnet35"

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
# ---------------------------------------------------------------------------

prepare_extra() {
    local prefix_path="$1"
    local wine_bin="$2"

    # ------------------------------------------------------------------
    # 1. Download main C&C95 v1.06c r3 full game installer (detection only)
    # ------------------------------------------------------------------
    local url="https://www.moddb.com/mods/command-conquer-unofficial-patch-106/downloads/cc95-v106c-revision-3-full-game-installer"
    local installer="cc95v106c_r3_u6_full.exe"
    local dest="$HOME/Downloads/$installer"

    echo ""
    echo "================================================================"
    echo "  Command & Conquer Gold 1.06c r3 full installer is required"
    echo "================================================================"
    echo ""
    echo "Opening the official download page in your browser..."
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" 2>/dev/null || true
    else
        echo "xdg-open not found. Please open this URL manually:"
        echo "  $url"
    fi

    echo ""
    echo "Please download the file named:"
    echo "  $installer"
    echo ""
    echo "Make sure it ends up in your Downloads folder:"
    echo "  $dest"
    echo ""
    echo "If your browser saved it elsewhere, move or copy it there."
    echo "(This script will NOT create the Downloads folder for you.)"
    echo ""

    while true; do
        read -r -p "Press ENTER once the file is ready in Downloads (or type 'q' to abort): " answer
        if [[ "${answer,,}" == "q" ]]; then
            echo "Aborted by user."
            return 1
        fi

        if [[ -f "$dest" ]]; then
            echo "Main installer found at: $dest"
            break
        else
            echo ""
            echo "File NOT found at: $dest"
            echo ""
            read -r -p "Check again? [Y/n] (or 'q' to stop): " retry
            case "${retry,,}" in
                n|no|q|quit)
                    echo "Stopping as requested."
                    return 1
                    ;;
                *)
                    # loop again and re-check
                    ;;
            esac
        fi
    done

    # ------------------------------------------------------------------
    # 2. Optional video package (German / English / Skip)
    # ------------------------------------------------------------------
    local video_url=""
    local video_installer=""
    local video_dest=""
    local video_choice=""

    echo ""
    echo "================================================================"
    echo "  Optional video content package"
    echo "================================================================"
    echo ""
    echo "The base game installer does not include the FMV videos."
    echo "You can optionally download a language-specific video pack."
    echo ""
    echo "  1) Download German video package"
    echo "  2) Download English video package"
    echo "  3) Skip (no videos)"
    echo ""

    while true; do
        read -r -p "Choose [1/2/3]: " video_choice
        case "${video_choice}" in
            1)
                video_url="https://www.moddb.com/mods/command-conquer-unofficial-patch-106/downloads/command-conquer-german-videos-base-pack"
                video_installer="cc95v106_videobase_ger.1.exe"
                video_dest="$HOME/Downloads/$video_installer"
                break
                ;;
            2)
                video_url="https://www.moddb.com/mods/command-conquer-unofficial-patch-106/downloads/command-conquer-english-videos-base-pack"
                video_installer="cc95v106_videobase_eng.1.exe"
                video_dest="$HOME/Downloads/$video_installer"
                break
                ;;
            3)
                echo "Skipping video package."
                video_installer=""
                break
                ;;
            *)
                echo "Please enter 1, 2 or 3."
                ;;
        esac
    done

    if [[ -n "$video_installer" ]]; then
        echo ""
        echo "Opening the video package download page..."
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$video_url" 2>/dev/null || true
        else
            echo "xdg-open not found. Please open this URL manually:"
            echo "  $video_url"
        fi

        echo ""
        echo "Please download the file named:"
        echo "  $video_installer"
        echo ""
        echo "Make sure it ends up in your Downloads folder:"
        echo "  $video_dest"
        echo ""
        echo "If your browser saved it elsewhere, move or copy it there."
        echo ""

        while true; do
            read -r -p "Press ENTER once the video file is ready in Downloads (or type 'q' to abort): " answer
            if [[ "${answer,,}" == "q" ]]; then
                echo "Aborted by user."
                return 1
            fi

            if [[ -f "$video_dest" ]]; then
                echo "Video package found at: $video_dest"
                break
            else
                echo ""
                echo "File NOT found at: $video_dest"
                echo ""
                read -r -p "Check again? [Y/n] (or 'q' to stop): " retry
                case "${retry,,}" in
                    n|no|q|quit)
                        echo "Stopping as requested."
                        return 1
                        ;;
                    *)
                        # loop again
                        ;;
                esac
            fi
        done
    fi

    # ------------------------------------------------------------------
    # 3. All files present → run installers in order
    # ------------------------------------------------------------------
    echo ""
    echo "================================================================"
    echo "  Running installers"
    echo "================================================================"
    echo ""

    echo "Launching main game installer..."
    WINEDEBUG=-all WINEPREFIX="$prefix_path" WINE="$wine_bin" "$wine_bin" "$dest" >/dev/null 2>&1
    local ret=$?
    if [[ $ret -eq 0 ]]; then
        echo "Main installer finished successfully."
    else
        echo "Main installer exited with code $ret (this may be normal for GUI installers)."
    fi
    echo ""

    if [[ -n "$video_installer" && -f "$video_dest" ]]; then
        echo "Launching video package installer..."
        WINEDEBUG=-all WINEPREFIX="$prefix_path" WINE="$wine_bin" "$wine_bin" "$video_dest" >/dev/null 2>&1
        ret=$?
        if [[ $ret -eq 0 ]]; then
            echo "Video package finished successfully."
        else
            echo "Video package exited with code $ret (this may be normal for GUI installers)."
        fi
        echo ""
    fi

    # ------------------------------------------------------------------
    # 4. Apply latest experimental cnc-ddraw (automatic)
    # ------------------------------------------------------------------
    local game_dir="$prefix_path/drive_c/Westwood/C&C95"
    local ddraw_url="https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/experimental/cnc-ddraw-experimental-release.zip"
    local ddraw_zip="/tmp/cnc-ddraw-experimental-release.zip"

    echo ""
    echo "================================================================"
    echo "  Applying cnc-ddraw (experimental) to fix all GFX Issues"
    echo "  Source: https://github.com/FunkyFr3sh/cnc-ddraw"
    echo "================================================================"
    echo ""

    if [[ ! -d "$game_dir" ]]; then
        echo "ERROR: Expected game directory not found:"
        echo "  $game_dir"
        echo "Did the installer finish and install to the default path?"
        echo "You can still manually extract cnc-ddraw into the correct folder later."
        return 1
    fi

    echo "Game directory found: $game_dir"
    echo "Downloading latest experimental cnc-ddraw..."

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL -o "$ddraw_zip" "$ddraw_url"; then
            echo "ERROR: Failed to download cnc-ddraw zip with curl."
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q -O "$ddraw_zip" "$ddraw_url"; then
            echo "ERROR: Failed to download cnc-ddraw zip with wget."
            return 1
        fi
    else
        echo "ERROR: Neither curl nor wget found. Cannot download cnc-ddraw automatically."
        echo "Please download manually from:"
        echo "  $ddraw_url"
        echo "and extract it into: $game_dir"
        return 1
    fi

    echo "Download complete. Extracting into game directory (overwriting conflicts)..."
    if ! command -v unzip >/dev/null 2>&1; then
        echo "ERROR: unzip not found. Please install unzip and re-run, or extract manually."
        rm -f "$ddraw_zip"
        return 1
    fi

    # -o = overwrite without prompting, -q = quiet
    if ! unzip -o -q "$ddraw_zip" -d "$game_dir"; then
        echo "ERROR: Failed to extract cnc-ddraw zip."
        rm -f "$ddraw_zip"
        return 1
    fi

    rm -f "$ddraw_zip"
    echo "cnc-ddraw extracted successfully."

    # Recommended DLL override for Wine + cnc-ddraw
    echo "Setting ddraw DLL override (native,builtin)..."
    WINEPREFIX="$prefix_path" WINE="$wine_bin" "$wine_bin" reg add \
        'HKEY_CURRENT_USER\Software\Wine\DllOverrides' \
        /v ddraw /t REG_SZ /d native,builtin /f >/dev/null 2>&1 || true

    echo ""
    echo "================================================================"
    echo "  Done! C&C95 is ready (including multiplayer via CnCNet)."
    echo "================================================================"
    echo ""
    echo "You can now run the game using:"
    echo "  wpm run $name \"C:\Westwood\C&C95\C&C95.exe\""
    echo ""
    echo "Warning: Change the resolution from now on only via CCConfigFull.exe and use 'cnc-ddraw config.exe' for all other settings"
    echo "otherwise, if you use CCConfig.exe and EACH TIME you do, you will have to redownload"
    echo "https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/experimental/cnc-ddraw-experimental-release.zip"
    echo "and extract its contents again into the game dir to get the game working again"
    echo ""
    echo "  wpm run $name \"C:\Westwood\C&C95\CCConfigFull.exe\""
    echo "  wpm run $name \"C:\Westwood\C&C95\cnc-ddraw config.exe\""
    echo ""
    echo " Start CnCNet for Multiplayer Games:"
    echo "  wpm run $name \"C:\Westwood\C&C95\cncnet5.exe\""
    echo ""
}
