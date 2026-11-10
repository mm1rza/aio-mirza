# ==============================================================================
#  AIO MIRZA - LAUNCHER MENU
#  File ini dipanggil langsung via link pendek: https://mnet.my.id/update/github/aio
# ==============================================================================

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                AIO MIRZA - MENU UTAMA                    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "1. Aktivasi Windows dan Office" -ForegroundColor White
Write-Host "2. Install Spotify Anti-Iklan" -ForegroundColor White
Write-Host "3. Download & Sinkronisasi File AIO ke C:\#mirza" -ForegroundColor White
Write-Host "4. Extension Browser (IPvFoo & TikTok HD Extension)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
$choice = Read-Host "Masukkan pilihan Anda (1/2/3/4)"

switch ($choice) {
    "1" {
        # Aktivasi Windows dan Office (Microsoft Activation Scripts - MAS)
        $masUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aHR0cHM6Ly9nZXQuYWN0aXZhdGVkLndpbg=='))
        Invoke-RestMethod $masUrl | Invoke-Expression
    }
    "2" {
        # Install Spotify Anti-Iklan (BlockTheSpot)
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        $btsUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL21ycG9uZC9CbG9ja1RoZVNwb3QvbWFzdGVyL2luc3RhbGwucHMx'))
        $btsScript = (New-Object System.Net.WebClient).DownloadString($btsUrl)
        $sb = [scriptblock]::Create($btsScript)
        & $sb -UninstallSpotifyStoreEdition -UpdateSpotify
    }
    "3" {
        # Download & Sinkronisasi File AIO ke C:\#mirza (RunAs Administrator)
        $updaterUrl = 'https://raw.githubusercontent.com/mm1rza/aio-mirza/main/%23updateallfiles/update.ps1'
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iex (iwr '$updaterUrl' -UseBasicParsing)`"" -Verb RunAs
    }
    "4" {
        # Download & Pasang Extension Browser (IPvFoo & tiktok-hd-extension)
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "              MENGUNDUH EXTENSION BROWSER                 " -ForegroundColor Cyan
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
            foreach ($branch in @("main", "master")) {
                try {
                    $zipUrl = "$($ext.Repo)/archive/refs/heads/$branch.zip"
                    $wc.DownloadFile($zipUrl, $tempZip)
                    $downloaded = $true
                    break
                } catch {}
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
                Write-Host "[$name] Gagal mengunduh berkas dari GitHub." -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host " Semua extension browser berhasil diunduh & diperbarui!  " -ForegroundColor Green
        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host ""
        Read-Host "Tekan Enter untuk kembali..."
    }
    default {
        Write-Host "Pilihan tidak valid. Silakan jalankan ulang skrip." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}
