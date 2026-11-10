# ==============================================================================
#  AIO MIRZA - LAUNCHER MENU
#  File ini dipanggil langsung via link pendek: https://mnet.my.id/update/github/aio
#  Mendukung multi-selection (contoh: 1, 1-4, 1234, atau 1,3,4)
# ==============================================================================

function Get-UserChoices {
    param ([string]$raw)
    $clean = $raw.Trim()

    # Format angka langsung rapat, contoh "134" atau "1234"
    if ($clean -match '^[1-4]+$') {
        return ($clean.ToCharArray() | ForEach-Object { "$_" } | Select-Object -Unique | Sort-Object)
    }

    $results = New-Object System.Collections.Generic.List[string]
    $tokens = $clean -split '[\s,;]+' | Where-Object { $_ -ne '' }

    foreach ($token in $tokens) {
        # Format rentang di dalam token, contoh "3-4" atau "1-3"
        if ($token -match '^([1-4])\s*-\s*([1-4])$') {
            $start = [int]$matches[1]
            $end   = [int]$matches[2]
            $start..$end | ForEach-Object {
                $d = "$_"
                if (-not $results.Contains($d)) { $results.Add($d) }
            }
        } elseif ($token -match '^[1-4]$') {
            if (-not $results.Contains($token)) { $results.Add($token) }
        } elseif ($token -match '^[1-4]+$') {
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
Write-Host "2. Install Spotify Anti-Iklan" -ForegroundColor White
Write-Host "3. Download & Sinkronisasi File AIO ke C:\#mirza" -ForegroundColor White
Write-Host "4. Extension Browser (IPvFoo & TikTok HD Extension)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Tips: Bisa pilih lebih dari 1 (contoh: 1, 1-4, 1234, atau 1,4)" -ForegroundColor Gray
$inputChoice = Read-Host "Masukkan pilihan Anda"

$selectedChoices = Get-UserChoices -raw $inputChoice

if (-not $selectedChoices -or $selectedChoices.Count -eq 0) {
    Write-Host "Pilihan tidak valid. Silakan jalankan ulang skrip." -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}

Write-Host ""
Write-Host "Menjalankan menu terpilih: $($selectedChoices -join ', ')..." -ForegroundColor Green
Start-Sleep -Milliseconds 600

foreach ($choice in $selectedChoices) {
    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host ">>> [1/4] Menjalankan Aktivasi Windows dan Office..." -ForegroundColor Cyan
            $masUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aHR0cHM6Ly9nZXQuYWN0aXZhdGVkLndpbg=='))
            Invoke-RestMethod $masUrl | Invoke-Expression
        }
        "2" {
            Write-Host ""
            Write-Host ">>> [2/4] Menjalankan Install Spotify Anti-Iklan..." -ForegroundColor Cyan
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
            $btsUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL21ycG9uZC9CbG9ja1RoZVNwb3QvbWFzdGVyL2luc3RhbGwucHMx'))
            $btsScript = (New-Object System.Net.WebClient).DownloadString($btsUrl)
            $sb = [scriptblock]::Create($btsScript)
            & $sb -UninstallSpotifyStoreEdition -UpdateSpotify
        }
        "3" {
            Write-Host ""
            Write-Host ">>> [3/4] Menjalankan Updater AIO Mirza ke C:\#mirza..." -ForegroundColor Cyan
            $updaterUrl = 'https://raw.githubusercontent.com/mm1rza/aio-mirza/main/%23updateallfiles/update.ps1'
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iex (iwr '$updaterUrl' -UseBasicParsing)`"" -Verb RunAs
        }
        "4" {
            Write-Host ""
            Write-Host ">>> [4/4] Mengunduh Extension Browser (Force Replace)..." -ForegroundColor Cyan
            Write-Host "==========================================================" -ForegroundColor Cyan

            $extBaseDir = "C:\#mirza\ChromeExtension"
            if (-not (Test-Path $extBaseDir)) {
                New-Item -ItemType Directory -Path $extBaseDir -Force | Out-Null
            }

            $extensions = @(
                @{ Name = "IPvFoo"; Repo = "https://github.com/mm1rza/ipvfoo" },
                @{ Name = "tiktok-hd-extension"; Repo = "https://github.com/mm1rza/tiktok-hd-extension" }
            )

            foreach ($ext in $extensions) {
                $name = $ext.Name
                $targetPath = Join-Path $extBaseDir $name
                $tempZip = Join-Path $env:TEMP "$name.zip"
                $tempExtract = Join-Path $env:TEMP "$name-extract"

                Write-Host "Mengunduh ekstensi $name dari $($ext.Repo)..." -ForegroundColor Yellow

                $wc = New-Object System.Net.WebClient
                $downloaded = $false
                $lastErr = ""

                foreach ($branch in @("main", "master")) {
                    try {
                        $zipUrl = "$($ext.Repo)/archive/refs/heads/$branch.zip"
                        $wc.DownloadFile($zipUrl, $tempZip)
                        $downloaded = $true
                        break
                    } catch {
                        $lastErr = $_.Exception.Message
                    }
                }

                if ($downloaded -and (Test-Path $tempZip)) {
                    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
                    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

                    $extractedFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1

                    if ($extractedFolder) {
                        # Wajib REPLACE: hapus folder lama jika sudah ada lalu ganti dengan versi terbaru
                        if (Test-Path $targetPath) {
                            Write-Host "Menghapus versi lama di $targetPath (REPLACE)..." -ForegroundColor Gray
                            Remove-Item $targetPath -Recurse -Force
                        }
                        Move-Item -Path $extractedFolder.FullName -Destination $targetPath -Force
                        Write-Host "[$name] Berhasil dipasang (REPLACE) ke: $targetPath" -ForegroundColor Green
                    }

                    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
                    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
                } else {
                    Write-Host "[$name] Gagal mengunduh: $lastErr (Periksa apakah repo bersifat Public / URL benar)" -ForegroundColor Red
                }
            }

            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host " Selesai memproses ekstensi browser." -ForegroundColor Green
            Write-Host "==========================================================" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Semua tugas terpilih selesai dijalankan!" -ForegroundColor Green
Read-Host "Tekan Enter untuk keluar..."
