# Настройки путей
$ResourcePacksDir = "resourcepacks"
$OptionsFile = "options.txt"

# --- 1. Чтение текущих включенных ресурспаков из options.txt ---
$EnabledPacks = @{}
if (Test-Path $OptionsFile) {
    $OptionsContent = Get-Content $OptionsFile
    foreach ($Line in $OptionsContent) {
        if ($Line -match '^resourcePacks:\s*\[(.*)\]') {
            # Разбиваем строку по запятым, убираем кавычки и пробелы
            $RawPacks = $Matches[1] -split ','
            foreach ($RawPack in $RawPacks) {
                $CleanPack = $RawPack.Trim().Trim('"').Trim("'")
                # В options.txt они хранятся как "file/имя_файла.zip"
                if ($CleanPack -match '^file/(.*)') {
                    $EnabledPacks[$Matches[1]] = $true
                } elseif ($CleanPack -ne "vanilla" -and $CleanPack -ne "") {
                    $EnabledPacks[$CleanPack] = $true
                }
            }
            break
        }
    }
}

# --- 2. Сканирование папки ресурспаков ---
if (-not (Test-Path $ResourcePacksDir)) {
    Write-Host "[-] Папка '$ResourcePacksDir' не найдена!" -ForegroundColor Red
    exit
}

# Хэш-таблица для предотвращения дубликатов (ключ — имя файла/папки)
$PacksRegistry = @{}

# Шаг А: Парсим .pw.toml файлы (Packwiz)
$TomlFiles = Get-ChildItem -Path $ResourcePacksDir -Filter "*.pw.toml"
foreach ($File in $TomlFiles) {
    $Content = Get-Content $File.FullName -Raw
    $NameMatch = [regex]::Match($Content, 'name\s*=\s*"([^"]+)"')
    $FileMatch = [regex]::Match($Content, 'filename\s*=\s*"([^"]+)"')

    if ($NameMatch.Success -and $FileMatch.Success) {
        $FName = $FileMatch.Groups[1].Value
        $PacksRegistry[$FName] = [PSCustomObject]@{
            Name     = $NameMatch.Groups[1].Value
            FileName = $FName
            Selected = $EnabledPacks.ContainsKey($FName) # Авто-выбор из options.txt
        }
    }
}

# Шаг Б: Ищем обычные .zip файлы (которых не было в .pw.toml)
$ZipFiles = Get-ChildItem -Path $ResourcePacksDir -Filter "*.zip"
foreach ($File in $ZipFiles) {
    $FName = $File.Name
    if (-not $PacksRegistry.ContainsKey($FName)) {
        $PacksRegistry[$FName] = [PSCustomObject]@{
            Name     = $File.BaseName # Имя без расширения .zip
            FileName = $FName
            Selected = $EnabledPacks.ContainsKey($FName) # Авто-выбор из options.txt
        }
    }
}

# Шаг В: Ищем обычные распакованные папки (на всякий случай)
$PackFolders = Get-ChildItem -Path $ResourcePacksDir -Directory
foreach ($Folder in $PackFolders) {
    $FName = $Folder.Name
    if (-not $PacksRegistry.ContainsKey($FName)) {
        $PacksRegistry[$FName] = [PSCustomObject]@{
            Name     = $Folder.Name
            FileName = $FName
            Selected = $EnabledPacks.ContainsKey($FName)
        }
    }
}

# Превращаем хэш-таблицу в обычный массив для работы интерфейса
$Packs = @($PacksRegistry.Values)

if ($Packs.Count -eq 0) {
    Write-Host "[-] В папке '$ResourcePacksDir' не найдено ресурспаков (.zip или .pw.toml)!" -ForegroundColor Yellow
    exit
}

# --- 3. Интерактивный CLI Интерфейс ---
$CurrentLine = 0
Write-Host "`nИспользуйте стрелки " -NoNewline; Write-Host "ВВЕРХ/ВНИЗ" -ForegroundColor Yellow -NoNewline; Write-Host " для навигации, " -NoNewline
Write-Host "ПРОБЕЛ" -ForegroundColor Yellow -NoNewline; Write-Host " для выбора, " -NoNewline
Write-Host "ENTER" -ForegroundColor Green -NoNewline; Write-Host " для сохранения.`n"

$MenuTop = [console]::CursorTop
[console]::CursorVisible = $false

try {
    while ($true) {
        [console]::CursorTop = $MenuTop
        [console]::CursorLeft = 0
        
        for ($i = 0; $i -lt $Packs.Count; $i++) {
            $Prefix = if ($i -eq $CurrentLine) { ">" } else { " " }
            $Checkbox = if ($Packs[$i].Selected) { "[X]" } else { "[ ]" }
            
            $Color = if ($i -eq $CurrentLine) { "Cyan" } else { "White" }
            $CheckboxColor = if ($Packs[$i].Selected) { "Green" } else { "DarkGray" }

            Write-Host "$Prefix " -ForegroundColor $Color -NoNewline
            Write-Host "$Checkbox " -ForegroundColor $CheckboxColor -NoNewline
            Write-Host "$($Packs[$i].Name) " -ForegroundColor $Color -NoNewline
            Write-Host "($($Packs[$i].FileName))".PadRight(50) -ForegroundColor DarkGray
        }

        $Key = [console]::ReadKey($true).Key
        
        if ($Key -eq 'UpArrow') {
            $CurrentLine = ($CurrentLine - 1 + $Packs.Count) % $Packs.Count
        }
        elseif ($Key -eq 'DownArrow') {
            $CurrentLine = ($CurrentLine + 1) % $Packs.Count
        }
        elseif ($Key -eq 'Spacebar') {
            $Packs[$CurrentLine].Selected = -not $Packs[$CurrentLine].Selected
        }
        elseif ($Key -eq 'Enter') {
            break
        }
    }
}
finally {
    [console]::CursorVisible = $true
}

[console]::CursorTop = $MenuTop + $Packs.Count + 1

# --- 4. Формирование строки для options.txt ---
$SelectedFiles = @()
foreach ($Pack in $Packs) {
    if ($Pack.Selected) {
        $SelectedFiles += "`"file/$($Pack.FileName)`""
    }
}

# Базовый ванильный ресурспак всегда идет первым
$PacksString = "resourcePacks:[`"vanilla`""
if ($SelectedFiles.Count -gt 0) {
    $PacksString += "," + ($SelectedFiles -join ",")
}
$PacksString += "]"

# --- 5. Обновление или создание options.txt ---
if (Test-Path $OptionsFile) {
    $OptionsContent = Get-Content $OptionsFile
    $UpdatedContent = @()
    $LineReplaced = $false

    foreach ($Line in $OptionsContent) {
        if ($Line -match "^resourcePacks:") {
            $UpdatedContent += $PacksString
            $LineReplaced = $true
        } else {
            $UpdatedContent += $Line
        }
    }

    if (-not $LineReplaced) {
        $UpdatedContent += $PacksString
    }

    $UpdatedContent | Set-Content $OptionsFile -Encoding UTF8
    Write-Host "[+] Файл $OptionsFile успешно обновлен!" -ForegroundColor Green
    Write-Host "Новое значение: $PacksString`n" -ForegroundColor DarkGray
} else {
    Write-Host "[!] Файл $OptionsFile не найден! Создан новый конфигурационный файл." -ForegroundColor Yellow
    $PacksString | Set-Content $OptionsFile -Encoding UTF8
}