$modsDir = "mods"
$packwizCmd = "packwiz" # Если packwiz.exe лежит в этой же папке, замени на ".\packwiz.exe"

# Проверка рабочей директории
if (-Not (Test-Path $modsDir)) {
    Write-Host "Папка 'mods' не найдена! Убедись, что скрипт запущен из корня сборки Packwiz." -ForegroundColor Red
    Exit
}

$modFiles = Get-ChildItem -Path $modsDir -Filter *.toml

$successCount = 0
$failCount = 0
$failedMods = @()

foreach ($mod in $modFiles) {
    # Читаем содержимое файла мода
    $content = Get-Content $mod.FullName -Raw
    
    # Ищем блок [update.curseforge]
    if ($content -match '\[update\.curseforge\]') {
        # Имя файла без расширения в 90% случаев совпадает со слагом мода
        $modSlug = $mod.BaseName 
        
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        Write-Host "Миграция мода: $modSlug" -ForegroundColor Yellow
        
        # Удаляем старый файл CurseForge
        & $packwizCmd remove $modSlug | Out-Null
        
        # Пытаемся установить с Modrinth (-y автоматически соглашается на первый найденный вариант)
        $installResult = & $packwizCmd modrinth install $modSlug -y 2>&1
        
        # Проверяем успешность установки по коду возврата packwiz
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] $modSlug успешно скачан с Modrinth!" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "[X] Не удалось найти $modSlug на Modrinth (или требуется ручной выбор)." -ForegroundColor Red
            
            # Восстанавливаем CurseForge версию из памяти
            Set-Content -Path $mod.FullName -Value $content
            Write-Host "[-] CurseForge версия восстановлена." -ForegroundColor DarkGray
            
            $failCount++
            $failedMods += $modSlug
        }
    }
}

Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Готово!" -ForegroundColor Green
Write-Host "Успешно перенесено: $successCount"
Write-Host "Остались на CurseForge: $failCount" -ForegroundColor Yellow

if ($failedMods.Count -gt 0) {
    Write-Host "`nЭти моды нужно поискать вручную (возможно, у них другое название на Modrinth):"
    $failedMods | ForEach-Object { Write-Host "- $_" -ForegroundColor DarkGray }
}

# Обновляем индекс сборки в конце
Write-Host "`nОбновление индекса (packwiz refresh)..." -ForegroundColor Cyan
& $packwizCmd refresh