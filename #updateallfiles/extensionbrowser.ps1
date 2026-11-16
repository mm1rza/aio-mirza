# ==============================================================================
#  AIO MIRZA - BROWSER EXTENSION INSTALLER (INDEPENDEN)
#  - Mengunduh ekstensi browser (IPvFoo & TikTok HD Extension)
#  - Mode Fresh Replace: Unduh tuntas -> Kosongkan isi folder lama -> Pasang baru
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
Write-Host "Metode Pasang    : Fresh Replace (Unduh ZIP -> Kosongkan -> Pasang)" -ForegroundColor White
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
    @{ 
        Name = "IPvFoo"
        Url  = "https://github.com/mm1rza/ipvfoo/archive/refs/heads/master.zip" 
    },
    @{ 
        Name = "tiktok-hd-extension"
        Url  = "https://github.com/mm1rza/tiktok-hd-extension/archive/refs/heads/main.zip" 
    }
)

$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$successCount = 0

foreach ($ext in $extensions) {
    $name = $ext.Name
    $url  = $ext.Url
    $targetPath  = Join-Path $extBaseDir $name
    $uniqueId    = [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $tempZip     = Join-Path $env:TEMP "$name-$uniqueId.zip"
    $tempExtract = Join-Path $env:TEMP "$name-extract-$uniqueId"

    Write-Host ""
    Write-Host "----------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "[$name] Memulai proses instalasi ekstensi..." -ForegroundColor Cyan
    Write-Host "[$name] Mengunduh arsip ZIP dari $url..." -ForegroundColor Yellow

    Wait-ForInternet

    try {
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }

        # 1. Unduh ZIP sampai tuntas ke folder temporary
        $wc.DownloadFile($url, $tempZip)

        if (-not (Test-Path $tempZip) -or ((Get-Item $tempZip).Length -eq 0)) {
            throw "File ZIP gagal diunduh atau ukuran berkas 0 byte."
        }

        $fileSizeMB = [math]::Round(((Get-Item $tempZip).Length / 1MB), 2)
        Write-Host "[$name] Unduhan tuntas ($fileSizeMB MB). Mengekstrak arsip..." -ForegroundColor Yellow

        # 2. Ekstrak arsip ZIP ke folder temporary
        Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

        # Deteksi direktori hasil ekstrak (GitHub biasanya membungkus dalam 1 root folder, e.g. repo-master/repo-main)
        $extractedFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
        $sourcePath = if ($extractedFolder) { $extractedFolder.FullName } else { $tempExtract }

        $items = Get-ChildItem -Path $sourcePath -Force
        if (-not $items -or $items.Count -eq 0) {
            throw "Tidak ditemukan file atau direktori di dalam arsip ZIP hasil ekstrak."
        }

        # 3. Kosongkan dulu isi file di folder tujuan agar benar-benar fresh
        if (Test-Path $targetPath) {
            Write-Host "[$name] Mengosongkan seluruh isi folder lama di $targetPath..." -ForegroundColor Gray
            Get-ChildItem -Path $targetPath -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "[$name] Membuat folder tujuan di $targetPath..." -ForegroundColor Gray
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        }

        # 4. Pindahkan semua file baru ke lokasi ekstensi
        Write-Host "[$name] Memindahkan file baru ke $targetPath..." -ForegroundColor Yellow
        $items | Move-Item -Destination $targetPath -Force

        Write-Host "[$name] Sukses dipasang secara fresh ke: $targetPath" -ForegroundColor Green
        $successCount++

    } catch {
        Write-Host "[$name] Gagal memasang ekstensi: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        # Bersihkan file dan folder sementara
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
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
