<h1 align=center>Caelestia Shell for Niri</h1>

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/irrationalpi2008-bot/niri-caelestia-shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/irrationalpi2008-bot/niri-caelestia-shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/irrationalpi2008-bot/niri-caelestia-shell?style=for-the-badge&labelColor=101418&color=d3bfe6)

</div>

> Actively maintained fork of [AyushKr2003's niri-caelestia-shell](https://github.com/AyushKr2003/niri-caelestia-shell). Kept alive for Niri users, with ongoing native C++ core optimizations and performance enhancements.

<div align=center>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

</div>

<div align=center> <h2>Screenshots</h2>

| App Launcher | Clipboard |
|:---:|:---:|
| ![App Launcher](images/screenshorts/app_launcher.png) | ![Clipboard](images/screenshorts/clipboard.png) |

| Quick Toggles | Weather |
|:---:|:---:|
| ![Quick Toggles](images/screenshorts/quicktoggles.png) | ![Weather](images/screenshorts/weather.png) |

| Niri Things | Dashboard |
|:---:|:--:|
| ![Niri Things](images/screenshorts/niriThings.png) | ![Dashboard](images/screenshorts/dashboard.png) |

</div>

> [!NOTE]
> This repo is **ONLY for the desktop shell** of the Caelestia dots for Niri. For the default Caelestia dots (Hyprland), head over to [the main Caelestia repo](https://github.com/caelestia-dots/caelestia).

---

## Features

Based on the Niri port by AyushKr2003 and jutraim, with native C++ optimizations and a unified CLI suite:

- **Core C++ Engine & Performance Optimizations**:
  - **Native Fuzzy Search**: Instant, zero-latency application filtering in `AppDb` and `CUtils` without JavaScript garbage collection pauses.
  - **In-Process Telemetry**: `/proc/cpuinfo` and `/proc/net/dev` parsed directly in C++ (`SysMonitor`), calculating CPU percentages, network download/upload rates, and sparkline history buffers in native code.
  - **Zero-Process Brightness**: Direct `/sys/class/backlight` sysfs reading, eliminating shell spawns (`brightnessctl`).
  - **Dynamic GPU Layer Gating**: MultiEffect shadow/blur shaders and background curves dynamically deactivate when drawers are closed, eliminating idle GPU compute.
  - **On-Demand Drawer Loading**: Heavy components like the Manga and Novel readers are wrapped in lazy `Loader` components to keep idle RAM minimal.
- **Unified `caelestia` CLI Suite**: Single-command control for shell functions—including launchers, screen capture, OCR, clipboard, doctor diagnostics, and updates.
- **Automated Installer**: Non-destructive installer that resolves dependencies, configures a dedicated Python venv for Material You color generation, builds C++ plugins, and verifies installation health.
- **Dynamic Material You Theming**: Live wallpaper-driven palette generation powered by `python-materialyoucolor` with 9 scheme variants, light/dark modes, and cross-app sync.
- **Screen Capture & AI Tools**: Integrated area picker for region screenshots (with Swappy editor), OCR text extraction via Tesseract, and Google Lens visual search.
- **Integrated Clipboard Manager**: Built-in clipboard history drawer backed by `cliphist` and `wl-clipboard`, with quick clear capabilities.
- **Control Center & Configuration**: Graphical settings window for appearance, fonts, themes, scaling, transparency, audio, and bluetooth, paired with structured JSON configuration (`~/.config/niri_caelestia/shell.json`).
- **Battery Monitor**: Warning notifications at configurable battery thresholds with icons, critical levels, and auto-hibernation protection.
- **Workspace Bar**: Application icons, drag-to-reorder columns, context menus, window grouping, and active window indicators.
- **System Monitor**: Real-time CPU, GPU (AMD/NVIDIA), and Memory resource monitoring with live graphs and network bandwidth tracking.
- **Built-in Readers**: Lazy-loaded Manga and Light Novel reader drawers.

---

## 📦 Dependencies

You need both runtime dependencies and development headers:

```sh
quickshell-git niri base-devel cmake ninja clang git pkg-config qt6-base qt6-declarative qt6-svg qt6-wayland cava libcava aubio wireplumber pipewire-pulse brightnessctl ddcutil playerctl libqalculate app2unit wl-clipboard cliphist grim slurp swappy tesseract tesseract-data-eng imagemagick curl jq ripgrep
```

> [!NOTE]
> Unlike the default Hyprland shell, [`caelestia-cli`](https://github.com/caelestia-dots/cli) is **not required for Niri**. Everything is powered by the built-in `caelestia` CLI suite included in this repository.

<details><summary> <b> Detailed package categorization </b></summary>

| Category | Packages |
|---|---|
| **Core & Shell** | `quickshell-git`, `niri`, `glibc`, `gcc-libs`, `qt6-base`, `qt6-declarative`, `qt6-svg`, `qt6-wayland`, `networkmanager` |
| **Audio & Visuals** | `cava`, `libcava`, `aubio`, `wireplumber`, `pipewire-pulse`, `playerctl` |
| **Hardware Control** | `brightnessctl`, `ddcutil` |
| **Colors & Theming** | `matugen-bin` (AUR), `python-materialyoucolor` (configured automatically in venv by installer) |
| **Fonts** | `ttf-material-symbols-variable-git` (or `ttf-material-icons-git`), `ttf-jetbrains-mono-nerd`, `ttf-rubik-vf` |
| **Capture & OCR** | `grim`, `slurp`, `swappy`, `tesseract`, `tesseract-data-eng`, `imagemagick` |
| **Clipboard** | `wl-clipboard`, `cliphist` |
| **Utilities & Build** | `libqalculate`, `app2unit`, `cmake`, `ninja`, `gcc`, `pkg-config`, `curl`, `jq`, `ripgrep` |

</details>

---

## Installation & Automated Setup

### Automated One-Command Installation (Arch Linux / Arch-based)

For a fully automated setup that handles package installation, Python virtual environment configuration, native C++ QML plugin compilation, initial palette generation, and CLI symlinking:

```sh
git clone https://github.com/irrationalpi2008-bot/niri-caelestia-shell
cd niri-caelestia-shell
./install.sh
```

> [!TIP]
> **Safe & Non-Destructive**: The installer will **never** overwrite or modify your personal Niri configuration (`~/.config/niri/config.kdl`).

#### Installer Options:
| Flag | Description |
| :--- | :--- |
| `--skip-deps` | Skip installing system (Pacman) and AUR packages |
| `--skip-build` | Skip compiling the native C++ QML plugin |
| `--skip-python` | Skip configuring the Python Material You virtual environment |
| `-y, --yes` | Run non-interactively without pause prompts |
| `-h, --help` | Display installer options and usage |

---

## The `caelestia` CLI Suite

The `caelestia` command is automatically symlinked into `~/.local/bin/caelestia` during installation, providing comprehensive control over every feature of the shell.

```sh
caelestia <command> [arguments...]
```

### 1. Lifecycle, Health & Maintenance
| Command | Description |
| :--- | :--- |
| `caelestia doctor` | Inspect system health, dependencies, Python venv, and C++ plugin compilation |
| `caelestia doctor --fix` (or `repair`) | Automatically diagnose and repair build artifacts, missing venv, or broken cache |
| `caelestia update` | Smart git pull, conditionally rebuild C++ plugins if changed, and reload shell |
| `caelestia status` | Display active shell instance, PID, RSS memory, compositor, and current theme |
| `caelestia start` | Launch Caelestia shell |
| `caelestia stop` | Gracefully terminate running shell instances |
| `caelestia restart` (or `reload`) | Restart the active Caelestia shell process |
| `caelestia log` | Stream live Quickshell logs in real time |
| `caelestia uninstall` | Safely clean up build artifacts, venv, state cache, and symlinks |

### 2. Live Dynamic Theming (Material You)
| Command | Description |
| :--- | :--- |
| `caelestia theme <image_path>` | Set new wallpaper and regenerate full system Material You color scheme |
| `caelestia theme <image> --mode <dark\|light>` | Set theme lightness mode (dark or light) |
| `caelestia theme <image> --variant <type>` | Choose Material 3 palette variant |
| `caelestia theme get` | Print the path of the currently active wallpaper |
| `caelestia theme list` | List available wallpapers in your wallpapers directory |

> **Available Palette Variants**: `scheme-tonal-spot` (default), `scheme-vibrant`, `scheme-expressive`, `scheme-rainbow`, `scheme-fruit-salad`, `scheme-monochrome`, `scheme-neutral`, `scheme-fidelity`, `scheme-content`.

### 3. Drawers & Navigation
| Command | Description |
| :--- | :--- |
| `caelestia launcher` | Toggle application launcher drawer (with native C++ fuzzy search) |
| `caelestia controlcenter` (or `cc`) | Open the Control Center settings window |
| `caelestia quicktoggles` (or `qt`) | Toggle the Quick Toggles panel |
| `caelestia session` | Toggle the session / power menu drawer |
| `caelestia overview` | Toggle the workspace overview drawer |
| `caelestia manga` | Toggle the built-in Manga Reader drawer |
| `caelestia novel` | Toggle the built-in Light Novel Reader drawer |
| `caelestia drawer <name>` | Toggle any drawer by name (`launcher`, `session`, `media`, `overview`, `manga`, `novel`) |

### 4. Productivity & Screen Capture Tools
| Command | Description |
| :--- | :--- |
| `caelestia capture region` (or `capture`) | Interactive region screenshot with Swappy editor |
| `caelestia capture freeze` | Freeze-screen interactive region screenshot |
| `caelestia capture ocr` (or `caelestia ocr`) | Select a region on screen to extract text directly to clipboard via Tesseract OCR |
| `caelestia capture lens` (or `caelestia lens`) | Select a screen region to perform visual search on Google Lens |
| `caelestia clipboard toggle` | Toggle the clipboard history drawer |
| `caelestia clipboard clear` | Wipe clipboard history and clear `wl-clipboard` / `cliphist` |
| `caelestia lock` | Lock your desktop via the Caelestia lockscreen |
| `caelestia dnd [toggle\|on\|off\|status]` | Toggle or set Do Not Disturb notification mode |
| `caelestia toast <title> <msg> [icon] [level]` | Send a custom on-screen notification toast (`info`, `success`, `warn`, `error`) |

### 5. Media Playback & Controls
| Command | Description |
| :--- | :--- |
| `caelestia media` | Toggle the media player drawer |
| `caelestia media play-pause` (or `play-pause`) | Toggle playback on active MPRIS player |
| `caelestia media next` (or `next`) | Skip to the next track |
| `caelestia media prev` (or `prev`) | Skip to the previous track |

### 6. Developer & Universal IPC
| Command | Description |
| :--- | :--- |
| `caelestia ipc show` | Print all live registered IPC targets and available methods in the running shell |
| `caelestia ipc <target> <function> [args...]` | Call any IpcHandler directly in the running shell |

---

### Manual Build (Alternative)

If you prefer building manually without the automated installer:

1. Install dependencies:
    ```sh
    sudo pacman -S --needed quickshell-git base-devel cmake ninja clang git pkg-config qt6-base qt6-declarative qt6-svg qt6-wayland cava libcava aubio wireplumber pipewire-pulse brightnessctl ddcutil playerctl libqalculate app2unit wl-clipboard cliphist grim slurp swappy tesseract tesseract-data-eng imagemagick curl jq ripgrep
    ```
2. Clone repository & build C++ plugins:
    ```sh
    cd ~/.config/quickshell
    git clone https://github.com/irrationalpi2008-bot/niri-caelestia-shell
    cd niri-caelestia-shell
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    cmake --build build
    ```
3. Run setup & link CLI:
    ```sh
    mkdir -p ~/.local/bin
    ln -sf "$PWD/bin/caelestia" ~/.local/bin/caelestia
    caelestia doctor --fix
    ```

---

## Usage with Niri

You can start the shell directly with `caelestia start` or via:
```sh
caelestia start
# or manually:
qs -p /path/to/niri-caelestia-shell/shell.qml
```

### Auto-start in `config.kdl`
Add this line to your `~/.config/niri/config.kdl`:
```kdl
spawn-at-startup "caelestia" "start"
```

### Blur Overview Layer Rule
To enable the blurred backdrop when overview/drawers open, add this to your `~/.config/niri/config.kdl`:
```kdl
layer-rule {
    match namespace="quickshell:Backdrop"
    place-within-backdrop true
    opacity 1.0
}
```

### Recommended Shortcuts in `config.kdl`
Using the `caelestia` CLI makes your Niri keybindings clean, readable, and robust:

```kdl
binds {
    // Shell Drawers & Menus
    Mod+Space repeat=false { spawn "caelestia" "launcher"; }
    Mod+V repeat=false     { spawn "caelestia" "clipboard" "toggle"; }
    Mod+Shift+C            { spawn "caelestia" "controlcenter"; }
    Ctrl+Alt+Delete        { spawn "caelestia" "session"; }
    Mod+Tab repeat=false   { spawn "caelestia" "overview"; }

    // Screen Capture, OCR & AI Tools
    Print                  { spawn "caelestia" "capture" "region"; }
    Mod+Shift+S            { spawn "caelestia" "capture" "freeze"; }
    Mod+Shift+O            { spawn "caelestia" "capture" "ocr"; }
    Mod+Shift+L            { spawn "caelestia" "capture" "lens"; }

    // Desktop Lock & DND
    Mod+L                  { spawn "caelestia" "lock"; }
    Mod+Shift+D            { spawn "caelestia" "dnd" "toggle"; }

    // Media Keys
    XF86AudioPlay          { spawn "caelestia" "media" "play-pause"; }
    XF86AudioNext          { spawn "caelestia" "media" "next"; }
    XF86AudioPrev          { spawn "caelestia" "media" "prev"; }
}
```

---

## Configuration

Shell configuration lives in:
```
~/.config/niri_caelestia/shell.json
```

It is managed visually through the **Control Center** (`caelestia controlcenter`), or by editing the JSON file directly.

<details><summary> <b> Complete Default JSON Schema </b></summary>

```json
{
    "appearance": {
        "rounding": {
            "scale": 1
        },
        "spacing": {
            "scale": 1
        },
        "padding": {
            "scale": 1
        },
        "font": {
            "family": {
                "sans": "Rubik",
                "mono": "JetBrains Mono Nerd Font",
                "material": "Material Symbols Rounded",
                "clock": "Rubik"
            },
            "size": {
                "scale": 1
            }
        },
        "anim": {
            "durations": {
                "scale": 1
            }
        },
        "transparency": {
            "enabled": false,
            "reduceTransparency": false,
            "base": 0.85,
            "layers": 0.4
        }
    },
    "general": {
        "isDistLogo": true,
        "apps": {
            "terminal": ["kitty"],
            "audio": ["pavucontrol"],
            "playback": ["mpv"],
            "explorer": ["thunar"]
        },
        "battery": {
            "warnLevels": [
                {
                    "level": 30,
                    "title": "Low battery",
                    "message": "You might want to plug in a charger",
                    "icon": "battery_android_frame_2"
                },
                {
                    "level": 20,
                    "title": "Did you see the previous message?",
                    "message": "You should probably plug in a charger now",
                    "icon": "battery_android_frame_1"
                },
                {
                    "level": 10,
                    "title": "Critical battery level",
                    "message": "PLUG THE CHARGER RIGHT NOW!!",
                    "icon": "battery_android_alert",
                    "critical": true
                }
            ],
            "criticalLevel": 3,
            "enableWarnings": true
        }
    },
    "background": {
        "enabled": true,
        "wallpaperEnabled": true,
        "desktopClock": {
            "enabled": true,
            "scale": 1,
            "position": "center",
            "invertColors": false,
            "background": {
                "enabled": false,
                "opacity": 0.5,
                "blur": false
            },
            "shadow": {
                "enabled": false,
                "opacity": 0.5,
                "blur": false
            }
        },
        "visualiser": {
            "enabled": false,
            "autoHide": true,
            "blur": false,
            "rounding": 1,
            "spacing": 1
        }
    },
    "bar": {
        "persistent": true,
        "showOnHover": false,
        "dragThreshold": 20,
        "scrollActions": {
            "workspaces": true,
            "volume": true,
            "brightness": true
        },
        "workspaces": {
            "shown": 4,
            "activeIndicator": true,
            "occupiedBg": true,
            "showWindows": false,
            "perMonitorWorkspaces": true,
            "windowIconImage": false,
            "windowIconGap": 5,
            "windowIconSize": 30,
            "groupIconsByApp": false,
            "groupingRespectsLayout": true,
            "focusedWindowBlob": false,
            "windowRighClickContext": true,
            "windowContextDefaultExpand": true,
            "doubleClickToCenter": true,
            "windowContextWidth": 250,
            "activeTrail": false,
            "pagerActive": true,
            "label": "◦",
            "occupiedLabel": "󰮯",
            "activeLabel": "󰮯"
        },
        "activeWindow": {
            "compact": true,
            "inverted": false
        },
        "tray": {
            "background": true,
            "compact": false,
            "recolour": false,
            "iconSubs": []
        },
        "status": {
            "showAudio": false,
            "showMicrophone": false,
            "showKbLayout": false,
            "showNetwork": true,
            "showWifi": true,
            "showBluetooth": true,
            "showBattery": true,
            "showLockStatus": true
        },
        "clock": {
            "background": true,
            "showDate": true,
            "showIcon": true
        },
        "popouts": {
            "tray": true,
            "statusIcons": true
        },
        "sizes": {
            "innerWidth": 40,
            "windowPreviewSize": 400,
            "trayMenuWidth": 300,
            "batteryWidth": 250,
            "networkWidth": 320
        },
        "entries": [
            { "id": "logo", "enabled": true },
            { "id": "workspaces", "enabled": true },
            { "id": "spacer", "enabled": true },
            { "id": "activeWindow", "enabled": true },
            { "id": "spacer", "enabled": true },
            { "id": "tray", "enabled": true },
            { "id": "divider", "enabled": true },
            { "id": "clock", "enabled": true },
            { "id": "statusIcons", "enabled": true },
            { "id": "divider", "enabled": true },
            { "id": "power", "enabled": true },
            { "id": "idleInhibitor", "enabled": false }
        ]
    },
    "border": {
        "thickness": 5,
        "rounding": 25
    },
    "dashboard": {
        "enabled": true,
        "showOnHover": true,
        "useWallpaperAvatar": true,
        "mediaUpdateInterval": 500,
        "resourceUpdateInterval": 1000,
        "dragThreshold": 50,
        "updateInterval": 1000,
        "performance": {
            "showBattery": true,
            "showGpu": true,
            "showCpu": true,
            "showMemory": true,
            "showStorage": true,
            "showNetwork": true
        }
    },
    "controlCenter": {
        "sizes": {
            "heightMult": 0.7,
            "ratio": 1.7778
        }
    },
    "launcher": {
        "enabled": true,
        "showOnHover": false,
        "maxShown": 8,
        "maxWallpapers": 9,
        "specialPrefix": "@",
        "actionPrefix": ">",
        "enableDangerousActions": false,
        "dragThreshold": 50,
        "vimKeybinds": false,
        "favouriteApps": [],
        "hiddenApps": [],
        "useFuzzy": {
            "apps": false,
            "actions": false,
            "schemes": false,
            "variants": false,
            "wallpapers": false
        },
        "sizes": {
            "itemWidth": 600,
            "itemHeight": 57,
            "wallpaperWidth": 280,
            "wallpaperHeight": 200
        }
    },
    "notifs": {
        "expire": true,
        "defaultExpireTimeout": 5000,
        "clearThreshold": 0.3,
        "expandThreshold": 20,
        "actionOnClick": false,
        "groupPreviewNum": 3,
        "sizes": {
            "width": 400,
            "image": 41,
            "badge": 20
        }
    },
    "osd": {
        "enabled": true,
        "hideDelay": 2000,
        "enableBrightness": true,
        "enableMicrophone": false,
        "sizes": {
            "sliderWidth": 30,
            "sliderHeight": 150
        }
    },
    "session": {
        "enabled": true,
        "dragThreshold": 30,
        "vimKeybinds": false,
        "commands": {
            "logout": ["niri", "msg", "action", "quit", "-s"],
            "shutdown": ["systemctl", "poweroff"],
            "hibernate": ["systemctl", "hibernate"],
            "reboot": ["systemctl", "reboot"]
        },
        "sizes": {
            "button": 80
        }
    },
    "lock": {
        "recolourLogo": false,
        "enableFprint": true,
        "showExtras": true,
        "maxFprintTries": 3,
        "sizes": {
            "heightMult": 0.7,
            "ratio": 1.7778,
            "centerWidth": 600
        }
    },
    "utilities": {
        "enabled": true,
        "maxToasts": 4,
        "sizes": {
            "width": 430,
            "toastWidth": 430
        },
        "toasts": {
            "configLoaded": true,
            "chargingChanged": true,
            "gameModeChanged": true,
            "dndChanged": true,
            "audioOutputChanged": true,
            "audioInputChanged": true,
            "capsLockChanged": true,
            "numLockChanged": true,
            "kbLayoutChanged": true,
            "kbLimit": true,
            "vpnChanged": true,
            "nowPlaying": false
        },
        "vpn": {
            "enabled": false,
            "provider": []
        }
    },
    "services": {
        "weatherLocation": "",
        "useFahrenheit": false,
        "useTwelveHourClock": true,
        "gpuType": "",
        "visualiserBars": 24,
        "audioIncrement": 0.1,
        "smartScheme": true,
        "defaultPlayer": "Spotify",
        "playerAliases": [
            {
                "from": "com.github.th_ch.youtube_music",
                "to": "YT Music"
            }
        ],
        "toasts": {
            "configLoaded": true,
            "configError": true
        }
    },
    "paths": {
        "wallpaperDir": "~/Pictures/Wallpapers",
        "wallpaper": "",
        "sessionGif": "root:/assets/kurukuru.gif",
        "mediaGif": "root:/assets/bongocat.gif"
    },
    "extra": {
        "manga": true,
        "novel": true
    }
}
```

</details>

### Profile Picture & Wallpapers
The profile picture for the dashboard is read from the file `~/.face`. To set it, place your image there or set it via the dashboard settings.

The wallpapers for the wallpaper switcher are read from `~/Pictures/Wallpapers` by default. To change this path, update `"wallpaperDir"` in `~/.config/niri_caelestia/shell.json`.

---

## Known Issues

1. System monitor GPU metrics currently support AMD and NVIDIA GPUs.
2. Focus grabbing for Quickshell popup windows behaves differently due to Wayland/Niri protocol characteristics.
3. Upstream Quickshell bugs may occasionally trigger a shell restart.

---

## Credits

* [AyushKr2003/niri-caelestia-shell](https://github.com/AyushKr2003/niri-caelestia-shell) – The original Niri fork and features this project builds upon
* [Quickshell](https://github.com/quickshell/quickshell) – Core shell framework
* [Caelestia](https://github.com/caelestia-shell/caelestia-shell) – Original shell project
* [jutraim/niri-caelestia-shell](https://github.com/jutraim/niri-caelestia-shell) – Initial Niri adaptation
* [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) – Feature ideas and design inspirations
* [Niri](https://github.com/YaLTeR/niri) – Scrollable-tiling Wayland compositor
* All upstream contributors :)

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=irrationalpi2008-bot/niri-caelestia-shell&type=Date)](https://star-history.com/#irrationalpi2008-bot/niri-caelestia-shell&Date)
