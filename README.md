# Niri + Noctalia Dotfiles

Полный набор конфигураций для **niri** (scrollable-tiling Wayland compositor) с **Noctalia Shell** — прозрачность, blur, темы, плагины, аудио-цепочка, автостарт.

**Система-источник:** CachyOS (Arch) · niri 26.04 · Noctalia 5.3.0 · AMD RX 6650 XT · Ryzen 5 8600G

---

## Быстрый старт

```bash
git clone https://github.com/Romalakino/niri-dotfiles.git
cd niri-dotfiles
chmod +x install.sh
./install.sh --dry-run   # preview
./install.sh             # deploy
```

---

## Структура репозитория

```
config/
├── niri/                    # основной конфиг композитора
│   ├── config.kdl           # entry point (include диспетчер)
│   ├── noctalia.kdl         # автогенерируемые цвета темы
│   └── cfg/
│       ├── animation.kdl    # анимации (spring, quad-bezier)
│       ├── autostart.kdl    # автозапуск (noctalia, easyeffects, mpvpaper, waydroid)
│       ├── display.kdl      # монитор (имя, разрешение, частота, scale)
│       ├── input.kdl        # клавиатура (us,ru), тачпад, курсор
│       ├── keybinds.kdl     # все хоткеи (vim-стиль, медиа, workspaces)
│       ├── layout.kdl       # gaps, transparency, preset widths
│       ├── misc.kdl         # blur, env vars, cursor theme
│       └── rules.kdl        # window/layer rules (radius, blur, floating)
├── noctalia/
│   └── config.toml          # polkit agent, wallpaper toggle
├── alacritty/               # терминал (opacity=0.8)
├── kitty/                   # тема (noctalia-generated)
├── foot/                    # тема
├── btop/                    # тема
├── easyeffects/db/          # аудио-плагины (EQ, bass, compressor, limiter, etc.)
├── fish/config.fish         # шелл
├── systemd/user/            # ruh-local-proxy.service/.path
└── user-dirs.dirs           # XDG directories (русские имена)

local/
├── bin/                     # скрипты (wallpaper-anim, waydroid-session, recorder-rename)
├── state/noctalia/          # ★ settings.toml — ВСЯ прозрачность/blur/плагины/тема
│   ├── settings.toml
│   └── state.toml
├── share/easyeffects/output/ # 8 EQ-пресетов (vlad-eq-*.json)
└── share/applications/      # кастомные .desktop файлы

noctalia-plugins/            # ★ собственные плагины (vlad-dev source)
├── equalizer/               # Luau: panel + widget + shortcut + eqctl + presets
├── ruh-vpn/                 # Python: sing-box backend + HTTP API + UI
└── timer/                   # Luau: timer panel plugin
```

---

## Прозрачность и Blur

Прозрачность достигается комбинацией **трёх** слоёв:

### 1. Niri (compositor level)
```kdl
// layout.kdl — фон композитора прозрачный, под ним wallpaper
background-color "transparent"

// misc.kdl — глобальный blur shader
blur {
    passes 3
    offset 3.5
    noise 0.03
    saturation 1.0
}

// rules.kdl — размытие для всех окон
window-rule {
    background-effect { blur true  xray false }
}

// rules.kdl — layer shell (бар, панель, OSD) тоже blur
layer-rule {
    match namespace="^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$"
    background-effect { xray false }
}
```

### 2. Noctalia Shell (UI level)
```toml
# ~/.local/state/noctalia/settings.toml
[backdrop]
blur_intensity = 0.0          # niri already does the blurring
tint_intensity = 0.0

[bar.default]
background_opacity = 0.55
compositor_blur = true        # delegate blur to niri

[shell.panel]
transparency_mode = "glass"   # frosted glass effect
```

### 3. Терминал (Alacritty)
```toml
# alacritty.toml
[window]
opacity = 0.8
```

### Итого для переноса
- `background-color "transparent"` — без этой строки wallpaper не виден
- `blur { ... }` + `background-effect { blur true }` — стекло за окнами
- `compositor_blur = true` в noctalia — бар не размывает сам, просит niri
- `transparency_mode = "glass"` — панель/локскрин с эффектом стекла

---

## Плагины Noctalia

### Официальные (auto-download)
| Плагин | Функция |
|--------|---------|
| `noctalia/mpvpaper` | Video wallpaper |
| `noctalia/screen_recorder` | HEVC запись (gpu-screen-recorder) |
| `noctalia/notes` | Sticky notes |
| `noctalia/timer` | Timer widget |
| `noctalia/wallhaven` | Wallhaven browser |

### Community
| Плагин | Функция |
|--------|---------|
| `kenn/keybind-cheatsheet` | Shown in bar center |
| `vn1k/cursor` | Cursor effects |

### Собственные (`vlad-dev` path source → `~/dev/noctalia-plugins/`)
| Плагин | Зависимости |
|--------|-------------|
| `equalizer` | easyeffects, lsp-plugins, python3, luau |
| `ruh-vpn` | sing-box, python 3.14, systemd units |
| `timer` | — (pure Luau) |

> **Важно:** путь `~/dev/noctalia-plugins` должен существовать — в `settings.toml` он указан как `kind = "path"` source. Без него 3 плагина исчезнут.

---

## Необходимые пакеты

### Core (обязательно)
```bash
sudo pacman -S --needed \
  niri noctalia \
  alacritty \
  grim slurp \
  mpvpaper \
  gpu-screen-recorder \
  easyeffects lsp-plugins \
  pipewire pipewire-alsa pipewire-pulse wireplumber \
  xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
  gnome-keyring \
  sddm \
  luau
```

