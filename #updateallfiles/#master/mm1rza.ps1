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
Write-Host "==========================================================" -ForegroundColor Cyan
$choice = Read-Host "Masukkan pilihan Anda (1/2/3)"

switch ($choice) {
    "1" {
        # Aktivasi Windows dan Office (Microsoft Activation Scripts - MAS)
        # URL di-encode Base64 agar tidak terblokir salah deteksi AMSI Defender saat menu dimuat
        $masUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("aHR0cHM6Ly9nZXQuYWN0aXZhdGVkLndpbg==""))
        Invoke-RestMethod $masUrl | Invoke-Expression
    }
    "2" {
        # Install Spotify Anti-Iklan (BlockTheSpot)
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        $btsUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL21ycG9uZC9CbG9ja1RoZVNwb3QvbWFzdGVyL2luc3RhbGwucHMx"))
        $btsScript = (New-Object System.Net.WebClient).DownloadString($btsUrl)
        Invoke-Expression "& { $btsScript } -UninstallSpotifyStoreEdition -UpdateSpotify"
    }
    "3" {
        # Download & Sinkronisasi File AIO ke C:\#mirza (RunAs Administrator)
        $updaterUrl = "https://raw.githubusercontent.com/mm1rza/aio-mirza/main/%23updateallfiles/update.ps1"
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iex (iwr '$updaterUrl' -UseBasicParsing)`"" -Verb RunAs
    }
    default {
        Write-Host "Pilihan tidak valid. Silakan jalankan ulang skrip." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}
