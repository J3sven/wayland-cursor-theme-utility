#!/bin/bash
set -e

DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo "Dry-run mode enabled. Simulating the entire process without making any changes."
    echo ""
fi

echo "--------------------------------------"
echo "🖱️  Wayland Cursor Theme Utility"
echo "--------------------------------------"
echo "This script configures cursor themes on Wayland systems."

# Step 1: Ask if the user grants permission to use sudo for system-wide settings
USE_SUDO=false
if [ "$EUID" -ne 0 ]; then
    echo ""
    echo "⚠️  Some system-wide configurations require root privileges (sudo)."
    read -p "Do you allow this script to use sudo where needed? (y/n): " allow_sudo
    if [[ "$allow_sudo" == [yY] ]]; then
        USE_SUDO=true
        echo "✔️  Sudo access granted for necessary commands."
    else
        echo "⚠️  Sudo access not granted. System-wide settings will be skipped."
    fi
else
    echo "✔️  Running as root. Sudo is not required."
    USE_SUDO=true
fi

echo "--------------------------------------"
echo ""
read -p "Press Enter to continue to theme selection... "

# Step 2: List available cursor themes
list_cursor_themes() {
    local themes=()
    local theme_dirs=("/usr/share/icons" "$HOME/.icons" "$HOME/.local/share/icons")

    for dir in "${theme_dirs[@]}"; do
        if [ -d "$dir" ]; then
            for theme in "$dir"/*; do
                if [ -f "$theme/index.theme" ]; then
                    themes+=("$(basename "$theme")")
                fi
            done
        fi
    done

    printf "%s\n" "${themes[@]}" | sort -u
}

select_cursor_theme() {
    IFS=$'\n' read -d '' -r -a themes < <(list_cursor_themes && printf '\0')

    if [ ${#themes[@]} -eq 0 ]; then
        echo -e "\nNo cursor themes found on your system."
        echo -e "To install a cursor theme, you can:\n"
        echo "1. Download themes from sites like https://www.gnome-look.org."
        echo "2. Place the downloaded themes in one of these directories:"
        echo "   - ~/.icons"
        echo "   - ~/.local/share/icons"
        echo "   - /usr/share/icons (requires root access)"
        echo -e "\nOnce installed, rerun this script."
        exit 1
    fi

    if command -v fzf &> /dev/null; then
        selected_theme=$(printf "%s\n" "${themes[@]}" | fzf --prompt="Select a cursor theme: ")
    else
        echo ""
        PS3="Select a cursor theme by number: "
        select theme in "${themes[@]}"; do
            if [ -n "$theme" ]; then
                selected_theme="$theme"
                break
            else
                echo "Invalid selection. Try again."
            fi
        done
    fi

    selected_theme=$(echo "$selected_theme" | xargs)
    echo "$selected_theme"
}

CURSOR_THEME=$(select_cursor_theme)

echo ""
read -p "Enter cursor size (default 24): " CURSOR_SIZE
CURSOR_SIZE=${CURSOR_SIZE:-24}

echo ""
echo "You have selected:"
echo "  Cursor Theme: $CURSOR_THEME"
echo "  Cursor Size: $CURSOR_SIZE"
echo ""
read -p "Apply these changes? (y/n): " confirm
if [[ "$confirm" != [yY] ]]; then
    echo "Aborting changes."
    exit 0
fi

echo "Applying changes..."

execute() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] $@"
    else
        eval "$@"
    fi
}

# Step 3: Set cursor environment variables globally (Wayland and Hyprland)
ENV_CONF="$HOME/.config/environment.d/cursor.conf"
execute "mkdir -p \"$(dirname "$ENV_CONF")\""
execute "echo -e \"XCURSOR_THEME=$CURSOR_THEME\nXCURSOR_SIZE=$CURSOR_SIZE\" > \"$ENV_CONF\""

echo "✔️ Applied xcursor theme (Wayland environment variables)"

# Step 4: Re-exec user daemon if not running as root
echo "🔄 Re-executing user daemon to apply changes..."
execute "systemctl --user daemon-reexec"

# Step 5: Set cursor theme for GTK
GTK_CONF="$HOME/.config/gtk-3.0/settings.ini"
execute "mkdir -p \"$(dirname "$GTK_CONF")\""
execute "echo -e \"[Settings]\ngtk-cursor-theme-name = $CURSOR_THEME\ngtk-cursor-theme-size = $CURSOR_SIZE\" > \"$GTK_CONF\""

echo "✔️ Applied GTK theme settings"

# Step 6: Set cursor theme for X11
XRESOURCES="$HOME/.Xresources"
execute "echo -e \"Xcursor.theme: $CURSOR_THEME\nXcursor.size: $CURSOR_SIZE\" > \"$XRESOURCES\""
execute "xrdb -merge \"$XRESOURCES\""

echo "✔️ Applied X11 cursor theme settings"

# Step 7: Set cursor theme for Hyprland
HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPRLAND_CONF" ]; then
    if pgrep -x "Hyprland" > /dev/null; then
        execute "hyprctl --batch cursor \"$CURSOR_THEME $CURSOR_SIZE\""
        echo "✔️ Applied Hyprland settings using hyprctl"
    else
        execute "echo -e \"\ncursor=$CURSOR_THEME $CURSOR_SIZE\" >> \"$HYPRLAND_CONF\""
        echo "✔️ Applied Hyprland settings via hyprland.conf"
    fi
else
    echo "⚠️  Hyprland configuration file not found. Skipping Hyprland setup."
fi

# Step 8: Set system-wide cursor theme (if sudo is allowed)
if [ "$USE_SUDO" = true ]; then
    GLOBAL_ICON_DIR="/usr/share/icons/default"
    execute "sudo mkdir -p \"$GLOBAL_ICON_DIR\""
    execute "sudo bash -c \"echo -e '[Icon Theme]\nInherits=$CURSOR_THEME' > $GLOBAL_ICON_DIR/index.theme\""
    execute "sudo gtk-update-icon-cache /usr/share/icons/$CURSOR_THEME || true"
    echo "✔️ Applied system-wide cursor theme and updated icon cache"
else
    echo "⚠️  Skipping system-wide settings due to missing sudo privileges."
fi

echo "✔️ Cursor theme setup completed successfully!"
echo "Please restart your session or run 'systemctl --user daemon-reexec' to fully apply the changes."
