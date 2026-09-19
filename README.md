<h1 align=center>Caelestia Shell for Niri</h1>

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/irrationalpi2008-bot/niri-caelestia-shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/irrationalpi2008-bot/niri-caelestia-shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/irrationalpi2008-bot/niri-caelestia-shell?style=for-the-badge&labelColor=101418&color=d3bfe6)

</div>

> Actively maintained fork of [AyushKr2003's niri-caelestia-shell](https://github.com/AyushKr2003/niri-caelestia-shell). Kept alive for Niri users, with ongoing C++ core optimizations.

<div align=center>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

</div>

<div align=center> <h2> Screenshots (OLD)</h2>

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

- **Core C++ Engine Optimizations**:
  - **Native Fuzzy Search**: Instant, zero-latency application filtering in `AppDb` and `CUtils` without JavaScript garbage collection pauses.
  - **In-Process Telemetry**: `/proc/cpuinfo` and `/proc/net/dev` parsed directly in C++ (`SysMonitor`), calculating CPU percentages, network download/upload rates, and sparkline history ring buffers in native code.
  - **Zero-Process Brightness**: Direct `/sys/class/backlight` sysfs reading, eliminating shell spawns (`sh -c echo $(brightnessctl ...)`).
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

You need both runtime dependencies and development headers.

<br>

* All dependencies in plain text:
   * `quickshell-git networkmanager fish glibc qt6-declarative gcc-libs cava libcava aubio libpipewire ddcutil brightnessctl ttf-material-icons-git ttf-jetbrains-mono grim swappy app2unit libqalculate python-materialyoucolor wl-clipboard cliphist tesseract tesseract-data-eng curl jq`

> [!NOTE]
> Unlike the default Hyprland shell, [`caelestia-cli`](https://github.com/caelestia-dots/cli) is **not required for Niri**. Everything is powered by the built-in `caelestia` CLI suite included in this repository.

<details><summary> <b> Detailed info about all dependencies </b></summary>

<div align=center>

| Category | Packages |
|---|---|
| Core | `quickshell-git`, `networkmanager`, `networkmanager-qt`, `fish`, `glibc`, `qt6-declarative`, `gcc-libs` |
| Audio & Visual | `cava`, `libcava`, `aubio`, `libpipewire`, `ddcutil`, `brightnessctl`, `materialyoucolor` |
| Fonts | `ttf-material-icons-git`, `ttf-jetbrains-mono` |
| Screenshot & Utils | `grim`, `swappy`, `app2unit`, `libqalculate`, `tesseract`, `tesseract-data-eng`, `curl`, `jq` |
| Clipboard | `wl-clipboard`, `cliphist` |
| Build | `cmake`, `ninja`, `gcc` |

</div>

### Manual installation

To install the shell manually, install all dependencies and clone this repo to `~/.config/quickshell/niri-caelestia-shell`.
Then simply build and install using `cmake`.

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
    sudo pacman -S --needed quickshell-git networkmanager fish glibc qt6-declarative gcc-libs cava libcava aubio libpipewire ddcutil brightnessctl ttf-jetbrains-mono grim swappy app2unit libqalculate wl-clipboard cliphist tesseract tesseract-data-eng curl jq cmake ninja gcc
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
qs -c niri-caelestia-shell
# or:
qs -p /path/to/niri-caelestia-shell/shell.qml
```

### Auto-start in `config.kdl`
Add this line to your `~/.config/niri/config.kdl`:
```kdl
spawn-at-startup "caelestia" "start"
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

    // Screen Capture & AI Tools
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

<details><summary> <b> Raw Low-Level IPC Commands & Targets Reference </b></summary>

```sh
❯ caelestia ipc show
target picker
    function open(): void
    function openFreeze(): void
    function regionOcr(): void
    function regionSearch(): void
  target quicktoggles
    function open(): void
    function toggle(): void
    function close(): void
  target idleInhibitor
    function toggle(): void
    function enable(): void
    function isEnabled(): bool
    function disable(): void
  target wallpaper
    function get(): string
    function set(path: string): void
    function list(): string
  target clipboard
    function open(): void
    function toggle(): void
    function close(): void
  target drawers
    function toggle(drawer: string): void
    function list(): string
  target controlCenter
    function open(): void
  target toaster
    function info(title: string, message: string, icon: string): void
    function success(title: string, message: string, icon: string): void
    function warn(title: string, message: string, icon: string): void
    function error(title: string, message: string, icon: string): void
  target lock
    function isLocked(): bool
    function lock(): void
    function unlock(): void
  target mpris
    function playPause(): void
    function pause(): void
    function getActive(prop: string): string
    function play(): void
    function next(): void
    function list(): string
    function stop(): void
    function previous(): void
  target notifs
    function clear(): void
  target brightness
    function setFor(query: string, value: string): string
    function get(): real
    function set(value: string): string
    function getFor(query: string): real
  ```

</details>

## If you want blur overview add this in your NIRI config
```kdl

layer-rule {
    match namespace="quickshell:Backdrop"
    place-within-backdrop true
    opacity 1.0
}
````

<details><summary> <b> Example Niri config.kdl </b></summary>

```kdl
// Startup commands
spawn-sh-at-startup "wl-paste --type text --watch cliphist store &"
spawn-sh-at-startup "wl-paste --type image --watch cliphist store &"
spawn-at-startup "caelestia" "start"

environment {
    XDG_CURRENT_DESKTOP "niri"
    XDG_MENU_PREFIX "plasma-"  // Required for Dolphin file associations
    QT_QPA_PLATFORM "wayland"
    ELECTRON_OZONE_PLATFORM_HINT "auto"
    QT_QPA_PLATFORMTHEME "kde"
    QT_STYLE_OVERRIDE "Darkly"
}

binds {
    // System
    Mod+Tab repeat=false { toggle-overview; }
    Mod+Shift+E { quit; }
    Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
    
    // Launcher
    Mod+Space repeat=false { spawn "caelestia" "launcher"; }
    
    // Clipboard
    Mod+V repeat=false { spawn "caelestia" "clipboard" "toggle"; } 

    // Control Center
    Mod+Shift+C { spawn "caelestia" "controlcenter"; }
    
    // Lock screen
    Mod+L { spawn "caelestia" "lock"; }
    
    // Region/Screenshot tools
    Mod+Shift+S { spawn "caelestia" "capture" "region"; }
    
    // OCR (extract text from screen region)
    Mod+Shift+X { spawn "caelestia" "capture" "ocr"; }
    
    // Google Lens (visual search from screen region)
    Mod+Shift+A { spawn "caelestia" "capture" "lens"; }
    
    // Applications (change "kitty" to your preferred terminal)
    Mod+T { spawn "kitty"; }
    Mod+Return { spawn "kitty"; }
    Super+E { spawn "dolphin"; }
    
    // Window management
    Mod+Q repeat=false { close-window; }
    Mod+D { maximize-column; }
    Mod+F { fullscreen-window; }
    Mod+Alt+Space { toggle-window-floating; }

    // Screenshots (native)
    Print { screenshot; }
    Ctrl+Print { screenshot-screen; }
    Alt+Print { screenshot-window; }
    
    // ========================================================================
    // HARDWARE KEYS - Audio, Brightness, Media
    // ========================================================================
    
    // Volume (hardware keys)
    XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; }
    XF86AudioMute allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
    XF86AudioMicMute allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

    // Media keys
    XF86AudioPlay { spawn "caelestia" "media" "play-pause"; }
    XF86AudioNext { spawn "caelestia" "media" "next"; }
    XF86AudioPrev { spawn "caelestia" "media" "prev"; }

    // Brightness (hardware keys) - change eDP-1 to your monitor name by running "niri msg outputs"
    XF86MonBrightnessUp { spawn "caelestia" "ipc" "brightness" "setFor" "eDP-1" "+5%"; }
    XF86MonBrightnessDown { spawn "caelestia" "ipc" "brightness" "setFor" "eDP-1" "10%-"; }
    
    // Session/Power menu
    Ctrl+Alt+Delete { spawn "caelestia" "session"; }
}

layer-rule {
    match namespace="quickshell:Backdrop"
    place-within-backdrop true
    opacity 1.0
}
```

</details>

---

## Configuration

Config lives in:

```
~/.config/niri_caelestia/shell.json
```
<details><summary> <b> Example JSON </b></summary>

```json
{
    "appearance": {
        "anim": {
            "durations": {
                "scale": 1
            }
        },
        "font": {
            "family": {
                "clock": "Rubik",
                "material": "Material Symbols Rounded",
                "mono": "JetBrains Mono Nerd Font",
                "sans": "Rubik"
            },
            "size": {
                "scale": 1
            }
        },
        "padding": {
            "scale": 1
        },
        "rounding": {
            "scale": 1
        },
        "spacing": {
            "scale": 1
        },
        "transparency": {
            "enabled": false,
            "base": 0.85,
            "layers": 0.4
        }
    },
    "general": {
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
                    "message": "You should probably plug in a charger <b>now</b>",
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
            "criticalLevel": 3
        },
        "idle": {
            "lockBeforeSleep": true,
            "inhibitWhenAudio": true,
            "timeouts": [
                {
                    "timeout": 180,
                    "idleAction": "lock"
                },
                {
                    "timeout": 300,
                    "idleAction": "dpms off",
                    "returnAction": "dpms on"
                },
                {
                    "timeout": 600,
                    "idleAction": ["systemctl", "suspend-then-hibernate"]
                }
            ]
        }
    },
    "background": {
        "desktopClock": {
            "enabled": true
        },
        "enabled": true,
        "visualiser": {
            "blur": false,
            "enabled": false,
            "autoHide": true,
            "rounding": 1,
            "spacing": 1
        }
    },
    "bar": {
        "clock": {
            "showIcon": true
        },
        "dragThreshold": 20,
        "entries": [
            {
                "id": "logo",
                "enabled": true
            },
            {
                "id": "workspaces",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "activeWindow",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "tray",
                "enabled": true
            },
            {
                "id": "clock",
                "enabled": true
            },
            {
                "id": "statusIcons",
                "enabled": true
            },
            {
                "id": "power",
                "enabled": true
            }
        ],
        "persistent": true,
        "popouts": {
            "activeWindow": true,
            "statusIcons": true,
            "tray": true
        },
        "scrollActions": {
            "brightness": true,
            "workspaces": true,
            "volume": true
        },
        "showOnHover": true,
        "status": {
            "showAudio": false,
            "showBattery": true,
            "showBluetooth": true,
            "showKbLayout": false,
            "showMicrophone": false,
            "showNetwork": true,
            "showLockStatus": true
        },
        "tray": {
            "background": false,
            "compact": false,
            "iconSubs": [],
            "recolour": false
        },
        "workspaces": {
            "label": "  ",
            
            
            "activeIndicator": true,
            "activeLabel": "󰮯",
            "activeTrail": false,
            "groupIconsByApp": true,
            "groupingRespectsLayout": false,
            "windowRighClickContext": true,
            "label": "⊙",
            "occupiedBg": true,
            "occupiedLabel": "󰮯",
            "showWindows": false,
            "shown": 4,
            "windowIconImage": false,
            "focusedWindowBlob": false,
            "windowIconGap": 0,
            "windowIconSize": 30
        },
        "excludedScreens": [""],
        "activeWindow": {
            "inverted": false
        }
    },
    "border": {
        "rounding": 10,
        "thickness": 10
    },
    "dashboard": {
        "enabled": true,
        "dragThreshold": 50,
        "mediaUpdateInterval": 500,
        "showOnHover": true
    },
    "launcher": {
        "actionPrefix": ">",
        "dragThreshold": 50,
    // ...existing code...
        "enableDangerousActions": false,
        "maxShown": 8,
        "maxWallpapers": 9,
        "specialPrefix": "@",
        "useFuzzy": {
            "apps": false,
            "actions": false,
            "schemes": false,
            "variants": false,
            "wallpapers": false
        },
        "showOnHover": false
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
    "notifs": {
        "actionOnClick": false,
        "clearThreshold": 0.3,
        "defaultExpireTimeout": 5000,
        "expandThreshold": 20,
        "openExpanded": false,
        "expire": true
    },
    "osd": {
        "enabled": true,
        "enableBrightness": true,
        "enableMicrophone": false,
        "hideDelay": 2000
    },
    "paths": {
        "mediaGif": "root:/assets/bongocat.gif",
        "sessionGif": "root:/assets/kurukuru.gif",
        "wallpaperDir": "~/Pictures/Wallpapers",
        "wallpaper": "~/Pictures/Wallpapers/default.jpg"
    },
    "services": {
        "audioIncrement": 0.1,
        "maxVolume": 1.0,
        "defaultPlayer": "Spotify",
        "gpuType": "",
        "playerAliases": [{ "from": "com.github.th_ch.youtube_music", "to": "YT Music" }],
        "weatherLocation": "New York",
        "useFahrenheit": false,
        "useTwelveHourClock": true,
        "smartScheme": true,
        "visualiserBars": 45
    },
    "session": {
        "dragThreshold": 30,
        "enabled": true,
        "vimKeybinds": false,
        "commands": {
            "logout": ["loginctl", "terminate-user", ""],
            "shutdown": ["systemctl", "poweroff"],
            "hibernate": ["systemctl", "hibernate"],
            "reboot": ["systemctl", "reboot"]
        }
    },
    "sidebar": {
        "dragThreshold": 80,
        "enabled": true
    },
    "utilities": {
        "enabled": true,
        "maxToasts": 4,
        "toasts": {
            "audioInputChanged": true,
            "audioOutputChanged": true,
            "capsLockChanged": true,
            "chargingChanged": true,
            "configLoaded": true,
            "dndChanged": true,
            "gameModeChanged": true,
            "kbLayoutChanged": true,
            "numLockChanged": true,
            "vpnChanged": true,
            "nowPlaying": false
        },
        "vpn": {
            "enabled": false,
            "provider": [
                {
                    "name": "wireguard",
                    "interface": "your-connection-name",
                    "displayName": "Wireguard (Your VPN)"
                }
            ]
        }
    }
}

```

</details>

<details><summary> <b> Example Nix Home Manager </b></summary>

I don't have nix, plz help :D

```nix
{
  programs.niri-caelestia-shell = {
    enable = true;
    with-cli = true;
    settings.theme.accent = "#ffb86c";
  };
}
```

</details>

### Profile Picture & Wallpapers
The profile picture for the dashboard is read from the file `~/.face`, so to set
it you can copy your image to there or set it via the dashboard. **It's not a directory.**

The wallpapers for the wallpaper switcher are read from `~/Pictures/Wallpapers`
by default. To change it, change the wallpapers path in `~/.config/niri_caelestia/shell.json`.

To set the wallpaper, you can use the app launcher command `> wallpaper`.


---

## Known Issues

1. Task manager has no Intel GPU support (AMD/NVIDIA only)
2. Focus grabbing for Quickshell windows behaves awkwardly due to Niri limitations
3. Quickshell may occasionally crash due to upstream issues (auto-restarts)


---

## Credits

* [AyushKr2003/niri-caelestia-shell](https://github.com/AyushKr2003/niri-caelestia-shell) – The original niri fork and awesome features this project builds upon
* [Quickshell](https://github.com/quickshell/quickshell) – Core shell framework
* [Caelestia](https://github.com/caelestia-shell/caelestia-shell) – Original project
* [jutraim/niri-caelestia-shell](https://github.com/jutraim/niri-caelestia-shell) – Initial Niri adaptation
* [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) – Many features and ideas inspired from
* [Niri](https://github.com/YaLTeR/niri) – Window manager backend
* All upstream contributors :)

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=irrationalpi2008-bot/niri-caelestia-shell\&type=Date)](https://star-history.com/#irrationalpi2008-bot/niri-caelestia-shell&Date)
