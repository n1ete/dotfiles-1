#!/usr/bin/env zsh

export LANG=de_DE.UTF-8
export LANGUAGE=en_US
export LC_MONETARY=de_DE.UTF-8
export LC_TIME=de_DE.UTF-8

export LIBVA_DRIVER_NAME=iHD
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"

export MOZ_ENABLE_WAYLAND=1
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland-egl
export WLR_DRM_NO_MODIFIERS=1

export PATH="$HOME/bin:$PATH"

systemctl --user import-environment PATH

if [[ -z $DISPLAY && "$(tty)" == "/dev/tty1" ]]; then
    systemd-cat -t sway sway --my-next-gpu-wont-be-nvidia
    systemctl --user stop sway-session.target
fi
