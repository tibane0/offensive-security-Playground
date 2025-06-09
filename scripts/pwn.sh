#!/bin/bash
set -e

TARGET_DIR="./"
MIN_PORT=9000
MAX_PORT=9999
socat_port=$((RANDOM % (MAX_PORT - MIN_PORT + 1) + MIN_PORT))

server=$(ip -o -4 addr list | awk '!/ lo / {print $4}' | cut -d/ -f1 | head -n1)

# Generate a random flag content
RANDOM_FLAG_CONTENT=$(head /dev/urandom | tr -dc A-Za-z0-9_ | head -c 32)
FLAG="pwn{$RANDOM_FLAG_CONTENT}"
FLAG_FILE="flag.txt"


function is_executable() {
    local file="$1"
    [[ -x "$file" ]] && file "$file" | grep -qE 'ELF|PE32|PE64'
}

mapfile -t potential_binaries < <(find "$TARGET_DIR" -type f -executable ! -iname '*flag*' ! -ipath '*flag*')

declare -a actual_binaries=()
for file in "${potential_binaries[@]}"; do
    if is_executable "$file"; then
        [[ "$file" =~ \.so($|\.) ]] && continue
        actual_binaries+=("$file")
    fi
done

if [ ${#actual_binaries[@]} -eq 0 ]; then
    echo "No executable binaries found in $TARGET_DIR and subdirectories."
    exit 1
fi

chosen_binary="${actual_binaries[RANDOM % ${#actual_binaries[@]}]}"
binary_dir=$(dirname "$chosen_binary")
chosen_binary_name=$(basename "$chosen_binary")


echo "[*] Selected binary: $chosen_binary"
echo "[*] Serving binary over TCP port $socat_port with socat (EXEC)"

FILES_DIR="$binary_dir"

# Create the flag file
echo "$FLAG" > "$binary_dir/$FLAG_FILE"
echo "[*] Created flag file: $binary_dir/$FLAG_FILE with content: $FLAG"

# Start socat
socat tcp-l:$socat_port,reuseaddr,fork EXEC:"$chosen_binary",pty,stderr &
socat_pid=$! # Store the PID of socat

# enter files in json
full_path="$binary_dir/$chosen_binary"


cat <<EOF > /var/www/html/pwn.json
{
    "binary_name": "$chosen_binary",
    "full_path": "$full_path",
    "Directory": "$binary_dir",
    "port": "$socat_port",
    "flag": "$FLAG",
    "server": "$server"

}
EOF


cleanup() {
    echo "[+] Cleaning up..."
    kill "$socat_pid" 2>/dev/null || true # Kill socat as well
    rm -f "$binary_dir/$FLAG_FILE" # Remove the flag file
    echo "[+] Done."
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT
wait $socat_pid
