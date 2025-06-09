#!/bin/bash
set -e

TARGET_DIR="./"
WEB_PAGE_PORT=8000
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
echo "[*] Serving directory '$binary_dir' over HTTP on port $WEB_PAGE_PORT"
echo "[*] Serving binary over TCP port $socat_port with socat (EXEC)"

FILES_DIR="$binary_dir"

# Create the flag file
echo "$FLAG" > "$binary_dir/$FLAG_FILE"
echo "[*] Created flag file: $binary_dir/$FLAG_FILE with content: $FLAG"

display_info_files() {
    local -A displayed_files=()
    local patterns=("README*" "readme*" "DESCRIPTION*" "description*" "*.md" "*.txt")

    echo "<h2>Challenge Information:</h2>"

    for pattern in "${patterns[@]}"; do
        while IFS= read -r -d $'\0' file; do
            [[ "${file,,}" == *"flag"* ]] && continue
            [[ -n "${displayed_files[$file]}" ]] && continue
            displayed_files[$file]=1

            if grep -qiE "flag{|\bflag\b" "$file"; then
                continue
            fi

            filename=$(basename "$file")
            echo "<h3>Contents of $filename:</h3>"
            echo "<pre>"
            head -100 "$file" | sed 's/</\&lt;/g; s/>/\&gt;/g' | grep -vi "flag{"
            echo "</pre><hr>"
        done < <(find "$FILES_DIR" -maxdepth 1 -iname "$pattern" -print0)
    done
}

cat >"$binary_dir/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>PWN CTF Challenge</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #1e1e1e;
            color: #c9d1d9;
            padding: 20px;
            margin: 0;
        }
        .container {
            background-color: #2d2d2d;
            padding: 30px;
            border-radius: 10px;
            max-width: 960px;
            margin: auto;
            box-shadow: 0 0 10px rgba(0,0,0,0.5);
        }
        h1, h2, h3 {
            color: #61afef;
            border-bottom: 1px solid #444;
            padding-bottom: 6px;
        }
        a {
            color: #98c379;
        }
        a:hover {
            color: #e5c07b;
        }
        pre {
            background-color: #1c1c1c;
            border: 1px solid #444;
            padding: 10px;
            overflow-x: auto;
            white-space: pre-wrap;
            border-radius: 6px;
            max-height: 300px;
        }
        ul {
            padding-left: 20px;
        }
        li {
            margin-bottom: 8px;
        }
        hr {
            border-top: 1px dashed #555;
        }
        /* Validator styles */
        .validator {
            margin-top: 20px;
            padding: 15px;
            background-color: #1c1c1c;
            border-radius: 6px;
        }
        #flag-input {
            padding: 8px;
            width: 300px;
            background-color: #2d2d2d;
            border: 1px solid #444;
            color: #c9d1d9;
            border-radius: 4px;
        }
        #validate-btn {
            padding: 8px 15px;
            background-color: #98c379;
            border: none;
            border-radius: 4px;
            color: #1e1e1e;
            cursor: pointer;
            margin-left: 10px;
        }
        #validate-btn:hover {
            background-color: #7dab5f;
        }
        #result {
            margin-top: 10px;
            padding: 8px;
            border-radius: 4px;
            display: none; /* Hidden by default */
        }
        .success {
            background-color: #2e7d32; /* Darker green */
            color: white;
        }
        .error {
            background-color: #c62828; /* Darker red */
            color: white;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>PWN CTF Challenge</h1>
    <p><strong>Download the binary:</strong> <a href="/$chosen_binary_name" download="$chosen_binary_name">$chosen_binary_name</a></p>
    <p><strong>Connect using socat or netcat:</strong></p>
    <code>socat - TCP:$server:$socat_port</code><br>
    <code>nc $server $socat_port</code></p>
EOF

# Add Challenge Information Section
display_info_files >> "$binary_dir/index.html"

cat >> "$binary_dir/index.html" <<EOF
    <h2>Available Files:</h2>
    <p>Directory : <p> <code> $binary_dir </code>
    <ul>
EOF

# List all files in the directory excluding index.html and the flag file
for file in "$FILES_DIR"/*; do
    filename=$(basename "$file")
    [[ "$filename" == "index.html" || "$filename" == "$FLAG_FILE" ]] && continue
    echo "        <li><a href=\"/$filename\" download=\"$filename\">$filename</a></li>" >> "$binary_dir/index.html"
done

cat >> "$binary_dir/index.html" <<EOF
    </ul>

    <h2>Submit your Flag:</h2>
    <div class="validator">
        <form id="flag-form">
            <input type="text" id="flag-input" placeholder="Enter your flag (e.g., pwn{...})" size="50">
            <button type="submit" id="validate-btn">Submit Flag</button>
        </form>
        <div id="result"></div>
    </div>

    <script>
        const correctFlag = "$FLAG"; // The actual flag content

        document.getElementById('flag-form').addEventListener('submit', function(event) {
            event.preventDefault(); // Prevent default form submission
            const enteredFlag = document.getElementById('flag-input').value.trim();
            const resultDiv = document.getElementById('result');

            resultDiv.style.display = 'block'; // Make the result div visible

            if (enteredFlag === correctFlag) {
                resultDiv.textContent = "Correct! You've successfully found the flag!";
                resultDiv.className = 'success'; // Apply success class
            } else {
                resultDiv.textContent = "Incorrect flag. Keep trying!";
                resultDiv.className = 'error'; // Apply error class
            }
        });
    </script>
</div>
</body>
</html>
EOF

# Start socat
socat tcp-l:$socat_port,reuseaddr,fork EXEC:"$chosen_binary",pty,stderr &
socat_pid=$! # Store the PID of socat

cd "$binary_dir"
echo "[+] Starting Python HTTP server on port $WEB_PAGE_PORT"
python3 -m http.server "$WEB_PAGE_PORT" &
web_pid=$!

cd - >/dev/null

cleanup() {
    echo "[+] Cleaning up..."
    kill "$web_pid" 2>/dev/null || true
    kill "$socat_pid" 2>/dev/null || true # Kill socat as well
    rm -f "$binary_dir/index.html"
    rm -f "$binary_dir/$FLAG_FILE" # Remove the flag file
    echo "[+] Done."
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

wait "$web_pid"