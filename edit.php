<?php
// Ścieżka do pliku setup.cfg
$filePath = 'setup.cfg';
header('Content-Type: text/html; charset=utf-8');

// Funkcja do wczytywania pliku konfiguracyjnego
function parseConfigFile($filePath)
{
    $config = [];
    foreach (file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (preg_match('/^\\s*#/u', $line) || trim($line) === '') continue;
        $parts = explode('=', $line, 2);
        $key = trim($parts[0]);
        $value = isset($parts[1]) ? trim($parts[1]) : '';
        $config[$key] = $value;
    }
    return $config;
}

// Wczytaj dane z pliku
if (!file_exists($filePath)) {
    die("Plik $filePath nie istnieje.");
}

$config = parseConfigFile($filePath);

// Jeśli użytkownik przeszedł do edycji
if (isset($_GET['action']) && $_GET['action'] === 'edit') {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        foreach ($config as $key => $value) {
            if (isset($_POST[$key])) {
                $config[$key] = htmlspecialchars($_POST[$key]);
            }
        }
        // Zapisz zmiany do pliku
        $lines = file($filePath, FILE_IGNORE_NEW_LINES);
        foreach ($lines as &$line) {
            if (preg_match('/^([^#=\\s]+)\\s*=\\s*(.*)$/', $line, $matches)) {
                $key = $matches[1];
                if (isset($config[$key])) {
                    $line = "$key={$config[$key]}";
                }
            }
        }
        file_put_contents($filePath, implode("\n", $lines) . "\n");
        $message = "Zapisano zmiany.";
    }

    // Wyświetl formularz edycji
    ?>
    <!DOCTYPE html>
    <html lang="pl">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Edycja setup.cfg</title>
        <style>
            body {
                font-family: 'Arial', sans-serif;
                background: #f0f4f8;
                color: #333;
                margin: 0;
                padding: 0;
            }
            .container {
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: #fff;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            }
            h1 {
                text-align: center;
                color: #4CAF50;
            }
            form {
                display: flex;
                flex-direction: column;
                gap: 15px;
            }
            label {
                font-weight: bold;
                color: #555;
            }
            input[type="text"] {
                padding: 10px;
                border: 1px solid #ccc;
                border-radius: 4px;
                font-size: 16px;
            }
            button {
                padding: 12px;
                background: #4CAF50;
                color: #fff;
                border: none;
                border-radius: 4px;
                font-size: 16px;
                cursor: pointer;
                transition: background 0.3s;
            }
            button:hover {
                background: #45a049;
            }
            .back-link {
                text-align: center;
                margin-top: 20px;
            }
            .back-link a {
                color: #4CAF50;
                text-decoration: none;
                font-size: 16px;
            }
            .back-link a:hover {
                text-decoration: underline;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Edycja setup.cfg</h1>
            <?php if (!empty($message)) : ?>
                <p style="color: green;"><?= $message ?></p>
            <?php endif; ?>
            <form method="post">
                <?php foreach ($config as $key => $value) : ?>
                    <label for="<?= $key ?>"><?= $key ?>:</label>
                    <input type="text" id="<?= $key ?>" name="<?= $key ?>" value="<?= htmlspecialchars($value) ?>">
                <?php endforeach; ?>
                <button type="submit">Zapisz</button>
            </form>
            <div class="back-link">
                <a href="index.php">Powrót</a>
            </div>
        </div>
    </body>
    </html>
    <?php
    exit;
}

// Wyświetl tabelę z danymi
?>
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deye AC Couple Grid Charger 1.0</title>
    <style>
    body {
        font-family: 'Arial', sans-serif;
        background: #f0f4f8;
        color: #333;
        margin: 0;
        padding: 0;
    }
    .container {
        max-width: 800px;
        margin: 50px auto;
        padding: 20px;
        background: #fff;
        border-radius: 8px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        overflow-x: auto;
    }
    h1 {
        text-align: center;
        color: #4CAF50;
    }
    table {
        border-collapse: collapse;
        width: 100%;
        table-layout: fixed; /* Ważne dla zawijania tekstu */
        margin-top: 20px;
    }
    th, td {
        border: 1px solid #ddd;
        padding: 12px;
        text-align: left;
        word-wrap: break-word; /* Zawijanie tekstu */
        white-space: pre-wrap; /* Umożliwia łamanie tekstu */
    }
    th {
        background: #f4f4f4;
        font-weight: bold;
    }
    tr:nth-child(even) {
        background: #f9f9f9;
    }
    tr:hover {
        background: #f1f1f1;
    }
    .edit-link {
        display: block;
        text-align: center;
        margin-top: 20px;
    }
    .edit-link a {
        display: inline-block;
        padding: 10px 20px;
        background: #4CAF50;
        color: #fff;
        border-radius: 4px;
        text-decoration: none;
        font-size: 16px;
        transition: background 0.3s;
    }
    .edit-link a:hover {
        background: #45a049;
    }
</style>

</head>
<body>
    <div class="container">
        <h1>Deye AC Couple Grid Charger 1.0</h1>
        <table>
            <thead>
                <tr>
                    <th>Parametr</th>
                    <th>Wartość</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($config as $key => $value): ?>
                    <tr>
                        <td><?= htmlspecialchars($key) ?></td>
                        <td><?= htmlspecialchars($value) ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
        <div class="edit-link">
            <a href="edit.php?action=edit">Edytuj konfigurację</a>
        </div>
    </div>
</body>
</html>

