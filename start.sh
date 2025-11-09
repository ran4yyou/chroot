#!/system/bin/sh
# Chroot Launcher with dan-home

UBUNTUPATH="/data/local/tmp/chrootubuntu"
DANHOME_OUTSIDE="/data/local/tmp/dan-home"

# Ensure running as root
if [ "$(id -u)" != "0" ]; then
  exit 1
fi

# Check if rootfs exists
if [ ! -d "$UBUNTUPATH" ]; then
  exit 1
fi

# Remount /data if needed
mount -o remount,dev,suid /data 2>/dev/null || true

# Create essential mountpoints
for dir in dev sys proc dev/pts dev/shm tmp home sdcard run; do
  mkdir -p "$UBUNTUPATH/$dir"
done

# Create dan-home outside rootfs if not exists
mkdir -p "$DANHOME_OUTSIDE"

# Main mounts
mount --bind /dev "$UBUNTUPATH/dev" 2>/dev/null || true
mount --bind /sys "$UBUNTUPATH/sys" 2>/dev/null || true
mount --bind /proc "$UBUNTUPATH/proc" 2>/dev/null || true
mount -t devpts devpts "$UBUNTUPATH/dev/pts" 2>/dev/null || true
mount -t tmpfs -o size=256M tmpfs "$UBUNTUPATH/dev/shm" 2>/dev/null || true
mount --bind "$DANHOME_OUTSIDE" "$UBUNTUPATH/home" 2>/dev/null || true

# Bind mount /sdcard if exists
if [ -d /sdcard ]; then
  mount --bind /sdcard "$UBUNTUPATH/sdcard" 2>/dev/null || true
fi

# Set permissions for tmp
chmod 1777 "$UBUNTUPATH/tmp" 2>/dev/null || true

# Enter chroot using /bin/sh
chroot "$UBUNTUPATH" /bin/sh --login

# Unmount all after exit
for mnt in dev/pts dev/shm dev sys proc sdcard home; do
  umount -lf "$UBUNTUPATH/$mnt" 2>/dev/null || true
done
