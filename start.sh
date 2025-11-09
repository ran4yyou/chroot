#!/system/bin/sh
# Chroot launcher (Termux / Android root) - minimal, portable

UBUNTUPATH="/data/local/tmp/chrootubuntu"
DANHOME_OUTSIDE="/data/local/tmp/dan-home"

# require root
if [ "$(id -u)" != "0" ]; then
  exit 1
fi

# check rootfs
if [ ! -d "$UBUNTUPATH" ]; then
  exit 1
fi

# remount /data if possible
mount -o remount,dev,suid /data 2>/dev/null || true

# create mountpoints inside rootfs
for d in dev sys proc dev/pts dev/shm tmp home sdcard run; do
  mkdir -p "$UBUNTUPATH/$d"
done

# ensure outside home exists
mkdir -p "$DANHOME_OUTSIDE"

# function cleanup mounts (best-effort)
_cleanup() {
  for m in dev/pts dev/shm dev sys proc sdcard home; do
    umount -lf "$UBUNTUPATH/$m" 2>/dev/null || true
  done
}
# trap EXIT to cleanup after leaving chroot
trap _cleanup EXIT

# perform mounts (ignore errors)
mount --bind /dev "$UBUNTUPATH/dev" 2>/dev/null || true
mount --bind /sys "$UBUNTUPATH/sys" 2>/dev/null || true
mount --bind /proc "$UBUNTUPATH/proc" 2>/dev/null || true
mount -t devpts devpts "$UBUNTUPATH/dev/pts" 2>/dev/null || true
mount -t tmpfs -o size=256M tmpfs "$UBUNTUPATH/dev/shm" 2>/dev/null || true
mount --bind "$DANHOME_OUTSIDE" "$UBUNTUPATH/home" 2>/dev/null || true

# bind /sdcard if available
if [ -d /sdcard ]; then
  mount --bind /sdcard "$UBUNTUPATH/sdcard" 2>/dev/null || true
fi

# set tmp perms
chmod 1777 "$UBUNTUPATH/tmp" 2>/dev/null || true

# choose shell inside chroot (prefer bash or zsh, fall back to sh)
SHELL_IN="/bin/sh"
if [ -x "$UBUNTUPATH/bin/bash" ]; then
  SHELL_IN="/bin/bash"
elif [ -x "$UBUNTUPATH/bin/zsh" ]; then
  SHELL_IN="/bin/zsh"
fi

# enter chroot (no --login option)
chroot "$UBUNTUPATH" "$SHELL_IN"
# when chroot exits, trap will run cleanup
