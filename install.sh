#!/bin/bash
set -e
clear

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================
# CHECKS
# ============================================
if ! command -v git &>/dev/null; then
  echo "Git no está instalado"
  exit 1
fi

if ! command -v pacman &>/dev/null; then
  echo "Este script es para Arch Linux"
  exit 1
fi

# Detectar VM
IS_VM=false
if systemd-detect-virt --quiet && [ "$(systemd-detect-virt)" != "none" ]; then
  VIRT=$(systemd-detect-virt)
  echo "VM detectada: $VIRT"
  read -p "¿Instalar herramientas de VM? [s/N] " vm_confirm
  if [[ "$vm_confirm" =~ ^[sS]$ ]]; then
    IS_VM=true
  fi
fi

echo "Iniciando instalación..."
sleep 1
clear

# ============================================
# PAQUETES BASE
# ============================================
echo "==> Instalando paquetes base..."
sudo pacman -S --needed \
  sway swaybg swayidle \
  waybar wofi mako libnotify \
  alacritty tmux \
  grim slurp wl-clipboard \
  brightnessctl imv \
  ttf-jetbrains-mono-nerd ttf-font-awesome \
  pipewire wireplumber \
  xdg-desktop-portal xdg-desktop-portal-wlr \
  nwg-look gnome-themes-extra \
  git zsh curl wget \
  flatpak

# AUR
if command -v yay &>/dev/null; then
  echo "==> Instalando paquetes AUR..."
  yay -S --needed swaylock-effects
else
  echo "WARN: yay no encontrado, instala swaylock-effects manualmente"
fi

# ============================================
# ZSH
# ============================================
echo "==> Configurando zsh..."
sleep 1

if [ ! -d ~/powerlevel10k ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
fi

# Plugins zsh
sudo pacman -S --needed zsh-autosuggestions zsh-history-substring-search

# Shell por defecto
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  chsh -s /usr/bin/zsh
fi

clear

# ============================================
# DOTFILES
# ============================================
echo "==> Copiando configs..."
mkdir -p $HOME/.config
mkdir -p $HOME/Pictures
mkdir -p $HOME/.config/environment.d

# Configs
for dir in sway waybar alacritty tmux wofi mako swaylock environment.d; do
  if [ -d "$DOTFILES_DIR/.config/$dir" ]; then
    echo "  -> $dir"
    cp -r "$DOTFILES_DIR/.config/$dir" "$HOME/.config/"
  else
    echo "  WARN: $dir no encontrado"
  fi
done

# Archivos home
[ -f "$DOTFILES_DIR/.zshrc" ] && cp "$DOTFILES_DIR/.zshrc" "$HOME/"
[ -f "$DOTFILES_DIR/.p10k.zsh" ] && cp "$DOTFILES_DIR/.p10k.zsh" "$HOME/"

# Wallpaper
if [ ! -f "$HOME/Pictures/wallpaper.png" ]; then
  echo "==> Descargando wallpaper..."
  wget -q -O "$HOME/Pictures/wallpaper.png" \
    https://raw.githubusercontent.com/dharmx/walls/refs/heads/main/weirdcore/a_cat_looking_at_the_camera.png
fi

# Scripts
if [ -d "$DOTFILES_DIR/scripts" ]; then
  mkdir -p $HOME/.config/scripts
  cp -r "$DOTFILES_DIR/scripts/"* "$HOME/.config/scripts/"
  chmod +x "$HOME/.config/scripts/"*.sh 2>/dev/null || true
fi

# ============================================
# VM
# ============================================
if [ "$IS_VM" = true ]; then
  echo "==> Configurando herramientas de VM ($VIRT)..."

  if [[ "$VIRT" == "vmware" ]]; then
    sudo pacman -S --needed open-vm-tools
    sudo systemctl enable --now vmtoolsd.service
    sudo systemctl enable --now vmware-vmblock-fuse.service

  elif [[ "$VIRT" == "oracle" ]]; then
    sudo pacman -S --needed virtualbox-guest-utils
    sudo systemctl enable --now vboxservice.service

  elif [[ "$VIRT" == "kvm" ]] || [[ "$VIRT" == "qemu" ]]; then
    sudo pacman -S --needed qemu-guest-agent
    sudo systemctl enable --now qemu-guest-agent.service
  fi
fi

# ============================================
# FLATPAK
# ============================================
echo "==> Configurando Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# ============================================
# DONE
# ============================================
clear
echo "============================================"
echo " Instalación completada"
echo "============================================"
echo ""
echo " Próximos pasos:"
echo "  1. Reinicia la sesión"
echo "  2. Entra a Sway desde TTY: sway"
echo "  3. Configura p10k: p10k configure"
if [ "$IS_VM" = true ]; then
  echo "  4. Reinicia para aplicar drivers de VM"
fi
echo ""