### Fonts & Cursors
```bash
sudo pacman -S --needed \
  ttf-meslo-nerd \
  awesome-terminal-fonts \
  noto-fonts noto-fonts-cjk noto-fonts-emoji \
  ttf-font-awesome
# capitaine-cursors — из AUR:
yay -S capitaine-cursors
```

### GPU (AMD)
```bash
sudo pacman -S --needed \
  vulkan-radeon lib32-vulkan-radeon \
  xf86-video-amdgpu mesa mesa-utils \
  amd-ucode
```

### Optional
```bash
# Waydroid (Android in container)
sudo pacman -S waydroid waydroid-image

# sing-box (for ruh-vpn plugin)
sudo pacman -S sing-box

# Flatpak apps
flatpak install org.gnome.Platform//51 org.gnome.TextEditor

# GTK theme
yay -S adw-gtk3-dark
```

### CachyOS metapackage (альтернатива ручной установке)
```bash
sudo pacman -S cachyos-niri-noctalia
```
Ставит `/etc/skel/.config/{niri,noctalia}` скелет. После установки дотфайлов из этого репо скелет будет перезаписан.

---

## Перенос на другую систему — пошагово

### 1. Установка базовой системы
- **Рекомендуемый дистрибутив:** Arch / CachyOS / EndeavourOS (niri + noctalia есть в pacman)
- Для других: niri собирается из исходников (Rust + meson), noctalia — flatpak или AUR
- Файловая система btrfs (опционально, для снапшотов)

### 2. Установка пакетов
```bash
# см. секцию «Необходимые пакеты» выше
```

### 3. Развёртывание дотфайлов
```bash
git clone https://github.com/Romalakino/niri-dotfiles.git ~/niri-dotfiles
cd ~/niri-dotfiles
chmod +x install.sh
./install.sh
```

### 4. Настройка монитора
Отредактировать `~/.config/niri/cfg/display.kdl`:
```kdl
output "DP-2" {              // ← имя вашего выхода (niri msg outputs)
    mode "1920x1080@240.003" // ← разрешение@частота
    scale 1                   // ← DPI scaling
}
```
Узнать имя: `niri msg outputs` или `wlr-randr`

### 5. Настройка wallpaper
Если используете видео:
- Положить `.mp4` в `~/Изображения/Wallpapers/` (или свой путь)
- Отредактировать `~/.config/niri/cfg/autostart.kdl` — путь к видео

Если только изображение:
- В Noctalia: `Super+Shift+Enter` (wallpaper selector) или через Wallhaven plugin

### 6. systemd units (VPN)
```bash
systemctl --user daemon-reload
systemctl --user enable --now ruh-local-proxy
systemctl --user enable --now ruh-local-proxy-reload.path
```

### 7. Перелогин
Выйти из сессии → SDDM → выбрать "niri" → войти.

Или без перелога:
```bash
niri msg action load-config-file
```

---

## Привязки клавиш (шпаргалка)

| Хоткей | Действие |
|--------|----------|
| `Super` | niri (модификатор) |
| `Super+Enter` | Alacritty |
| `Super+F` | Firefox |
| `Super+N` | Nautilus |
| `Super+Space` | Noctalia launcher |
| `Super+S` | Control Center |
| `Super+V` | Clipboard history |
| `Super+Shift+Enter` | Wallpaper selector |
| `Super+A` | Waydroid (ArchiveTune) |
| `Super+Shift+G` | Quadra ESP toggle |
| `Super+Shift+E` | Equalizer panel |
| `Super+Shift+V` | RUH VPN |
| `Super+Alt+L` | Lock screen |
| `Super+Shift+Q` | Session menu |
| `Super+O` | Window overview |
| `Super+H/J/K/L` | Focus (vim) |
| `Super+Shift+H/J/K/L` | Move window |
| `Super+1..9` | Workspace |
| `Super+Ctrl+1..9` | Move to workspace |
| `Super+Esc` | Allow/Disallow inhibit |
| `Super+Shift+P` | Power off monitors |
| `Ctrl+Alt+Del` | Quit niri |
| `Print` | Screenshot (noctalia) |
| Media keys | Volume/brightness via noctalia OSD |

---

## Themes & Colors

Единая палитра **Ayu/Noctalia** используется везде:
| Роль | HEX |
|------|-----|
| Background | `#131315` |
| Foreground | `#e5e1e4` |
| Accent | `#c2c4e8` |
| Pink | `#e4bad5` |
| Red/Urgent | `#ffb4ab` |
| Muted | `#46464d` |

Тема генерируется Noctalia из обоев (`[theme] source = "wallpaper"`). Файлы `noctalia.toml`/`noctalia.conf` в alacritty/kitty/foot/btop — автогенерируемые шаблоны. Ручная правка: только grayscale override в `alacritty.toml` (секция `[colors.primary]`).

---

## Важные замечания при миграции

1. **Пути в конфигах абсолютные** (`/home/vlad/...`) — если у вас другой username, замените во всех файлах:
   ```bash
   grep -rl "/home/vlad" ~/.config/niri ~/.local/state/noctalia ~/.local/bin | \
     xargs sed -i 's|/home/vlad|/home/YOUR_USER|g'
   ```

2. **XDG directories** используют русские имена (`Изображения`, `Видео`). Либо создайте их, либо измените `~/.config/user-dirs.dirs` и все пути в конфигах.

3. **`noctalia.kdl`** — генерируется при смене wallpaper. Не нужно редактировать руками.

4. **Alacritty `opacity = 0.8`** работает только если niri не в `xray` режиме (а у нас `xray false`).

5. **Waydroid** — отдельная сущность, требует `waydroid init` после установки.

6. **GPU** — конфиги протестированы на AMD (amdgpu + vulkan-radeon). Для NVIDIA niri требует `WLR_BACKENDS` tweaks или modesetting driver.

---

## Лицензия

WTFPL — делайте что хотите.
