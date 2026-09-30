#!/usr/bin/env bash
# Instalador interactivo de sway-dotfiles.
# Primero pregunta todo, muestra un resumen y recién entonces instala.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$HOME/.cache/sway-dotfiles-install.log"
export DOTFILES_DIR LOG

# Paleta (la misma de tmux/alacritty)
ACCENT="#c9a227"
MUTED="#888888"
OK="#779955"
ERR="#cc3333"

# ============================================
# PAQUETES
# ============================================
PKGS_BASE=(
  sway swaybg swayidle waybar wofi mako libnotify
  alacritty tmux
  grim slurp wl-clipboard brightnessctl imv
  ttf-jetbrains-mono-nerd ttf-font-awesome noto-fonts-emoji noto-fonts-extra
  pipewire wireplumber pavucontrol playerctl blueman
  xdg-desktop-portal xdg-desktop-portal-wlr nwg-look gnome-themes-extra
  zsh zsh-autosuggestions zsh-history-substring-search
  git curl wget jq python eza fzf ripgrep fd base-devel
)
PKGS_NVIM=(neovim lazygit tree-sitter-cli gcc make unzip nodejs npm)
PKGS_UTILS=(swappy cliphist wlsunset)
PKGS_VPN=(wireguard-tools)
PKGS_FLATPAK=(flatpak)
PKGS_GAMING=(mangohud)

AUR_BASE=(swaylock-effects)
AUR_UTILS=(warpd-wayland)
AUR_OTP=(otpclient)

# Componentes opcionales (etiqueta visible en el menú)
C_NVIM="Neovim + LazyVim"
C_UTILS="Utilidades: portapapeles, luz azul, swappy, warpd"
C_VPN="VPN WireGuard"
C_FLATPAK="Flatpak + Flathub"
C_TIDAL="Tidal (Flatpak)"
C_GAMING="Gaming: MangoHud"
C_OTP="OTPClient (AUR)"

# ============================================
# HELPERS
# ============================================
die() { printf '\n  \033[31m✗ %s\033[0m\n\n' "$1" >&2; exit 1; }

ok()   { gum style --foreground "$OK" "  ✓ $*"; }
info() { gum style --foreground "$MUTED" "    $*"; }
warn() { gum style --foreground "$ACCENT" "  ! $*"; }

section() {
  echo
  gum style --foreground "$ACCENT" --bold "━━ $* "
}

# Ejecuta un paso con spinner; la salida completa va al log.
# Uso: step "Título" funcion_o_comando [args...]
step() {
  local title=$1; shift
  echo "==> $title" >>"$LOG"
  if gum spin --spinner dot --spinner.foreground "$ACCENT" --title " $title" -- \
      bash -c '"$@" >>"$LOG" 2>&1' _ "$@"; then
    ok "$title"
  else
    gum style --foreground "$ERR" "  ✗ $title"
    echo
    tail -n 15 "$LOG" | gum style --foreground "$MUTED" --border rounded \
      --border-foreground "$ERR" --padding "0 1"
    die "Falló \"$title\". Log completo: $LOG"
  fi
}

selected() { [[ $'\n'"$COMPONENTS"$'\n' == *$'\n'"$1"$'\n'* ]]; }

# ============================================
# CHEQUEOS PREVIOS
# ============================================
[ "$EUID" -eq 0 ] && die "No lo ejecutes como root; el script usa sudo cuando hace falta."
[ -t 0 ] || die "El instalador es interactivo: ejecútalo desde una terminal."
command -v pacman >/dev/null || die "Este instalador es para Arch Linux y derivadas."

mkdir -p "$(dirname "$LOG")"
: >"$LOG"

if ! command -v gum >/dev/null; then
  echo "Se necesita 'gum' para la interfaz del instalador."
  sudo pacman -S --needed --noconfirm gum || die "No se pudo instalar gum."
fi

