#!/usr/bin/env zsh

[[ "$TTY" == /dev/tty* ]] || return 0

export $(systemctl --user show-environment)

export GPG_TTY="$TTY"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
systemctl --user import-environment GPG_TTY SSH_AUTH_SOCK
export npm_config_prefix=~/.node_modules

if [[ -z $DISPLAY && "$TTY" == "/dev/tty1" ]]; then
    systemd-cat -t sway sway --my-next-gpu-wont-be-nvidia
    systemctl --user stop sway-session.target
    systemctl --user unset-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
fi
