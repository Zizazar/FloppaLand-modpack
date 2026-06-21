$modsDir = ".\mods"
$outputFile = "MODLIST.md"

if (-not (Test-Path $modsDir)) {
    Write-Host "Папка $modsDir не найдена!" -ForegroundColor Red
    exit
}

$mods = @()

# Читаем все .toml файлы в папке mods
Get-ChildItem -Path $modsDir -Filter *.toml | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    # Парсим название
    $name = if ($content -match 'name\s*=\s*"([^"]+)"') { $Matches[1] } else { $_.Name }
    
    # Парсим сторону (client, server, both)
    $side = if ($content -match 'side\s*=\s*"([^"]+)"') { $Matches[1] } else { "both" }
    
    # Ищем ID мода для генерации ссылок
    $link = ""
    if ($content -match '\[update\.modrinth\][\s\S]*?mod-id\s*=\s*"([^"]+)"') {
        $link = "[Modrinth](https://modrinth.com/mod/$($Matches[1]))"
    } elseif ($content -match '\[update\.curseforge\][\s\S]*?project-id\s*=\s*(\d+)') {
        $link = "[CurseForge](https://www.curseforge.com/projects/$($Matches[1]))"
    }
    
    $mods += [PSCustomObject]@{ Name = $name; Side = $side; Link = $link }
}

$mods = $mods | Sort-Object Name

$builder = New-Object System.Text.StringBuilder
[void]$builder.AppendLine("## Mods List")
[void]$builder.AppendLine("")
[void]$builder.AppendLine("| Name | Side | Mod page |")
[void]$builder.AppendLine("|---|---|---|")

foreach ($mod in $mods) {
    $sideText = switch ($mod.Side) {
        "client" { "Client" }
        "server" { "Server" }
        default { "Both" }
    }
    [void]$builder.AppendLine("| **$($mod.Name)** | $sideText | $($mod.Link) |")
}

$builder.ToString() | Out-File $outputFile -Encoding utf8
Write-Host "Modlist generated to $outputFile" -ForegroundColor Green