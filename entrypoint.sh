#!/bin/sh
set -e

# Start snix FUSE mount in background
echo "Starting snix store mount..." >&2
/usr/local/bin/snix store mount --experimental-store-composition /etc/snix/store-config.toml /nix/store &
SNIX_PID=$!

# Function to cleanup on exit
cleanup() {
    echo "Cleaning up snix mount..." >&2
    if [ -n "$SNIX_PID" ] && kill -0 "$SNIX_PID" 2>/dev/null; then
        kill "$SNIX_PID" 2>/dev/null || true
        wait "$SNIX_PID" 2>/dev/null || true
    fi
    # Unmount if still mounted
    umount /nix/store 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Wait for mount to be ready (check if /nix/store is accessible)
echo "Waiting for mount to be ready..."
for i in 1 2 3 4 5; do
    if mountpoint -q /nix/store 2>/dev/null; then
        break
    fi
    if [ $i -eq 5 ]; then
        echo "WARNING: Mount may not be ready yet" >&2
    fi
    sleep 1
done

# If no command specified, run a shell
if [ $# -eq 0 ]; then
    exec /bin/sh
fi

# Execute the command
exec "$@"
