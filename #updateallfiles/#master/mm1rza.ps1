# ==============================================================================
#  AIO MIRZA - LAUNCHER MENU
#  File ini dipanggil langsung via link pendek: https://mnet.my.id/update/github/aio
#  Mendukung multi-selection (contoh: 1, 1-3, 123, atau 1,3)
# ==============================================================================

function Get-UserChoices {
    param ([string]$raw)
    $clean = $raw.Trim()

    # Format angka langsung rapat, contoh "123" atau "13"
    if ($clean -match '^[1-3]+$') {
        return ($clean.ToCharArray() | ForEach-Object { "$_" } | Select-Object -Unique | Sort-Object)
    }

    $results = New-Object System.Collections.Generic.List[string]
    $tokens = $clean -split '[\s,;]+' | Where-Object { $_ -ne '' }

    foreach ($token in $tokens) {
        # Format rentang di dalam token, contoh "2-3" atau "1-3"
        if ($token -match '^([1-3])\s*-\s*([1-3])$') {
            $start = [int]$matches[1]
            $end   = [int]$matches[2]
            $start..$end | ForEach-Object {
                $d = "$_"
                if (-not $results.Contains($d)) { $results.Add($d) }
            }
        } elseif ($token -match '^[1-3]$') {
            if (-not $results.Contains($token)) { $results.Add($token) }
        } elseif ($token -match '^[1-3]+$') {
            $token.ToCharArray() | ForEach-Object {
                $d = "$_"
                if (-not $results.Contains($d)) { $results.Add($d) }
            }
        }
    }
    return ($results | Sort-Object)
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                AIO MIRZA - MENU UTAMA                    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "1. Aktivasi Windows dan Office" -ForegroundColor White
Write-Host "2. Download & Sinkronisasi File AIO ke C:\#mirza" -ForegroundColor White
Write-Host "3. Extension Browser (IPvFoo & TikTok HD Extension)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Tips: Bisa pilih lebih dari 1 (contoh: 1, 1-3, 123, atau 1,3)" -ForegroundColor Gray
$inputChoice = Read-Host "Masukkan pilihan Anda"

$selectedChoices = Get-UserChoices -raw $inputChoice

if (-not $selectedChoices -or $selectedChoices.Count -eq 0) {
    Write-Host "Pilihan tidak valid. Silakan jalankan ulang skrip." -ForegroundColor Red
    return
}

Write-Host ""
Write-Host "Menjalankan menu terpilih: $($selectedChoices -join ', ')..." -ForegroundColor Green
Start-Sleep -Milliseconds 600

foreach ($choice in $selectedChoices) {
    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host ">>> [1/3] Menjalankan Aktivasi Windows dan Office..." -ForegroundColor Cyan
            $masUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aHR0cHM6Ly9nZXQuYWN0aXZhdGVkLndpbg=='))
            Invoke-RestMethod $masUrl | Invoke-Expression
        }
        "2" {
            Write-Host ""
            Write-Host ">>> [2/3] Menjalankan Updater AIO Mirza ke C:\#mirza..." -ForegroundColor Cyan
            $updaterUrl = 'https://raw.githubusercontent.com/mm1rza/aio-mirza/main/%23updateallfiles/update.ps1'
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iex (iwr '$updaterUrl' -UseBasicParsing)`"" -Verb RunAs
        }
        "3" {
            Write-Host ""
            Write-Host ">>> [3/3] Menjalankan Installer Extension Browser..." -ForegroundColor Cyan
            $extUrl = 'https://raw.githubusercontent.com/mm1rza/aio-mirza/main/%23updateallfiles/extensionbrowser.ps1'
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iex (iwr '$extUrl' -UseBasicParsing)`"" -Verb RunAs
        }
    }
}

Write-Host ""
Write-Host "Semua tugas terpilih selesai dijalankan!" -ForegroundColor Green
