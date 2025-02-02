# 🖱️ Wayland Cursor Theme Utility

This utility is designed to **fix cross-environment cursor theming issues** by ensuring that **both client-side and server-side applications** (like Flatpak, GTK, X11, and Hyprland) are properly themed. By unifying cursor theme configurations across different environments, it ensures consistent theming for Wayland-based setups.

---

## Features
- **Fixes cross-environment inconsistencies** between Wayland, X11, GTK, Flatpak, and Hyprland.
- Detects and lists installed cursor themes from both **user-level** and **system-wide directories**.
- Applies cursor themes to **client-side applications** (e.g., GTK, Flatpak, Qt) and **server-side components** (e.g., X11 and Hyprland).
- Supports **user-specific configurations** or **system-wide settings** when run as root.
- Offers **dry-run mode** to simulate changes without applying them.

---

## Usage

### 1. Download the script:
```bash
wget https://example.com/path/to/wayland-cursor-theme-utility.sh -O cursor-utility.sh
chmod +x cursor-utility.sh
```

### 2. Run the script:
```bash
./cursor-utility.sh
```

You can also enable **dry-run mode** to see what the script would do without making any changes:
```bash
./cursor-utility.sh --dry-run
```

---

## Requirements
- **Wayland-based desktop environment** (tested on Sway, Hyprland, and GNOME).
- **fzf** (optional) – for enhanced theme selection.

---

## How It Works
1. The script scans the following directories for installed cursor themes:
   - `/usr/share/icons`
   - `~/.icons`
   - `~/.local/share/icons`
   
2. It prompts you to select a theme and specify a cursor size (default is **24**).
   
3. Depending on how you run the script:
   - If run without `sudo`, it applies configurations only at the **user level**.
   - If run as `sudo`, it applies **system-wide configurations** and updates **global icon caches**.

4. The following components are configured to maintain **theming consistency** across environments:
   - **Wayland environment variables** (via `~/.config/environment.d/cursor.conf`)
   - **GTK settings** (via `~/.config/gtk-3.0/settings.ini`)
   - **X11 settings** (via `~/.Xresources`)
   - **Hyprland cursor configuration** (if Hyprland is installed)
   - **Flatpak applications** (via `flatpak override`)
   - **Qt cursor theme settings** (if `qt5ct` is installed)

5. The script offers an option to **reboot** to apply the changes.

---

## Example Walkthrough

1. Run the script:
    ```bash
    ./cursor-utility.sh
    ```

2. Follow the prompts to select a cursor theme:
    ```
    Select a cursor theme by number: 
    1) Adwaita
    2) Breeze
    3) Bibata
    ```

3. Enter a cursor size (default is **24**):
    ```
    Enter cursor size (default 24): 32
    ```

4. Confirm your choices and let the script apply the changes:
    ```
    You have selected:
      Cursor Theme: Breeze
      Cursor Size: 32
    Apply these changes? (y/n): y
    ```

5. Optionally reboot your system:
    ```
    Would you like to reboot now? (y/n): y
    ```

---

## Handling System-Wide Settings
If you run the script without `sudo`, system-wide configurations will be skipped, but you’ll be shown the manual commands to apply them:
```
⚠️  Skipping system-wide settings due to missing root privileges.
To apply them manually, run:
  sudo mkdir -p /usr/share/icons/default
  sudo bash -c "echo -e '[Icon Theme]\nInherits=Breeze' > /usr/share/icons/default/index.theme"
  sudo gtk-update-icon-cache /usr/share/icons/Breeze
```

---

## Customization
Feel free to modify the script to fit your specific desktop environment or window manager. The script is designed to be portable and flexible for different Wayland setups.

---

## Troubleshooting
- **No cursor themes found:**  
  Ensure you have installed cursor themes in one of the following directories:
  ```
  ~/.icons
  ~/.local/share/icons
  /usr/share/icons
  ```
  You can download themes from sites like [gnome-look.org](https://www.gnome-look.org).

- **Hyprland configuration not applied:**  
  Make sure you have the correct `hyprland.conf` file located in `~/.config/hypr/`. Also, check if Hyprland is running:
  ```bash
  pgrep -x "Hyprland"
  ```

---

## Contributions
We welcome contributions! If you encounter any issues or have suggestions for improvement, feel free to submit a pull request or open an issue on our GitHub repository.

---

## License
This script is distributed under the **GNU General Public License v3.0**. See the full license [here](https://www.gnu.org/licenses/gpl-3.0.en.html).

```
Copyright (C) [Year] [Author or Organization]

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
```

You should have received a copy of the GNU General Public License along with this program. If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

---

Enjoy your **consistent cross-environment cursor theming**! 😊
