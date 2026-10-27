#!/bin/bash
#
# Bash-based Wine Prefix Manager (wpm.sh) v0.3-dev
# Copyright (C) 2026 Enrico Heine
# https://github.com/Flashdown/wpm
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License Version 3 as
# published by the Free Software Foundation Version 3 of the License.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

################################################################################################################################
# The Script uses by default ~/Wine as main folder, feel free to change the WINE_BASE variable below to match your preference. #
################################################################################################################################
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WINE_BASE="$HOME/Wine"
VERSIONS_DIR="$WINE_BASE/versions"
PREFIXES_DIR="$WINE_BASE/Prefixes"
WINETRICKS_CACHE="$HOME/.cache/winetricks"
DEPS_DIR="$WINE_BASE/deps"
WINETRICKS="$DEPS_DIR/winetricks"
TEMPLATES_DIR="$WINE_BASE/templates"

mkdir -p "$VERSIONS_DIR" "$PREFIXES_DIR" "$WINETRICKS_CACHE" "$DEPS_DIR" "$TEMPLATES_DIR"

print_info()  { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
print_warn()  { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
print_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
print_header(){ echo -e "${BLUE}=== $1 ===${NC}" >&2; }

usage() {
cat << 'EOF'
Usage: wpm <command> [options]

Commands:
  create <name>          Create a new Wine prefix (name is mandatory)
  list                   List all managed prefixes
  info <name>            Show details about a prefix
  delete <name>          Delete a prefix
  run <name> [cmd...]    Run a command inside the prefix (e.g. winecfg, regedit, executables, winetricks, etc.)
  shell <name>           Open an interactive shell in the prefix (e.g. run winecfg, winetricks
                          or launch/test apps from here via wine e.g.: wine /path/to/my.exe)
  templates              List available templates

Options for create:
  --wine <version|path|url>
                             Wine version (Kron4ek name, default: per-template or 11.15),
                             full path to a custom Wine binary (e.g. /opt/cxoffice/bin/wine),
                             or a direct http(s) URL to a .tar.xz / .tar.gz Wine build.
                             Supports vanilla (e.g. 11.15), staging (e.g. staging-11.15)
                             and proton (e.g. proton-9.0, proton-exp-11.0) from Kron4ek.
  --template <name>          Apply a template from $HOME/Wine/templates/<name>.sh
  --arch <32|64>             Prefix architecture (default: 64, or template preference)
  --force                    Overwrite existing prefix

Templates live in simple files under $HOME/Wine/templates/.
Each template can define:
  DEFAULT_WINE="11.15"          # or /path/to/wine  or  https://.../wine-xxx.tar.xz
  DEFAULT_ARCH="32"             # optional
  WINETRICKS_DEPS="corefonts ..."
  prepare_extra() { ... }       # optional extra steps (receives prefix_path wine_bin)

Examples:
  # Command & Conquer Gold Template
  wpm create myprefix --template cnc-gold

  # 32-bit prefix without template
  wpm create myapp32 --arch 32

  # Proton prefix
  wpm create mygame --wine proton-exp-11.0

  # Use any wine build you like, such as CrossOver Wine, by path:
  wpm create myoffice --wine /opt/cxoffice/bin/wine --template mytemplate

  # Download and use a custom runner from any URL:
  wpm create mycustom --wine https://example.com/wine-fancy-amd64.tar.xz

  # Common 'run' examples:
  wpm run myprefix winecfg
  wpm run myprefix regedit
  wpm run myprefix explorer
  wpm run myprefix /path/to/myapp.exe
  wpm run myprefix 'C:\Program Files\MyApp\app.exe'
  wpm run myprefix winetricks corefonts dotnet48 vcrun2022

  # Open Explorer inside the prefix
  wpm run myprefix explorer

  # Open a shell inside the prefix (e.g. run winecfg, winetricks
  # or launch/test apps from here via wine e.g.: wine /path/to/my.exe)
  wpm shell myprefix

EOF
}

install_system_deps() {
    if ! command -v cabextract &>/dev/null; then
        print_warn "System dependency 'cabextract' is missing."
        print_warn "Please install it with your distribution's package manager, e.g.:"
        print_warn "  Debian/Ubuntu:   sudo apt install cabextract"
        print_warn "  Fedora/RHEL:     sudo dnf install cabextract"
        print_warn "  Arch:            sudo pacman -S cabextract"
        print_warn "  openSUSE:        sudo zypper install cabextract"
        print_warn "Other useful tools (wget, unzip, curl) should also be present."
    fi
    ensure_winetricks || return 1
}

# ---------------------------------------------------------------------------
# Wine binary resolution (Kron4ek name | absolute path | http(s) URL)
# ---------------------------------------------------------------------------

get_wine_binary() {
    local ver="$1"
    local dir_name
    if [[ "$ver" == staging-* || "$ver" == *-staging ]]; then
        local base="${ver#staging-}"; base="${base%-staging}"
        dir_name="wine-${base}-staging-amd64"
    else
        dir_name="wine-${ver}-amd64"
    fi
    echo "$VERSIONS_DIR/$dir_name/bin/wine"
}

get_prefix_wine_binary() {
    local prefix_path="$1"
    if [ -f "$prefix_path/.wine-binary" ]; then
        head -n1 "$prefix_path/.wine-binary"
        return 0
    fi
    # Fallback for old prefixes (created before .wine-binary was added)
    local ver
    ver=$(head -n1 "$prefix_path/.wine-version" 2>/dev/null || echo "11.11")
    if [[ "$ver" == /* ]]; then
        echo "$ver"
    else
        get_wine_binary "$ver"
    fi
}

ensure_wine_downloaded() {
    local ver="$1"
    local wine_bin; wine_bin=$(get_wine_binary "$ver")
    [ -x "$wine_bin" ] && { print_info "Wine $ver already cached"; return 0; }

    print_header "Downloading Wine $ver from Kron4ek"
    local dir_name fname tag="$ver"

    if [[ "$ver" == staging-* || "$ver" == *-staging ]]; then
        local base="${ver#staging-}"; base="${base%-staging}"
        dir_name="wine-${base}-staging-amd64"
        fname="wine-${base}-staging-amd64.tar.xz"
        tag="$base"
    else
        dir_name="wine-${ver}-amd64"
        fname="wine-${ver}-amd64.tar.xz"
    fi

    wget --progress=bar -O "/tmp/$fname" "https://github.com/Kron4ek/Wine-Builds/releases/download/${tag}/${fname}" || return 1
    tar -xf "/tmp/$fname" -C "$VERSIONS_DIR"
    rm -f "/tmp/$fname"
}

# Download an arbitrary Wine/Proton build from a direct URL and cache it
download_wine_from_url() {
    local url="$1"
    local fname
    fname=$(basename "${url%%\?*}")
    local dir_name="${fname}"
    dir_name="${dir_name%.tar.xz}"
    dir_name="${dir_name%.tar.gz}"
    dir_name="${dir_name%.tgz}"
    dir_name="${dir_name%.tar}"

    local wine_cand="$VERSIONS_DIR/$dir_name/bin/wine"
    if [ -x "$wine_cand" ]; then
        print_info "Wine from URL already cached as $dir_name"
        echo "$wine_cand"
        return 0
    fi

    print_header "Downloading Wine from URL"
    print_info "$url"
    local tmp="/tmp/wpm-wine-$$.archive"
    if ! wget --progress=bar -O "$tmp" "$url"; then
        print_error "Failed to download $url"
        rm -f "$tmp"
        return 1
    fi

    local extract_tmp="/tmp/wpm-extract-$$"
    mkdir -p "$extract_tmp"
    if ! tar -xf "$tmp" -C "$extract_tmp" 2>/dev/null; then
        print_error "Failed to extract archive (unsupported format?)"
        rm -rf "$tmp" "$extract_tmp"
        return 1
    fi
    rm -f "$tmp"

    # Locate the wine binary inside the extracted tree
    local found_wine
    found_wine=$(find "$extract_tmp" -type f -name wine \( -executable -o -perm -111 \) 2>/dev/null | head -n1)
    if [ -z "$found_wine" ]; then
        print_error "No executable 'wine' binary found inside the archive"
        rm -rf "$extract_tmp"
        return 1
    fi

    # The directory that contains bin/ (or the parent of the wine binary)
    local wine_root
    wine_root=$(dirname "$(dirname "$found_wine")")
    # Safety: if the structure is flatter, fall back
    if [ ! -d "$wine_root/bin" ]; then
        wine_root=$(dirname "$found_wine")
    fi

    # Avoid clobbering an existing different build
    if [ -d "$VERSIONS_DIR/$dir_name" ]; then
        local hash
        hash=$(printf '%s' "$url" | md5sum | cut -c1-8)
        dir_name="${dir_name}-${hash}"
    fi

    mv "$wine_root" "$VERSIONS_DIR/$dir_name" || {
        print_error "Failed to move extracted Wine into cache"
        rm -rf "$extract_tmp"
        return 1
    }
    rm -rf "$extract_tmp"

    local final_bin="$VERSIONS_DIR/$dir_name/bin/wine"
    if [ ! -x "$final_bin" ]; then
        final_bin=$(find "$VERSIONS_DIR/$dir_name" -type f -name wine \( -executable -o -perm -111 \) 2>/dev/null | head -n1)
    fi
    if [ ! -x "$final_bin" ]; then
        print_error "Could not locate wine binary after extraction"
        return 1
    fi

    print_info "Cached Wine build as $dir_name"
    echo "$final_bin"
}

# Resolve any of: Kron4ek version name | absolute path | http(s) URL  → full path to wine binary
resolve_wine() {
    local ver="$1"
    if [[ -z "$ver" ]]; then
        print_error "No Wine version/path/URL specified"
        return 1
    fi

    if [[ "$ver" == /* ]]; then
        if [ -x "$ver" ]; then
            echo "$ver"
            return 0
        else
            print_error "Custom Wine binary not found or not executable: $ver"
            return 1
        fi
    elif [[ "$ver" == http://* || "$ver" == https://* ]]; then
        download_wine_from_url "$ver"
    else
        ensure_wine_downloaded "$ver" || return 1
        get_wine_binary "$ver"
    fi
}

ensure_winetricks() {
    mkdir -p "$DEPS_DIR"
    if [ -x "$WINETRICKS" ]; then
        local ver
        ver=$("$WINETRICKS" --version 2>/dev/null | head -n1 || echo "unknown")
        print_info "Using cached winetricks ($ver) from $DEPS_DIR"
        return 0
    fi

    print_header "Downloading latest winetricks from GitHub"
    if wget --progress=bar -O "$WINETRICKS" "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"; then
        chmod +x "$WINETRICKS"
        local ver
        ver=$("$WINETRICKS" --version 2>/dev/null | head -n1 || echo "unknown")
        print_info "winetricks $ver successfully downloaded to $WINETRICKS"
    else
        print_error "Failed to download winetricks"
        rm -f "$WINETRICKS"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Templates
# ---------------------------------------------------------------------------

# Source a template file and populate the expected variables / functions
# After calling: DEFAULT_WINE, DEFAULT_ARCH, WINETRICKS_DEPS are set (or empty)
# and prepare_extra() may be defined by the template.
load_template() {
    local tname="$1"
    local tfile="$TEMPLATES_DIR/${tname}.sh"

    if [ ! -f "$tfile" ]; then
        print_error "Template '$tname' not found."
        print_info "Available templates are in: $TEMPLATES_DIR"
        print_info "Run: wpm templates"
        exit 1
    fi

    # Reset so a previous template cannot leak
    DEFAULT_WINE=""
    DEFAULT_ARCH=""
    WINETRICKS_DEPS=""
    # Provide a no-op so "prepare_extra" is always defined after source
    prepare_extra() { :; }

    # shellcheck source=/dev/null
    source "$tfile"

    print_info "Loaded template: $tname"
}

apply_template() {
    local prefix_path="$1"
    local wine_bin="$2"
    local tname="$3"
    local name
    name=$(basename "$prefix_path")

    print_header "Preparing prefix with template '$tname'"

    export W_CACHE="$WINETRICKS_CACHE"

    if [ -n "$WINETRICKS_DEPS" ]; then
        print_info "Installing winetricks components: $WINETRICKS_DEPS"
        if ! WINEPREFIX="$prefix_path" WINE="$wine_bin" "$WINETRICKS" -q $WINETRICKS_DEPS; then
            print_warn "Some winetricks packages had issues (non-fatal)"
        fi
    else
        print_info "Template defines no WINETRICKS_DEPS – skipping winetricks"
    fi

    # Call the (possibly template-provided) extra function
    if declare -f prepare_extra >/dev/null 2>&1; then
        prepare_extra "$prefix_path" "$wine_bin"
    fi

    print_info "Template '$tname' applied successfully."
    echo ""
}

# ---------------------------------------------------------------------------
# CMD FUNCTIONS
# ---------------------------------------------------------------------------

cmd_create() {
    local name="$1"
    shift || true

    # --- Mandatory non-empty name check ---
    if [[ -z "$name" || "$name" == -* ]]; then
        print_error "Prefix name is required and must not start with '-'."
        print_info  "Usage: wpm create <name> [options]"
        exit 1
    fi

    local wine_ver=""
    local wine_explicit=false
    local prepare_target=""
    local arch="64"
    local arch_explicit=false
    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --wine)
                wine_ver="$2"
                wine_explicit=true
                shift 2
                ;;
            --template)
                prepare_target="$2"
                shift 2
                ;;
            --arch)
                arch="$2"
                arch_explicit=true
                shift 2
                ;;
            --force)
                force=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Load template early so we can pick up its defaults
    if [ -n "$prepare_target" ]; then
        load_template "$prepare_target"
    fi

    # Resolve wine version: explicit --wine wins, otherwise template default, otherwise 11.15
    if [ -z "$wine_ver" ]; then
        if [ -n "$DEFAULT_WINE" ]; then
            wine_ver="$DEFAULT_WINE"
        else
            wine_ver="11.15"
        fi
    fi

    # Resolve architecture preference from template when not overridden
    if [ "$arch_explicit" != true ] && [ -n "$DEFAULT_ARCH" ]; then
        arch="$DEFAULT_ARCH"
    fi

    local prefix_path="$PREFIXES_DIR/$name"
    local do_init=true
    if [ -d "$prefix_path" ]; then
        if [ "$force" = true ]; then
            print_warn "Removing existing prefix '$name' (--force)"
            rm -rf "$prefix_path"
        elif [ -n "$prepare_target" ]; then
            print_info "Prefix '$name' already exists — applying template (refreshing components)..."
            do_init=false
        else
            print_error "Prefix already exists. Use --force to overwrite."
            exit 1
        fi
    fi

    local wine_bin
    if [ "$do_init" = true ]; then
        wine_bin=$(resolve_wine "$wine_ver") || exit 1
    else
        # Re-apply template on existing prefix → keep its original runner
        print_header "Preparing existing prefix '$name'"
        if [ -f "$prefix_path/.wine-binary" ]; then
            wine_bin=$(head -n1 "$prefix_path/.wine-binary")
            print_info "Using stored wine binary for this prefix"
        else
            local wine_ver_existing
            wine_ver_existing=$(head -n1 "$prefix_path/.wine-version" 2>/dev/null || echo "$wine_ver")
            if [[ "$wine_ver_existing" == custom || "$wine_ver_existing" == /* || "$wine_ver_existing" == http* ]]; then
                print_error "Existing prefix uses a custom/URL runner but .wine-binary is missing. Aborting."
                exit 1
            fi
            wine_bin=$(resolve_wine "$wine_ver_existing") || exit 1
        fi
        if [ ! -x "$wine_bin" ]; then
            print_error "Wine binary for existing prefix is not executable: $wine_bin"
            exit 1
        fi
    fi

    if [ "$do_init" = true ]; then
        print_header "Creating prefix '$name' with Wine ($wine_ver) (arch: win$arch)"
        mkdir -p "$prefix_path"

        if [[ "$wine_ver" == /* || "$wine_ver" == http://* || "$wine_ver" == https://* ]]; then
            echo "custom" > "$prefix_path/.wine-version"
        else
            echo "$wine_ver" > "$prefix_path/.wine-version"
        fi
        echo "$arch" > "$prefix_path/.wine-arch"
        echo "$wine_bin" > "$prefix_path/.wine-binary"

        local winearch="win${arch}"
        WINEPREFIX="$prefix_path" WINEARCH="$winearch" "$wine_bin" wineboot --init &>/dev/null || true
    fi

    export W_CACHE="$WINETRICKS_CACHE"

    if [ -n "$prepare_target" ]; then
        apply_template "$prefix_path" "$wine_bin" "$prepare_target"
    fi

    print_info "Prefix '$name' ready!"
    echo ""
    print_info "You can now install software or run programs using:"
    print_info "  wpm run $name explorer"
    print_info "  wpm run $name C:\\myfolder\\myfile.exe or /path/to/my.exe"
    echo ""
    print_info "Or run an interactive shell in your prefix and do anything you like:"
    print_info "  wpm shell $name (e.g run: winecfg, winetricks, regedit,wine explorer, wine /path/to/my.exe, and so on...)"
}

cmd_list() {
    print_header "Managed Wine Prefixes"
    if [ ! -d "$PREFIXES_DIR" ] || [ -z "$(ls -A "$PREFIXES_DIR" 2>/dev/null)" ]; then
        echo "No prefixes found."; return
    fi
    printf "%-22s %-28s %-8s %s\n" "NAME" "WINE" "ARCH" "PATH"
    printf "%-22s %-28s %-8s %s\n" "----" "----" "----" "----"
    for p in "$PREFIXES_DIR"/*; do
        [ -d "$p" ] || continue
        local name; name=$(basename "$p")
        local ver="unknown"
        if [ -f "$p/.wine-version" ]; then
            ver=$(head -n1 "$p/.wine-version")
            if [ "$ver" = "custom" ] && [ -f "$p/.wine-binary" ]; then
                local binpath; binpath=$(head -n1 "$p/.wine-binary")
                ver="custom ($(basename "$binpath"))"
            fi
        fi
        local parch="64"
        [ -f "$p/.wine-arch" ] && parch=$(head -n1 "$p/.wine-arch")
        printf "%-22s %-28s %-8s %s\n" "$name" "$ver" "$parch" "$p"
    done
}

cmd_info() {
    local name="$1"
    if [[ -z "$name" ]]; then
        print_error "Prefix name is required."
        exit 1
    fi
    local prefix_path="$PREFIXES_DIR/$name"
    [ ! -d "$prefix_path" ] && { print_error "Prefix '$name' does not exist."; exit 1; }
    print_header "Info for prefix: $name"
    echo "Location: $prefix_path"
    if [ -f "$prefix_path/.wine-binary" ]; then
        echo "Wine binary: $(head -n1 "$prefix_path/.wine-binary")"
    fi
    if [ -f "$prefix_path/.wine-version" ]; then
        local wver; wver=$(head -n1 "$prefix_path/.wine-version")
        if [ "$wver" != "custom" ]; then
            echo "Wine version: $wver"
        fi
    fi
    local parch="64"
    [ -f "$prefix_path/.wine-arch" ] && parch=$(head -n1 "$prefix_path/.wine-arch")
    echo "Architecture: win${parch}"
    echo "Size: $(du -sh "$prefix_path" 2>/dev/null | cut -f1)"
}

cmd_delete() {
    local name="$1"
    if [[ -z "$name" ]]; then
        print_error "Prefix name is required."
        exit 1
    fi
    local prefix_path="$PREFIXES_DIR/$name"
    [ ! -d "$prefix_path" ] && { print_error "Prefix does not exist."; exit 1; }
    read -r -p "Really delete '$name'? (y/N) " c
    [[ "$c" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    rm -rf "$prefix_path"
    print_info "Prefix '$name' deleted."
}

cmd_run() {
    local name="$1"; shift || true
    if [[ -z "$name" ]]; then
        print_error "Prefix name is required."
        exit 1
    fi
    local prefix_path="$PREFIXES_DIR/$name"
    [ ! -d "$prefix_path" ] && { print_error "Prefix does not exist."; exit 1; }
    local wine_bin; wine_bin=$(get_prefix_wine_binary "$prefix_path")
    [ ! -x "$wine_bin" ] && { print_error "Wine binary for prefix not found or not executable: $wine_bin"; exit 1; }

    export WINEPREFIX="$prefix_path"
    export WINE="$wine_bin"
    export WINELOADER="$wine_bin"
    export WINESERVER="${wine_bin%/*}/wineserver"
    export PATH="$DEPS_DIR:${wine_bin%/*}:$PATH"
    export W_CACHE="$WINETRICKS_CACHE"

    # winetricks support

    if [[ "$1" == "winetricks" ]]; then
        if [ ! -x "$WINETRICKS" ]; then
            ensure_winetricks || exit 1
        fi
        shift
        exec "$WINETRICKS" "$@"
    fi

    exec "$wine_bin" "$@"
}

cmd_shell() {
    local name="$1"
    if [[ -z "$name" ]]; then
        print_error "Prefix name is required."
        exit 1
    fi
    local prefix_path="$PREFIXES_DIR/$name"
    [ ! -d "$prefix_path" ] && { print_error "Prefix does not exist."; exit 1; }
    local wine_bin; wine_bin=$(get_prefix_wine_binary "$prefix_path")
    [ ! -x "$wine_bin" ] && { print_error "Wine binary for prefix not found or not executable: $wine_bin"; exit 1; }

    export WINEPREFIX="$prefix_path"
    export WINE="$wine_bin"
    export WINELOADER="$wine_bin"
    export WINESERVER="${wine_bin%/*}/wineserver"
    export PATH="$DEPS_DIR:${wine_bin%/*}:$PATH"
    export PS1="[\[\e[32m\]wine-$name\[\e[0m\]] \w \$ "

    # Start the interactive shell inside the prefix's drive_c
    local drive_c="$prefix_path/drive_c"
    if [ -d "$drive_c" ]; then
        cd "$drive_c" || true
    fi

    print_info "Entering shell for '$name'. Type 'exit' to leave."
    print_info "Tip: You can now run 'winetricks ...' directly (bundled version is in PATH)."
    exec bash --norc -i
}

cmd_templates() {
    print_header "Available templates ($TEMPLATES_DIR)"
    local found=false
    for f in "$TEMPLATES_DIR"/*.sh; do
        [ -f "$f" ] || continue
        found=true
        local tname
        tname=$(basename "$f" .sh)
        # Show a short description from the first comment line if present
        local desc
        desc=$(grep -m1 -E '^# Template:' "$f" 2>/dev/null | sed 's/^# Template:[[:space:]]*//')
        if [ -n "$desc" ]; then
            printf "  %-20s %s\n" "$tname" "$desc"
        else
            printf "  %s\n" "$tname"
        fi
    done
    if [ "$found" = false ]; then
        echo "  (no templates found)  "
    fi
    echo
    print_info "Create or edit template files in $TEMPLATES_DIR to manage your templates."
}

main() {
    local cmd="$1"; shift || true
    case "$cmd" in
        create)
            # Fail fast on missing/invalid name before downloading anything
            if [[ -z "$1" || "$1" == -* ]]; then
                print_error "Prefix name is required and must not start with '-'."
                print_info  "Usage: wpm create <name> [options]"
                exit 1
            fi
            install_system_deps
            cmd_create "$@"
            ;;
        list) cmd_list ;;
        info) cmd_info "$1" ;;
        delete|rm) cmd_delete "$1" ;;
        run) cmd_run "$@" ;;
        shell) cmd_shell "$1" ;;
        templates) cmd_templates ;;
        -h|--help|help|"") usage ;;
        *) print_error "Unknown command: $cmd"; usage; exit 1 ;;
    esac
}

main "$@"
