$modsDir = ".\mods"
$outputFile = "MODLIST.md"
$jsonOutputFile = "MODLIST.json"

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

    # Парсим имя файла
    $filename = if ($content -match 'filename\s*=\s*"([^"]+)"') { $Matches[1] } else { "" }

    # Парсим сторону (client, server, both)
    $side = if ($content -match 'side\s*=\s*"([^"]+)"') { $Matches[1] } else { "both" }

    # Парсим URL загрузки и страницу
    $downloadUrl = ""
    $pageUrl = ""

    if ($content -match '\[update\.modrinth\][\s\S]*?mod-id\s*=\s*"([^"]+)"') {
        $modId = $Matches[1]
        $pageUrl = "https://modrinth.com/mod/$modId"
        $downloadUrl = if ($content -match '(?ms)^\[download\][\s\S]*?url\s*=\s*"([^"]+)"') { $Matches[1] } else { $pageUrl }
    } elseif ($content -match '\[update\.curseforge\][\s\S]*?project-id\s*=\s*(\d+)') {
        $projectId = $Matches[1]
        $pageUrl = "https://www.curseforge.com/projects/$projectId"
        $fileId = if ($content -match '\[update\.curseforge\][\s\S]*?file-id\s*=\s*(\d+)') { $Matches[1] } else { "" }
        $downloadUrl = if ($fileId) { "https://www.curseforge.com/projects/$projectId/files/$fileId" } else { $pageUrl }
    }

    # Парсим платформу и версию
    $platform = ""
    $version = ""
    if ($content -match '(?ms)\[update\.modrinth\]') {
        $platform = "modrinth"
        if ($content -match '(?ms)\[update\.modrinth\][\s\S]*?version\s*=\s*"([^"]+)"') {
            $version = $Matches[1]
        }
    } elseif ($content -match '(?ms)\[update\.curseforge\]') {
        $platform = "curseforge"
        if ($content -match '(?ms)\[update\.curseforge\][\s\S]*?file-id\s*=\s*(\d+)') {
            $version = $Matches[1]
        }
    }

    # Ищем ID мода для генерации ссылок
    $link = ""
    if ($content -match '\[update\.modrinth\][\s\S]*?mod-id\s*=\s*"([^"]+)"') {
        $link = "[Modrinth](https://modrinth.com/mod/$($Matches[1]))"
    } elseif ($content -match '\[update\.curseforge\][\s\S]*?project-id\s*=\s*(\d+)') {
        $link = "[CurseForge](https://www.curseforge.com/projects/$($Matches[1]))"
    }

    $mods += [PSCustomObject]@{
        Name = $name
        Version = $version
        Filename = $filename
        DownloadUrl = $downloadUrl
        PageUrl = $pageUrl
        Platform = $platform
        Side = $side
        Link = $link
    }
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

$jsonMods = $mods | ForEach-Object {
    [ordered]@{
        name = $_.Name
        version = $_.Version
        filename = $_.Filename
        download_url = $_.DownloadUrl
        page_url = $_.PageUrl
        platform = $_.Platform
        side = $_.Side
    }
}

$jsonMods | ConvertTo-Json -Depth 6 | Out-File $jsonOutputFile -Encoding utf8

Write-Host "Modlist generated to $outputFile and $jsonOutputFile" -ForegroundColor Green