clear
gum style --border double --border-foreground "$ACCENT" --padding "1 4" --margin "1 2" \
  --align center \
  "$(gum style --foreground "$ACCENT" --bold 'sway-dotfiles')" \
  "" \
  "Sway · Waybar · Alacritty + tmux · Zsh · LazyVim" \
  "$(gum style --foreground "$MUTED" 'Ligero, pero completo')"

# ============================================
# PREGUNTAS
# ============================================
section "Componentes"
info "La base de Sway siempre se instala. Espacio marca o desmarca, Enter confirma."
COMPONENTS=$(gum choose --no-limit --height 10 \
  --header "¿Qué más quieres instalar?" \
  --header.foreground "$ACCENT" --cursor.foreground "$ACCENT" --selected.foreground "$OK" \
  --selected "$C_NVIM,$C_UTILS,$C_VPN,$C_FLATPAK,$C_GAMING" \
  "$C_NVIM" "$C_UTILS" "$C_VPN" "$C_FLATPAK" "$C_TIDAL" "$C_GAMING" "$C_OTP") || true

# Tidal necesita Flatpak
if selected "$C_TIDAL" && ! selected "$C_FLATPAK"; then
  COMPONENTS+=$'\n'"$C_FLATPAK"
  warn "Tidal necesita Flatpak: se agrega también."
fi

INSTALL_YAY=false
if ! command -v yay >/dev/null; then
  section "AUR"
  info "swaylock-effects (y warpd/OTPClient si los elegiste) vienen de AUR."
  if gum confirm "¿Instalar yay para acceder a AUR?" --prompt.foreground "$ACCENT"; then
    INSTALL_YAY=true
  else
    warn "Sin yay: los paquetes de AUR se omiten (instálalos luego a mano)."
  fi
fi

BLACKARCH=false
if grep -q '^\[blackarch\]' /etc/pacman.conf; then
  section "BlackArch"
  ok "El repositorio de BlackArch ya está configurado."
else
  section "BlackArch"
  info "Agrega el repositorio de BlackArch (~2800 herramientas de pentesting)."
  info "Solo se configura el repo; no instala herramientas. Luego: sudo pacman -S <herramienta>"
  if gum confirm "¿Agregar los repositorios de BlackArch?" --default=false --prompt.foreground "$ACCENT"; then
    BLACKARCH=true
  fi
fi

VM_TOOLS=false
VIRT=$(systemd-detect-virt 2>/dev/null || true)
if [ -n "$VIRT" ] && [ "$VIRT" != "none" ]; then
  section "Máquina virtual"
  info "Detectada: $VIRT"
  if gum confirm "¿Instalar las herramientas de invitado de $VIRT?" --prompt.foreground "$ACCENT"; then
    VM_TOOLS=true
  fi
fi

CHANGE_SHELL=false
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
  section "Shell"
  if gum confirm "¿Usar zsh como shell por defecto?" --prompt.foreground "$ACCENT"; then
    CHANGE_SHELL=true
  fi
fi

# ============================================
# RESUMEN
# ============================================
yn() { $1 && echo "sí" || echo "no"; }
SUMMARY="$(gum style --foreground "$ACCENT" --bold 'Resumen')

Base Sway          sí
$(while IFS= read -r c; do [ -n "$c" ] && printf '%s\n' "+ $c"; done <<<"$COMPONENTS")

AUR (yay)          $(command -v yay >/dev/null && echo "ya instalado" || yn $INSTALL_YAY)
BlackArch          $(grep -q '^\[blackarch\]' /etc/pacman.conf && echo "ya configurado" || yn $BLACKARCH)
Herramientas VM    $(yn $VM_TOOLS)
zsh por defecto    $(yn $CHANGE_SHELL)"

echo
gum style --border rounded --border-foreground "$MUTED" --padding "1 3" --margin "0 2" "$SUMMARY"
echo
gum confirm "¿Empezar la instalación?" --prompt.foreground "$ACCENT" || die "Instalación cancelada. No se modificó nada."

