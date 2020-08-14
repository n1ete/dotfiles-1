#!/bin/bash

set -e
exec 2> >(while read line; do echo -e "\e[01;31m$line\e[0m"; done)

script_name="$(basename "$0")"
dotfiles_dir="$(
    cd "$(dirname "$0")"
    pwd
)"
cd "$dotfiles_dir"

if (( "$EUID" )); then
    sudo -s "$dotfiles_dir/$script_name" "$@"
    exit 0
fi

if [ "$1" = "-r" ]; then
    echo >&2 "Running in reverse mode!"
    reverse=1
fi

copy() {
    if [ -z "$reverse" ]; then
        orig_file="$dotfiles_dir/$1"
        dest_file="/$1"
    else
        orig_file="/$1"
        dest_file="$dotfiles_dir/$1"
    fi

    mkdir -p "$(dirname "$orig_file")"
    mkdir -p "$(dirname "$dest_file")"

    rm -rf "$dest_file"

    cp -R "$orig_file" "$dest_file"
    if [ -z "$reverse" ]; then
        [ -n "$2" ] && chmod "$2" "$dest_file"
    else
        chown -R n1ete "$dest_file"
    fi
    echo "$dest_file <= $orig_file"
}

is_chroot() {
    grep rootfs /proc/mounts > /dev/null
}

systemctl_enable() {
    echo "systemctl enable "$1""
    systemctl enable "$1"
}

systemctl_enable_start() {
    echo "systemctl enable --now "$1""
    systemctl enable "$1"
    systemctl start "$1"
}

echo ""
echo "=========================="
echo "Setting up /etc configs..."
echo "=========================="
copy "etc/udev/rules.d/80-nvidia-pm.rules"
copy "etc/modprobe.d/nvidia.conf"
copy "etc/bluetooth/main.conf"
copy "etc/conf.d/snapper"
copy "etc/default/grub-btrfs/config"
copy "etc/default/earlyoom"
copy "etc/docker/daemon.json"
copy "etc/modules-load.d/v4l2loopback.conf"
copy "etc/modprobe.d/v4l2loopback.conf"
copy "etc/pacman.conf"
copy "etc/pacman.d/hooks"
copy "etc/pam.d/polkit-1"
copy "etc/pam.d/sudo"
copy "etc/pulse/default.pa"
copy "etc/snap-pac.conf"
copy "etc/snapper/configs/root"
copy "etc/ssh/ssh_config"
copy "etc/sudoers.d/override"
copy "etc/sysctl.d/99-sysctl.conf"
copy "etc/systemd/journald.conf"
copy "etc/systemd/logind.conf"
copy "etc/systemd/network"
copy "etc/systemd/resolved.conf"
copy "etc/systemd/system/getty@tty1.service.d/override.conf"
copy "etc/systemd/system/usbguard.service.d/override.conf"
copy "etc/systemd/system/reflector.service"
copy "etc/systemd/system/reflector.timer"
copy "etc/systemd/system/system-dotfiles-sync.service"
copy "etc/systemd/system/system-dotfiles-sync.timer"
copy "etc/updatedb.conf"
copy "etc/usbguard/usbguard-daemon.conf" 600

if [[ $HOSTNAME == home-* ]]; then
    copy "etc/systemd/system/backup-repo@pkgbuild"
    copy "etc/systemd/system/backup-repo@.service"
    copy "etc/systemd/system/backup-repo@.timer"
fi

(( "$reverse" ))&& exit 0

echo ""
echo "================================="
echo "Enabling and starting services..."
echo "================================="

sysctl --system > /dev/null

systemctl daemon-reload
systemctl_enable_start "bluetooth.service"
systemctl_enable_start "btrfs-scrub@-.timer"
systemctl_enable_start "btrfs-scrub@mnt-btrfs\x2droot.timer"
systemctl_enable_start "btrfs-scrub@home.timer"
systemctl_enable_start "btrfs-scrub@var-cache-pacman.timer"
systemctl_enable_start "btrfs-scrub@var-log.timer"
systemctl_enable_start "btrfs-scrub@var-tmp.timer"
systemctl_enable_start "btrfs-scrub@\x2esnapshots.timer"
systemctl_enable_start "btrfs-scrub@var-lib-aurbuild.timer"
systemctl_enable_start "btrfs-scrub@var-lib-archbuild.timer"
systemctl_enable_start "btrfs-scrub@var-lib-docker.timer"
systemctl_enable_start "docker.socket"
systemctl_enable_start "earlyoom.service"
systemctl_enable_start "fstrim.timer"
systemctl_enable_start "iwd.service"
systemctl_enable_start "linux-modules-cleanup.service"
systemctl_enable_start "pcscd.socket"
systemctl_enable_start "reflector.timer"
systemctl_enable_start "snapper-cleanup.timer"
systemctl_enable_start "system-dotfiles-sync.timer"
systemctl_enable_start "systemd-networkd.socket"
systemctl_enable_start "systemd-resolved.service"
systemctl_enable_start "tlp.service"
systemctl_enable_start "ufw.service"
systemctl_enable_start "usbguard.service"
systemctl_enable_start "usbguard-dbus.service"

if [ ! -s "/etc/usbguard/rules.conf" ]; then
    echo >&2 "=== Remember to set usbguard rules: usbguard generate-policy >! /etc/usbguard/rules.conf"
fi

#if [[ $HOSTNAME == home-* ]]; then
#    systemctl_enable_start "backup-repo@pkgbuild.timer"
#
#    if [ -d "/home/n1ete/.ccnet" ]; then
#        systemctl_enable_start "seaf-cli@n1ete.service"
#    else
#        echo >&2 "=== Seafile is not initialized, skipping..."
#    fi
#fi

echo ""
echo "==============================="
echo "Creating top level Trash dir..."
echo "==============================="
mkdir --parent /.Trash
chmod a+rw /.Trash
chmod +t /.Trash
echo "Done"

echo ""
echo "======================================="
echo "Finishing various user configuration..."
echo "======================================="

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping /etc/resolv.conf setup..."
else
    echo "Configuring /etc/resolv.conf"
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

echo "Configuring NTP"
timedatectl set-ntp true

echo "Configuring aurutils"
ln -sf /etc/pacman.conf /usr/share/devtools/pacman-aur.conf

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping firewall setup..."
else
    echo "Configuring firewall"
    ufw --force reset > /dev/null
    ufw default allow outgoing
    ufw default deny incoming
    ufw enable
    find /etc/ufw -type f -name '*.rules.*' -delete

    sleep 1
fi
