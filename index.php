<?php
// Ścieżka do pliku data.txt
header('Content-Type: text/html; charset=utf-8');
$file_path = 'data.txt';


// Sprawdzenie, czy plik istnieje
if (!file_exists($file_path)) {
    die("Plik data.txt nie został znaleziony.");
}

// Wczytaj dane z pliku
$data = file($file_path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

// Przetwarzanie danych na tablicę asocjacyjną
$parsed_data = array();
foreach ($data as $line) {
    $line_parts = explode('=', $line, 2);
    $key = trim($line_parts[0]);
    $value = isset($line_parts[1]) ? trim($line_parts[1]) : '';
    $parsed_data[$key] = $value;
}

// Mapowanie danych do wyświetlenia
$setcharge = isset($parsed_data['SETCHARGE']) ? $parsed_data['SETCHARGE'] : 'Brak danych';
$battcur = isset($parsed_data['BATTCUR']) ? $parsed_data['BATTCUR'] : 'Brak danych';
$mode = isset($parsed_data['MODE']) ? $parsed_data['MODE'] : 'Brak danych';
$schedule = isset($parsed_data['SCHEDULE']) ? $parsed_data['SCHEDULE'] : 'Brak danych';
$batcharge = isset($parsed_data['BATCHARGE']) ? $parsed_data['BATCHARGE'] : 'Brak danych';
$batmin = isset($parsed_data['BATMIN']) ? $parsed_data['BATMIN'] : 'Brak danych';
$lowbat = isset($parsed_data['LOWBAT']) ? $parsed_data['LOWBAT'] : 'Brak danych';
$maxbat = isset($parsed_data['MAXBAT']) ? $parsed_data['MAXBAT'] : 'Brak danych';
$update = isset($parsed_data['UPDATE']) ? $parsed_data['UPDATE'] : 'Brak danych';
$load = isset($parsed_data['LOAD']) ? $parsed_data['LOAD'] : 'Brak danych';
$gridpower = isset($parsed_data['GRIDPOWER']) ? $parsed_data['GRIDPOWER'] : 'Brak danych';

$battwat = isset($parsed_data['BATTWAT']) ? $parsed_data['BATTWAT'] : 'Brak danych';
$pv = isset($parsed_data['PV']) ? $parsed_data['PV'] : 'Brak danych';
$chargeforce = isset($parsed_data['CHARGEFORCE']) ? $parsed_data['CHARGEFORCE'] : 'Brak danych';

// Funkcja do renderowania ikony bateryjki
function renderBatteryIcon($percentage) {
    if ($percentage >= 80) {
        return '🔋🔋🔋🔋';
    } elseif ($percentage >= 60) {
        return '🔋🔋🔋';
    } elseif ($percentage >= 40) {
        return '🔋🔋';
    } elseif ($percentage >= 20) {
        return '🔋';
    } else {
        return '🪫';
    }
}

// Interpretacja danych
$mode_description = $mode === 'Disabled' ? 'Pozwalam rozładowywać' : ($mode === 'Grid' ? 'Ładuje' : 'Nieznany tryb');
$chargeforce_description = $chargeforce === '1' ? 'Tak' : 'Nie';

?>
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deye prosument 0.6</title>
    <meta http-equiv="refresh" content="2">
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f9;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 800px;
            margin: 20px auto;
            background: #ffffff;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            overflow: hidden;
            padding: 20px;
        }
        h1 {
            text-align: center;
            color: #333333;
        }
        ul {
            list-style: none;
            padding: 0;
        }
        li {
            margin: 10px 0;
            padding: 10px;
            background: #e8e8f3;
            border-radius: 5px;
            font-size: 18px;
        }
        li strong {
            color: #555555;
        }
        .config-link {
            display: block;
            text-align: center;
            margin-top: 20px;
        }
        .config-link a {
            text-decoration: none;
            color: #ffffff;
            background-color: #007BFF;
            padding: 10px 20px;
            border-radius: 5px;
            font-size: 16px;
        }
        .config-link a:hover {
            background-color: #0056b3;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Deye prosument v0.7</h1>
        <ul>
            <li><strong>Aktualne ładowanie:</strong> <?php echo htmlspecialchars($setcharge); ?>A</li>
            <li><strong>Obciażenie baterii:</strong> <?php echo htmlspecialchars($battcur); ?>A</li>
            <li><strong>Tryb działania harmonogramu:</strong> <?php echo htmlspecialchars($mode_description); ?></li>
            <li><strong>Aktualny harmonogram:</strong> <?php echo htmlspecialchars($schedule); ?></li>
            <li><strong>Aktualne naładowanie:</strong> <?php echo htmlspecialchars($batcharge); ?>% <?php echo renderBatteryIcon((int)$batcharge); ?></li>
            <li><strong>Rozładowanie buforowe do:</strong> <?php echo htmlspecialchars($lowbat); ?>%</li>
            <li><strong>Naładowanie buforowe do:</strong> <?php echo htmlspecialchars($maxbat); ?>%</li>
            <li><strong>Próg rozładowania krytycznego:</strong> <?php echo htmlspecialchars($batmin); ?>%</li>
            <li><strong>Ostatnia aktualizacja:</strong> <?php echo htmlspecialchars($update); ?></li>
            <li><strong>Moc poborów sumaryczna:</strong> <?php echo htmlspecialchars($load); ?> W</li>
            <li><strong>Moc baterii:</strong> <?php echo htmlspecialchars($battwat); ?> W</li>
            <li><strong>Aktualna produkcja PV:</strong> <?php echo htmlspecialchars($pv); ?> W</li>
            <li><strong>Obciążenie sieci:</strong> <?php echo htmlspecialchars($gridpower); ?> W</li>
            <li><strong>Wymuszone ładowanie:</strong> <?php echo htmlspecialchars($chargeforce_description); ?></li>
        </ul>
        <div class="config-link">
            <a href="edit.php">Konfiguracja</a>
        </div>
    </div>
</body>
</html>