# ============================================
# INSTALACIÓN
# ============================================
section "Permisos"
sudo -v || die "Se necesita sudo."
# Mantener sudo vivo mientras dure la instalación
( while kill -0 $$ 2>/dev/null; do sudo -n true; sleep 50; done ) 2>/dev/null &
ok "sudo habilitado"

PKGS=("${PKGS_BASE[@]}")
AUR=("${AUR_BASE[@]}")
selected "$C_NVIM"    && PKGS+=("${PKGS_NVIM[@]}")
selected "$C_UTILS"   && PKGS+=("${PKGS_UTILS[@]}") && AUR+=("${AUR_UTILS[@]}")
selected "$C_VPN"     && PKGS+=("${PKGS_VPN[@]}")
selected "$C_FLATPAK" && PKGS+=("${PKGS_FLATPAK[@]}")
selected "$C_GAMING"  && PKGS+=("${PKGS_GAMING[@]}")
selected "$C_OTP"     && AUR+=("${AUR_OTP[@]}")

# pipewire-pulse reemplaza a pulseaudio; con --noconfirm el conflicto abortaría
if pacman -Qq pulseaudio &>/dev/null; then
  warn "pulseaudio instalado: se omite pipewire-pulse (reemplázalo a mano si quieres)."
else
  PKGS+=(pipewire-pulse)
fi

section "Paquetes"
if $BLACKARCH; then
  # Sin spinner: strap.sh pregunta por /dev/tty si hacer `pacman -Su`
  info "BlackArch preguntará si actualizar el sistema: se recomienda responder Y."
  STRAP_DIR=$(mktemp -d)
  curl -fsSL -o "$STRAP_DIR/strap.sh" https://blackarch.org/strap.sh ||
    die "No se pudo descargar strap.sh de BlackArch."
  chmod +x "$STRAP_DIR/strap.sh"
  sudo "$STRAP_DIR/strap.sh" 2>&1 | tee -a "$LOG" ||
    die "Falló la configuración de BlackArch. Log completo: $LOG"
  rm -rf "$STRAP_DIR"
  ok "Repositorios de BlackArch agregados"
fi

step "Instalando paquetes oficiales (${#PKGS[@]})" sudo pacman -S --needed --noconfirm "${PKGS[@]}"

if $INSTALL_YAY; then
  install_yay() {
    local tmp; tmp=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
  }
  export -f install_yay
  step "Instalando yay" install_yay
fi

if command -v yay >/dev/null; then
  # swaylock-effects entra en conflicto con swaylock; --noconfirm no lo resolvería
  if pacman -Qq swaylock &>/dev/null && ! pacman -Qq swaylock-effects &>/dev/null; then
    step "Quitando swaylock (lo reemplaza swaylock-effects)" sudo pacman -Rdd --noconfirm swaylock
  fi
  step "Instalando paquetes de AUR (${#AUR[@]})" \
    yay -S --needed --noconfirm --answerclean None --answerdiff None "${AUR[@]}"
else
  warn "AUR omitido. Pendiente: ${AUR[*]}"
fi

if $VM_TOOLS; then
  case "$VIRT" in
    vmware)
      step "Herramientas de VMware" sudo pacman -S --needed --noconfirm open-vm-tools
      step "Habilitando servicios de VMware" sudo systemctl enable --now vmtoolsd.service vmware-vmblock-fuse.service ;;
    oracle)
      step "Herramientas de VirtualBox" sudo pacman -S --needed --noconfirm virtualbox-guest-utils
      step "Habilitando servicio de VirtualBox" sudo systemctl enable --now vboxservice.service ;;
    kvm|qemu)
      step "Agente de QEMU" sudo pacman -S --needed --noconfirm qemu-guest-agent
      step "Habilitando agente de QEMU" sudo systemctl enable --now qemu-guest-agent.service ;;
    *) warn "No hay herramientas conocidas para $VIRT." ;;
  esac
