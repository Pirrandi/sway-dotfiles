# sway-dotfiles

Configuración personal para **Arch Linux + Sway**. Ligera en recursos, completa en funciones: un solo `install.sh` deja cualquier máquina con el mismo entorno.

![Escritorio](assets/sway-preview.png)
![Pantalla de bloqueo](assets/lockscreen-preview.png)

## Stack

| Componente | Herramienta |
|------------|-------------|
| Gestor de ventanas | Sway (Wayland) |
| Barra | Waybar |
| Launcher | Wofi |
| Terminal | Alacritty + tmux |
| Shell | Zsh + Powerlevel10k (sin Oh My Zsh) |
| Editor | Neovim + LazyVim |
| Notificaciones | Mako |
| Bloqueo | Swaylock-effects + swayidle |

**Principios**

- Nada de frameworks pesados: plugins de zsh desde los paquetes del sistema, sin OMZ ni TPM.
- Los módulos de Waybar reaccionan a eventos (workspaces, MPRIS) en lugar de consultar cada segundo.
- Lo específico de cada máquina (monitores, contextos) queda fuera del repositorio.

## Instalación

Requisitos: Arch Linux (o derivada) y `git`. El instalador usa [gum](https://github.com/charmbracelet/gum) para la interfaz y lo instala si falta.

```bash
git clone https://github.com/Pirrandi/sway-dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

El instalador es interactivo: **primero pregunta todo, muestra un resumen y solo instala si confirmas**. Si cancelas en el resumen, no se modifica nada.

**Qué pregunta**

| Pregunta | Por defecto |
|----------|-------------|
| Componentes opcionales: Neovim + LazyVim, utilidades (portapapeles, luz azul, swappy, warpd), VPN WireGuard, Flatpak, Tidal, MangoHud, OTPClient | Todos menos Tidal y OTPClient |
| Instalar `yay` para acceder a AUR (solo si no está) | Sí |
| Agregar los repositorios de BlackArch (solo el repo, sin herramientas) | No |
| Herramientas de invitado (solo si detecta una VM: VMware, VirtualBox, QEMU/KVM) | Sí |
| Usar zsh como shell por defecto (solo si no lo es) | Sí |

**Qué hace**

1. Instala los paquetes oficiales y los de AUR según lo elegido. La base de Sway siempre se instala.
2. Descarga Powerlevel10k.
3. Crea un symlink en `~/.config/` para cada carpeta de `.config/` del repositorio, además de `~/.zshrc` y `~/.p10k.zsh`. Si ya existe una carpeta real, la respalda como `*.bak`.
4. Crea `output.conf` a partir de la plantilla y genera los atajos de contexto.
5. Descarga el wallpaper y, si corresponde, los plugins de LazyVim.

Cada paso muestra su progreso; la salida completa queda en `~/.cache/sway-dotfiles-install.log`. Si un paso falla, se muestran las últimas líneas del log.

### Después de instalar

1. Cierra sesión y entra a Sway desde la TTY: `sway`.
2. Ajusta los monitores en `~/.config/sway/config.d/output.conf` (nombres con `swaymsg -t get_outputs`).
3. Configura el prompt: `p10k configure`.
4. Abre `nvim` una vez para que compile los parsers de Treesitter y revisa `:checkhealth`.

## Contextos

Los workspaces se agrupan en **contextos** (`personal`, `work`, …). Cada contexto tiene sus propios workspaces del 1 al 10, y `Super+1-0` siempre actúa sobre el contexto activo. Así se mantienen separados el trabajo y lo personal sin mezclar ventanas.

- Los contextos se definen en `~/.config/scripts/contexts.txt` (uno por línea).
- Se crean nuevos desde el menú `Super+Ctrl+W`, que también regenera los atajos `Super+F1-Fn`.
- La barra muestra los workspaces del contexto activo: `personal: ●1 ○2 ○3`.

## Atajos

`Super` es la tecla Windows.

### Ventanas y sesión

| Atajo | Acción |
|-------|--------|
| `Super+Return` | Terminal |
| `Super+D` | Launcher |
| `Super+Q` | Cerrar ventana |
| `Super+H/J/K/L` o flechas | Mover el foco |
| `Super+Shift+H/J/K` o flechas | Mover la ventana (`Super+Shift+L` bloquea; usa `Super+Shift+→`) |
| `Super+F` | Pantalla completa |
| `Super+Shift+Space` | Alternar flotante |
| `Super+T` / `Super+Shift+T` / `Super+S` | Layout normal / pestañas / apilado |
| `Super+Shift+I` | Modo redimensionar |
| `Super+Shift+R` | Recargar Sway |
| `Super+Shift+L` | Bloquear pantalla |
| `Super+Shift+Q` | Salir de Sway |

### Contextos y workspaces

| Atajo | Acción |
|-------|--------|
| `Super+1-0` | Ir al workspace N del contexto activo |
| `Super+Shift+1-0` | Mover la ventana al workspace N del contexto activo |
| `Super+F1-Fn` | Cambiar de contexto |
| `Super+Ctrl+W` | Menú de contextos (ir, mover, crear) |
| `Super+Ctrl+M` | Mover la ventana a cualquier workspace de cualquier contexto |
| `Super+Tab` | Volver al workspace anterior |

### Utilidades

| Atajo | Acción |
|-------|--------|
| `Print` | Captura completa → `~/Pictures/Screenshots` + portapapeles |
| `Super+Print` | Captura de un área → `~/Pictures/Screenshots` + portapapeles |
| `Super+Shift+S` | Captura de un área solo al portapapeles |
| `Super+Ctrl+S` | Captura de un área → editor swappy |
| `Super+Shift+V` | Historial del portapapeles |
| `Super+Space` | Complementos: filtro de luz azul, historial del portapapeles, no molestar |
| `Super+Shift+A` | Elegir salida de audio |
| `Super+Ctrl+Space` | Cambiar distribución de teclado (us / latam) |
| `Super+Alt+C/X/G/S` | warpd: mouse con teclado (normal / hint / grid / screen); `Esc` para salir |
| `Super+O` / `Super+Alt+M` | Scratchpad: OTPClient / Tidal |

### tmux

El prefijo es `Ctrl+A`.

| Atajo | Acción |
|-------|--------|
| `Prefijo` + `\|` / `-` | Dividir en vertical / horizontal |
| `Prefijo` + `H/J/K/L` (minúsculas) | Moverse entre paneles |
| `Prefijo` + `H/J/K/L` (mayúsculas) | Redimensionar panel |
| `Prefijo` + `Ctrl+H/L` | Ventana anterior / siguiente |
| `Prefijo` + `q` / `Q` | Cerrar panel / ventana |
| `Prefijo` + `r` | Recargar configuración |

### Zsh

| Atajo | Acción |
|-------|--------|
| `Ctrl+R` | Buscar en el historial (fzf) |
| `Ctrl+T` | Insertar archivo (fzf) |
| `Alt+C` | Entrar a un directorio (fzf) |
| `↑` / `↓` | Buscar en el historial por lo ya escrito |
| `Ctrl+←/→` | Moverse por palabras |
| `Ctrl+Backspace` / `Alt+Backspace` | Borrar la palabra anterior |

## Personalización

| Qué | Dónde |
|-----|-------|
| Monitores y asignación de workspaces | `~/.config/sway/config.d/output.conf` (no versionado) |
| Contextos | `~/.config/scripts/contexts.txt` (no versionado) |
| Perfiles de VPN (WireGuard) | `PROFILES` en `.config/scripts/wg-status.sh` |
| Sensor de temperatura | `hwmon-path-abs` en `.config/waybar/config.jsonc` |
| Distribuciones de teclado | `.config/sway/config.d/input.conf` |
| Plugins de Neovim | `.config/nvim/lua/plugins/` |

## Estructura

```
.
├── install.sh
├── .zshrc / .p10k.zsh
└── .config/
    ├── sway/         # config + config.d/ (atajos, tema, inicio, entrada)
    ├── waybar/       # barra y estilos
    ├── scripts/      # contextos, capturas, audio, VPN, módulos de la barra
    ├── nvim/         # LazyVim
    ├── tmux/  alacritty/  wofi/  mako/  swaylock/
    ├── environment.d/  fontconfig/  MangoHud/
```
