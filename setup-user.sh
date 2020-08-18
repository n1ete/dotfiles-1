#!/bin/bash

set -e
exec 2> >(while read line; do echo -e "\e[01;31m$line\e[0m"; done)

MY_GPG_KEY_ID="3129FAE7E854EDEF"

dotfiles_dir="$(
    cd "$(dirname "$0")"
    pwd
)"
cd "$dotfiles_dir"

in_docker() {
    grep -q docker /proc/1/cgroup > /dev/null
}

link() {
    orig_file="$dotfiles_dir/$1"
    if [ -n "$2" ]; then
        dest_file="$HOME/$2"
    else
        dest_file="$HOME/$1"
    fi

    mkdir -p "$(dirname "$orig_file")"
    mkdir -p "$(dirname "$dest_file")"

    rm -rf "$dest_file"
    ln -s "$orig_file" "$dest_file"
    echo "$dest_file -> $orig_file"
}

is_chroot() {
    ! cmp -s /proc/1/mountinfo /proc/self/mountinfo
}

systemctl_enable_start() {
    if ! in_docker; then
        systemctl --user daemon-reload
    fi
    echo "systemctl --user enable --now "$1""
    systemctl --user enable --now "$1"
}

echo "==========================="
echo "Setting up user dotfiles..."
echo "==========================="

link ".ignore"
link ".magic"
link ".mrtrust"
link ".p10k.zsh"
link ".p10k.zsh" ".p10k-ascii-8color.zsh"
link ".zprofile"
link ".zsh-aliases"
link ".zshenv"
link ".zshrc"
link ".curlrc"

link ".config/chromium-flags.conf"
link ".config/environment.d"
link ".config/firejail"
link ".config/firewarden"
link ".config/flashfocus"
link ".config/gammastep"
link ".config/git/$(hostgroup)" ".config/git/config"
link ".config/git/common"
link ".config/git/home"
link ".config/git/work"
link ".config/git/ignore"
link ".config/gsimplecal"
link ".config/gtk-2.0"
link ".config/gtk-3.0"
link ".config/htop"
link ".config/imapnotify"
link ".config/kak"
link ".config/kanshi"
link ".config/khal"
link ".config/khard"
link ".config/kitty"
link ".config/mako"
link ".config/mbsync"
link ".config/mimeapps.list"
link ".config/mpv"
link ".config/msmtp"
link ".config/neomutt"
link ".config/notmuch"
link ".config/pacman"
link ".config/pylint"
link ".config/qalculate/qalc.cfg"
link ".config/qutebrowser"
link ".config/repoctl"
link ".config/swappy"
link ".config/sway"
link ".config/swaylock"
link ".config/systemd/user/backup-packages.service"
link ".config/systemd/user/backup-packages.timer"
link ".config/systemd/user/mbsync.service"
link ".config/systemd/user/mbsync.timer"
link ".config/systemd/user/polkit-gnome.service"
link ".config/systemd/user/sway-autoname-workspaces.service"
link ".config/systemd/user/sway-inactive-window-transparency.service"
link ".config/systemd/user/sway-session.target"
link ".config/systemd/user/systembus-notify.service"
link ".config/systemd/user/udiskie.service"
link ".config/systemd/user/waybar.service"
link ".config/systemd/user/waybar-updates.service"
link ".config/systemd/user/waybar-updates.timer"
link ".config/systemd/user/himawaripy.service"
link ".config/systemd/user/himawaripy.timer"
link ".config/tig"
link ".config/transmission/settings.json"
link ".config/USBGuard"
link ".config/waybar"
link ".config/wluma"
link ".config/vimiv"
link ".config/wofi"
link ".config/xkb"

link ".local/bin"
link ".local/share/applications"
link ".local/share/gpg/gpg.conf"
link ".local/share/gpg/gpg-agent.conf"
link ".local/share/qutebrowser/greasemonkey"

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping user services..."
else
    echo ""
    echo "================================="
    echo "Enabling and starting services..."
    echo "================================="

    systemctl --user daemon-reload
    systemctl_enable_start "backup-packages.timer"
    systemctl_enable_start "flashfocus.service"
    systemctl_enable_start "gammastep.service"
    systemctl_enable_start "polkit-gnome.service"
    systemctl_enable_start "sway-autoname-workspaces.service"
    systemctl_enable_start "sway-inactive-window-transparency.service"
    systemctl_enable_start "systembus-notify.service"
    systemctl_enable_start "udiskie.service"
    systemctl_enable_start "waybar.service"
    systemctl_enable_start "waybar-updates.timer"
    systemctl_enable_start "wl-clipboard-manager.service"
    systemctl_enable_start "wluma-als-emulator.service"
    systemctl_enable_start "wluma.service"
    systemctl_enable_start "yubikey-touch-detector.service"
    systemctl_enable_start "himawaripy.timer"

    if [[ $HOSTNAME == home-* ]]; then
        if [ -d "$HOME/library/mail" ]; then
            systemctl_enable_start "mbsync.timer"
            systemctl_enable_start "goimapnotify@personal.service"
        else
            echo >&2 -e "
            === Mail is not configured, skipping...
            === Consult \$MBSYNC_CONFIG for initial setup, and then sync everything using:
            === while ! mbsync -c "\$MBSYNC_CONFIG" -a; do echo 'restarting...'; done
            "
        fi
    fi
fi

echo ""
echo "======================================="
echo "Finishing various user configuration..."
echo "======================================="

echo "Configuring MIME types"
file --compile --magic-file "$HOME/.magic"

if ! gpg -k | grep "$MY_GPG_KEY_ID" > /dev/null; then
    echo "Importing my public PGP key"
    curl -s https://keys.openpgp.org/vks/v1/by-fingerprint/4AA5A5A3602162EF1459D24D3129FAE7E854EDEF | gpg --import
    gpg --trusted-key "$MY_GPG_KEY_ID" > /dev/null
fi

find "$GNUPGHOME" -type f -path "*#*" -delete
find "$GNUPGHOME" -type f -not -path "*#*" -exec chmod 600 {} \;
find "$GNUPGHOME" -type d -exec chmod 700 {} \;

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping YubiKey configuration..."
else
    if [ ! -s "$HOME/.config/Yubico/u2f_keys" ]; then
        echo "Configuring YubiKey for passwordless sudo (touch it now)"
        mkdir -p "$HOME/.config/Yubico"
        pamu2fcfg -un1ete > "$HOME/.config/Yubico/u2f_keys"
    fi
fi

if [ -d "$HOME/.password-store" ]; then
    echo "Configuring automatic git push for pass"
    echo -e "#!/bin/sh\n\npass git push" > "$HOME/.password-store/.git/hooks/post-commit"
    chmod +x "$HOME/.password-store/.git/hooks/post-commit"
else
    echo >&2 "=== Password store is not configured yet, skipping..."
fi

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping GTK file chooser dialog configuration..."
else
    echo "Configuring GTK file chooser dialog"
    gsettings set org.gtk.Settings.FileChooser sort-directories-first true
fi

echo "Ignoring further changes to often changing config"
git update-index --assume-unchanged ".config/transmission/settings.json"

echo "Configure repo-local git settings"
git config user.email "schadensregulierung@gmail.com"
git config user.signingkey "A8A97BFE4BDB137B002F0CDD4F928F5DA9D310B9"
git config commit.gpgsign false
git remote set-url origin "git@github.com:n1ete/dotkob.git"