fi

section "Configuración"
if [ ! -d "$HOME/powerlevel10k" ]; then
  step "Descargando Powerlevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
else
  ok "Powerlevel10k ya está instalado"
fi

$CHANGE_SHELL && step "Cambiando la shell a zsh" sudo chsh -s /usr/bin/zsh "$USER"

# Symlinks: cada carpeta de .config/ más los archivos del home.
# Si ya existe algo real (no symlink), se respalda como *.bak.
link() {
  local src=$1 target=$2
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak"
    warn "Respaldo: ${target/#$HOME/\~} → ${target/#$HOME/\~}.bak"
  fi
  ln -sfn "$src" "$target"
}
mkdir -p "$HOME/.config" "$HOME/Pictures"
LINKED=()
for src in "$DOTFILES_DIR"/.config/*/; do
  dir=$(basename "$src")
  link "${src%/}" "$HOME/.config/$dir"
  LINKED+=("$dir")
done
for f in .zshrc .p10k.zsh; do
  [ -f "$DOTFILES_DIR/$f" ] && link "$DOTFILES_DIR/$f" "$HOME/$f" && LINKED+=("$f")
done
ok "Symlinks creados: ${LINKED[*]}"

chmod +x "$HOME/.config/scripts/"*.{sh,py} 2>/dev/null || true

OUTPUT_CONF="$HOME/.config/sway/config.d/output.conf"
NEW_OUTPUT_CONF=false
if [ ! -f "$OUTPUT_CONF" ]; then
  cp "$DOTFILES_DIR/.config/sway/config.d/output.conf.example" "$OUTPUT_CONF"
  NEW_OUTPUT_CONF=true
  ok "output.conf creado desde la plantilla"
fi

CONTEXTS_FILE="$HOME/.config/scripts/contexts.txt"
[ -f "$CONTEXTS_FILE" ] || printf 'personal\nwork\n' >"$CONTEXTS_FILE"
"$HOME/.config/scripts/ctx-menu.sh" --gen-binds
ok "Contextos y atajos Super+F1-Fn"

if [ ! -f "$HOME/Pictures/wallpaper.jpg" ]; then
  step "Descargando wallpaper" wget -q -O "$HOME/Pictures/wallpaper.jpg" \
    https://raw.githubusercontent.com/vyrx-dev/Wallpapers/master/monochrome/monochrome-headless.jpg
fi

if selected "$C_NVIM"; then
  step "Instalando plugins de LazyVim" nvim --headless "+Lazy! sync" +qa
fi

if selected "$C_FLATPAK"; then
  step "Agregando Flathub" flatpak remote-add --user --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
fi
if selected "$C_TIDAL"; then
  step "Instalando Tidal" flatpak install --user --noninteractive flathub com.mastermindzh.tidal-hifi
fi

# ============================================
# FIN
# ============================================
NEXT=("Cierra sesión y entra a Sway desde la TTY: sway")
$NEW_OUTPUT_CONF && NEXT+=("Ajusta tus monitores en ~/.config/sway/config.d/output.conf (swaymsg -t get_outputs)")
NEXT+=("Configura el prompt: p10k configure")
selected "$C_NVIM" && NEXT+=("Abre nvim una vez para compilar Treesitter y revisa :checkhealth")
$VM_TOOLS && NEXT+=("Reinicia para cargar los drivers de la VM")

echo
gum style --border double --border-foreground "$OK" --padding "1 3" --margin "0 2" \
  "$(gum style --foreground "$OK" --bold '✓ Instalación completada')" \
  "" \
  "$(i=1; for n in "${NEXT[@]}"; do echo "$i. $n"; i=$((i + 1)); done)" \
  "" \
  "$(gum style --foreground "$MUTED" "Log: ${LOG/#$HOME/\~}")"
echo
