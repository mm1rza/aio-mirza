# ==============================================================================
#  AIO MIRZA - BROWSER EXTENSION INSTALLER (INDEPENDEN)
#  - Mengunduh ekstensi browser (IPvFoo & TikTok HD Extension)
#  - Mode Force Replace: Menimpa bersih versi lama dengan versi terbaru dari GitHub
#  - Dapat dijalankan langsung secara mandiri atau melalui Menu Utama AIO
# ==============================================================================

# 1. Pastikan berjalan dengan hak Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Protokol Keamanan Jaringan
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         AIO MIRZA - BROWSER EXTENSION INSTALLER          " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Direktori Target : C:\#mirza\ChromeExtension" -ForegroundColor White
Write-Host "Metode Pasang    : Force Replace (Timpa Bersih)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

$extBaseDir = "C:\#mirza\ChromeExtension"
if (-not (Test-Path $extBaseDir)) {
    try {
        New-Item -ItemType Directory -Path $extBaseDir -Force | Out-Null
    } catch {
        Write-Host "[!] Gagal membuat direktori $($extBaseDir): $_" -ForegroundColor Red
        Start-Sleep -Seconds 3
        exit
    }
}

# Fungsi cek koneksi internet
function Test-Internet {
    param ([string]$url = "https://raw.githubusercontent.com")
    try {
        $req = [System.Net.WebRequest]::Create($url)
        $req.Timeout = 4000
        $req.Method = "HEAD"
        $resp = $req.GetResponse()
        $resp.Close()
        return $true
    } catch {
        return $false
    }
}

function Wait-ForInternet {
    if (-not (Test-Internet)) {
        Write-Host ""
        Write-Host "[!] Koneksi internet terputus. Menunggu sambungan kembali..." -ForegroundColor Yellow
        while (-not (Test-Internet)) {
            Start-Sleep -Seconds 3
        }
        Write-Host "[OK] Koneksi internet kembali aktif!" -ForegroundColor Green
    }
}

Wait-ForInternet

$extensions = @(
    @{ Name = "IPvFoo"; Repo = "https://github.com/mm1rza/ipvfoo" },
    @{ Name = "tiktok-hd-extension"; Repo = "https://github.com/mm1rza/tiktok-hd-extension" }
)

$wc = New-Object System.Net.WebClient
$successCount = 0

foreach ($ext in $extensions) {
    $name = $ext.Name
    $targetPath = Join-Path $extBaseDir $name
    $tempZip = Join-Path $env:TEMP "$name.zip"
    $tempExtract = Join-Path $env:TEMP "$name-extract"

    Write-Host ""
    Write-Host "[$name] Mengunduh ekstensi dari $($ext.Repo)..." -ForegroundColor Yellow

    Wait-ForInternet

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
        try {
            if (Test-Path $tempExtract) {
                Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
            }
            Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

            $extractedFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1

            if ($extractedFolder) {
                if (Test-Path $targetPath) {
                    Write-Host "[$name] Menghapus versi lama di $targetPath (REPLACE)..." -ForegroundColor Gray
                    Remove-Item $targetPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                Move-Item -Path $extractedFolder.FullName -Destination $targetPath -Force
                Write-Host "[$name] Berhasil dipasang (REPLACE) ke: $targetPath" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "[$name] Gagal mengekstrak isi arsip ZIP." -ForegroundColor Red
            }
        } catch {
            Write-Host "[$name] Terjadi kesalahan saat instalasi: $_" -ForegroundColor Red
        } finally {
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
            if (Test-Path $tempExtract) {
                Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        Write-Host "[$name] Gagal mengunduh: $lastErr" -ForegroundColor Red
        Write-Host "       (Periksa apakah repository bersifat Public atau tautan sudah benar)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "                   SINKRONISASI SUKSES                    " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Berhasil Dipasang : $successCount dari $($extensions.Count) ekstensi" -ForegroundColor White
Write-Host " Lokasi Folder     : $extBaseDir" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

# Hitung mundur penutupan otomatis (bisa ditutup cepat dengan menekan tombol apa saja)
try {
    for ($sec = 20; $sec -gt 0; $sec--) {
        if ([Console]::KeyAvailable) {
            [Console]::ReadKey($true) | Out-Null
            break
        }
        Write-Host -NoNewline "`rJendela tertutup otomatis dalam $sec detik... (Tekan sembarang tombol untuk keluar)   " -ForegroundColor Gray
        Start-Sleep -Seconds 1
    }
} catch {
    Start-Sleep -Seconds 3
}
Write-Host ""
