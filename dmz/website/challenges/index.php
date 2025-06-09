<?php
// Load configuration data
$jsondata = file_get_contents('../pwn.json');
if ($jsondata === false) {
    die("Error: Could not load challenge data");
}

$data = json_decode($jsondata, true);
if ($data === null) {
    die("Error: Invalid JSON data");
}

// Set up directory paths
$challengeDir = rtrim($data['Directory'], DIRECTORY_SEPARATOR);
$baseUrl = basename($challengeDir);

function display_info_files(string $files_dir) {
    if (!is_dir($files_dir)) {
        echo "<div class='error'>Error: Challenge directory not found</div>";
        return;
    }

    $displayed_files = [];
    $patterns = [
        'README*', 'readme*', 'DESCRIPTION*', 'description*', '*.md', '*.txt'
    ];

    echo "<h2>Challenge Information:</h2>";

    foreach ($patterns as $pattern) {
        $files = glob($files_dir . DIRECTORY_SEPARATOR . $pattern, GLOB_BRACE);
        if ($files === false) continue;

        foreach ($files as $file) {
            // Skip files with 'flag' in name (case insensitive)
            if (stripos(basename($file), 'flag') !== false) {
                continue;
            }
            
            // Skip already displayed files
            if (isset($displayed_files[realpath($file)])) {
                continue;
            }

            // Read file contents
            $contents = file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            if ($contents === false) {
                continue;
            }

            // Check for flag content
            $clean_contents = [];
            $has_flag = false;
            foreach ($contents as $line) {
                if (preg_match('/flag\{|\\bflag\\b/i', $line)) {
                    $has_flag = true;
                    break;
                }
                $clean_contents[] = htmlspecialchars($line, ENT_QUOTES, 'UTF-8');
            }

            if ($has_flag) {
                continue;
            }

            $displayed_files[realpath($file)] = true;

            echo '<h3>Contents of ' . htmlspecialchars(basename($file)) . ':</h3>';
            echo '<pre>';
            echo implode("\n", array_slice($clean_contents, 0, 100));
            echo '</pre><hr>';
        }
    }
}

function check_flag($userFlag, $correctFlag) {
    if (trim($userFlag) === trim($correctFlag)) {
        return "<div class='success'>Correct Flag!</div>";
    } else {
        return "<div class='error'>Incorrect Flag. Keep Trying!</div>";
    }
}
?>
<!doctype html>
<html>
    <head>
        <title>Pwn CTF Challenge</title>
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
                text-decoration: none;
            }
            a:hover {
                color: #e5c07b;
                text-decoration: underline;
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
                list-style-type: square;
            }
            li {
                margin-bottom: 8px;
            }
            hr {
                border-top: 1px dashed #555;
                margin: 20px 0;
            }
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
            .success {
                background-color: #2e7d32;
                color: white;
                padding: 10px;
                margin-top: 10px;
                border-radius: 4px;
            }
            .error {
                background-color: #c62828;
                color: white;
                padding: 10px;
                margin-top: 10px;
                border-radius: 4px;
            }
            code {
                background-color: #1c1c1c;
                padding: 2px 4px;
                border-radius: 3px;
                font-family: monospace;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>PWN CTF Challenge</h1>
            <p><strong>Download the binary:</strong> 
                <a href="<?php echo $data['full_path']; ?>" download="<?php echo $data['binary_name']; ?>">
                    <?php echo htmlspecialchars($data['binary_name']); ?>
                </a>
            </p>
            <p><strong>Connect using socat or netcat:</strong></p>
            <code>socat - TCP:<?php echo htmlspecialchars($data['server'] . ' ' . $data['port']); ?></code><br>
            <code>nc <?php echo htmlspecialchars($data['server'] . ' ' . $data['port']); ?></code>

            <?php display_info_files($challengeDir); ?>

            <h2>Available Files</h2>
            <h5>Directory: </h5> <code><?php echo htmlspecialchars($challengeDir); ?></code>
            <ul>
            <?php
            $files = scandir($challengeDir);
            if ($files === false) {
                echo "<li>Error reading directory</li>";
            } else {
                foreach ($files as $file) {
                    if ($file === '.' || $file === '..' || stripos($file, 'flag') !== false) {
                        continue;
                    }
                    $fullPath = $challengeDir . DIRECTORY_SEPARATOR . $file;
                    if (is_file($fullPath)) {
                        $url = htmlspecialchars($challengeDir . '/' . rawurlencode($file));
                        #$filename = htmlspecialchars($file);
                        $filename = $file;
                        echo "<li><a href=\"$url\" download=\"$filename\">$filename</a></li>\n";
                    }
                }
            }
            ?>
            </ul>

            <h2>Submit your Flag:</h2>
            <div class="validator">
                <form method="post">
                    <input type="text" id="flag-input" 
                           placeholder="Enter your flag (e.g., pwn{...})" 
                           size="50" name="flag" required>
                    <button type="submit" id="validate-btn">Submit Flag</button>
                </form>
                <?php
                if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['flag'])) {
                    echo check_flag($_POST['flag'], $data['flag']);
                }
                ?>
            </div>
        </div>
    </body>
</html>