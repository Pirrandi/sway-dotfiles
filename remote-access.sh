#!/usr/bin/env bash
# Configura el acceso remoto a esta máquina mediante Tailscale SSH (+ mosh).
# Se ejecuta a mano: ./remote-access.sh
# OpenSSH (sshd) queda deshabilitado; Tailscale se encarga de la autenticación.
set -euo pipefail

# Paleta (la misma de tmux/alacritty)
ACCENT=$'\033[38;2;128;160;255m'
MUTED=$'\033[38;2;148;148;148m'
OK=$'\033[38;2;140;200;95m'
WARN=$'\033[38;2;227;199;138m'
ERR=$'\033[38;2;255;84;84m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# ============================================
# HELPERS
# ============================================
die()     { printf '\n  %s✗ %s%s\n\n' "$ERR" "$1" "$RESET" >&2; exit 1; }
ok()      { printf '  %s✓ %s%s\n' "$OK" "$*" "$RESET"; }
info()    { printf '    %s%s%s\n' "$MUTED" "$*" "$RESET"; }
warn()    { printf '  %s! %s%s\n' "$WARN" "$*" "$RESET"; }
section() { printf '\n%s%s━━ %s %s\n' "$ACCENT" "$BOLD" "$*" "$RESET"; }

[[ $EUID -ne 0 ]] || die "Ejecuta el script como usuario normal; pedirá sudo cuando haga falta."
command -v pacman >/dev/null || die "Este script es para Arch Linux (o derivadas)."

# ============================================
# PAQUETES
# ============================================
section "Paquetes"
sudo pacman -S --needed tailscale mosh
ok "tailscale y mosh instalados"

# ============================================
# TAILSCALE
# ============================================
section "Tailscale"
sudo systemctl enable --now tailscaled
ok "tailscaled habilitado"
info "Si es la primera vez, abre el enlace que aparece para iniciar sesión."
sudo tailscale up --ssh
ok "Tailscale SSH activo"

# ============================================
# OPENSSH
# ============================================
section "OpenSSH"
if [[ $(systemctl is-enabled sshd 2>/dev/null || true) == enabled ]]; then
  warn "sshd está habilitado y expone el puerto 22 fuera de Tailscale."
  read -rp "    ¿Deshabilitarlo? [y/N] " answer
  if [[ ${answer,,} == y* ]]; then
    sudo systemctl disable --now sshd
    ok "sshd deshabilitado"
  else
    warn "sshd sigue habilitado"
  fi
else
  ok "sshd deshabilitado (no hace falta)"
fi

# ============================================
# FIREWALL
# ============================================
section "Firewall"
if command -v ufw >/dev/null && sudo ufw status 2>/dev/null | head -n1 | grep -q 'Status: active'; then
  sudo ufw allow in on tailscale0 to any port 60000:61000 proto udp
  ok "ufw: puertos de mosh abiertos solo en tailscale0"
elif systemctl is-active --quiet firewalld 2>/dev/null; then
  sudo firewall-cmd --permanent --zone=trusted --add-interface=tailscale0
  sudo firewall-cmd --reload
  ok "firewalld: tailscale0 agregado a la zona trusted"
else
  ok "No hay firewall activo; no hace falta nada"
fi

# ============================================
# SIGUIENTES PASOS
# ============================================
host=$(tailscale status --self --json 2>/dev/null | jq -r '.Self.HostName // empty' 2>/dev/null || true)
host=${host:-$(uname -n)}

section "Siguientes pasos"
cat <<MSG

  ${BOLD}En el teléfono${RESET}
    1. Instala la app de Tailscale e inicia sesión con la misma cuenta.
    2. Cliente de terminal:
       - iOS: Termius o Blink Shell
       - Android: Termux  →  pkg install openssh mosh
    3. Conéctate:
       mosh ${USER}@${host} -- tmux new-session -A -t main -s phone
       ssh -t ${USER}@${host} tmux new-session -A -t main -s phone

  ${BOLD}Seguridad de la cuenta de Tailscale${RESET}
    - Activa la verificación en dos pasos (2FA) en el proveedor de identidad.
    - Recomendado: Tailnet Lock (tailscale lock init)
      https://tailscale.com/kb/1226/tailnet-lock
    - En las ACL, limita SSH a tus propios dispositivos y pide
      reautenticación periódica con "action": "check", por ejemplo:

        "ssh": [{
          "action": "check",
          "src":    ["autogroup:member"],
          "dst":    ["autogroup:self"],
          "users":  ["autogroup:nonroot"]
        }]

MSG
