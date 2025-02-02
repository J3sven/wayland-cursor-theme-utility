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

# Step 1: Determine the correct home directory (in case of sudo) and scan for themes
if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    ORIGINAL_HOME=$(eval echo "~$SUDO_USER")
    ORIGINAL_HOME=$HOME
fi

ROOT_REQUIRED=false
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  You are not running the script as root."
    echo "Some system-wide settings will require root privileges."
    echo ""
    read -p "Would you like to restart the script as sudo for system-wide settings? (y/n): " use_sudo
    if [[ "$use_sudo" == [yY] ]]; then
        echo "Restarting the script with sudo..."
        exec sudo bash "$0" "$@"
    else
        echo "Continuing with user-specific configurations only."
    fi
else
    ROOT_REQUIRED=true
fi

echo "This script configures cursor themes on Wayland systems."
echo "--------------------------------------"
echo ""
read -p "Press Enter to continue to theme selection... "

list_cursor_themes() {
    local themes=()
    local theme_dirs=("/usr/share/icons" "$ORIGINAL_HOME/.icons" "$ORIGINAL_HOME/.local/share/icons")

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

# Step 2: Set cursor environment variables globally (Wayland and Hyprland)
ENV_CONF="${ORIGINAL_HOME}/.config/environment.d/cursor.conf"
execute "mkdir -p \"$(dirname "$ENV_CONF")\""
execute "echo -e \"XCURSOR_THEME=$CURSOR_THEME\nXCURSOR_SIZE=$CURSOR_SIZE\" > \"$ENV_CONF\""

echo "✔️ Applied xcursor theme (Wayland environment variables)"

execute "systemctl --user daemon-reexec"

# Step 3: Set cursor theme for GTK (Wayland and X11)
GTK_CONF="${ORIGINAL_HOME}/.config/gtk-3.0/settings.ini"
execute "mkdir -p \"$(dirname "$GTK_CONF")\""
execute "echo -e \"[Settings]\ngtk-cursor-theme-name = $CURSOR_THEME\ngtk-cursor-theme-size = $CURSOR_SIZE\" > \"$GTK_CONF\""

echo "✔️ Applied GTK theme settings"

# Step 4: Set cursor theme for X11 (XWayland)
XRESOURCES="${ORIGINAL_HOME}/.Xresources"
execute "echo -e \"Xcursor.theme: $CURSOR_THEME\nXcursor.size: $CURSOR_SIZE\" > \"$XRESOURCES\""
execute "xrdb -merge \"$XRESOURCES\""

echo "✔️ Applied X11 cursor theme settings"

# Step 5: Set cursor theme for Hyprland
HYPRLAND_CONF="${ORIGINAL_HOME}/.config/hypr/hyprland.conf"
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

# Step 6: Set system-wide cursor theme (only if root privileges are available)
if [ "$ROOT_REQUIRED" = true ]; then
    GLOBAL_ICON_DIR="/usr/share/icons/default"
    execute "mkdir -p \"$GLOBAL_ICON_DIR\""
    execute "bash -c \"echo -e '[Icon Theme]\nInherits=$CURSOR_THEME' > $GLOBAL_ICON_DIR/index.theme\""
    execute "gtk-update-icon-cache /usr/share/icons/$CURSOR_THEME || true"
    echo "✔️ Applied system-wide cursor theme and updated icon cache"
else
    echo "⚠️  Skipping system-wide settings due to missing root privileges."
fi

echo "✔️ Cursor theme setup completed successfully!"

if [[ "$reboot_choice" == [yY] ]]; then
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Simulating reboot... (No actual reboot will occur)"
    else
        echo "Rebooting the system..."
        if [ "$EUID" -eq 0 ]; then
            reboot
        else
            sudo reboot
        fi
    fi
else
    echo "Reboot skipped. Please reboot manually to apply changes."
fi
