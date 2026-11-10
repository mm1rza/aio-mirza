# ==============================================================================
#  AIO MIRZA - AUTO UPDATER & INCREMENTAL SYNC (GITHUB)
#  - Mengunduh berkas satu per satu secara modular (Tanpa ZIP besar)
#  - Memeriksa perubahan berkas (Hanya mengunduh file yang baru/berubah)
#  - Aman dari putus koneksi (Jika internet mati, menunggu dan melanjutkan sisa)
# ==============================================================================

# Aktifkan dukungan TLS 1.2 & 1.3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

$targetDir    = "C:\#mirza"
$manifestUrl  = "https://raw.githubusercontent.com/mm1rza/aio-mirza/main/%23updateallfiles/manifest.json"
$versionUrl   = "https://raw.githubusercontent.com/mm1rza/aio-mirza/main/%23updateallfiles/version.txt"

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
    param ([string]$targetUrl = "https://raw.githubusercontent.com")
    if (-not (Test-Internet -url $targetUrl)) {
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Red
        Write-Host " [!] KONEKSI INTERNET TERPUTUS / TIDAK TERDETEKSI" -ForegroundColor Red
        Write-Host "==========================================================" -ForegroundColor Red
        Write-Host " Menunggu koneksi internet aktif kembali..." -ForegroundColor Yellow
        Write-Host " Harap periksa kabel LAN atau sambungan Wi-Fi komputer ini." -ForegroundColor Cyan
        Write-Host " Jendela TIDAK akan tertutup. (Tekan Ctrl+C untuk membatalkan)" -ForegroundColor Gray
        Write-Host "==========================================================" -ForegroundColor Red

        $dotCount = 1
        while (-not (Test-Internet -url $targetUrl)) {
            Write-Host -NoNewline "`r Menunggu koneksi internet$('.' * $dotCount)      " -ForegroundColor Yellow
            $dotCount = ($dotCount % 5) + 1
            Start-Sleep -Seconds 3
        }
        Write-Host ""
        Write-Host "[OK] Koneksi internet kembali aktif! Melanjutkan proses..." -ForegroundColor Green
        Start-Sleep -Seconds 1
    }
}

function Get-GitHubRawUrl {
    param ([string]$RelativePath)
    $segments = $RelativePath.Split('/') | ForEach-Object {
        [System.Uri]::EscapeDataString($_)
    }
    return "https://raw.githubusercontent.com/mm1rza/aio-mirza/main/" + ($segments -join '/')
}

function Format-FileSize {
    param ([long]$Bytes)
    if ($Bytes -ge 1MB) {
        return "$([math]::Round($Bytes / 1MB, 2)) MB"
    } elseif ($Bytes -ge 1KB) {
        return "$([math]::Round($Bytes / 1KB, 1)) KB"
    } else {
        return "$Bytes B"
    }
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         AIO MIRZA - INCREMENTAL UPDATER (GITHUB)         " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Direktori Target : $targetDir" -ForegroundColor White

# Pastikan folder target ada
if (-not (Test-Path $targetDir)) {
    Write-Host "Membuat direktori instalasi $targetDir..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# 1. Unduh manifest.json dari GitHub
Write-Host "Memeriksa daftar berkas terbaru dari GitHub..." -ForegroundColor Yellow
Wait-ForInternet -targetUrl $manifestUrl

$remoteManifest = $null
while ($null -eq $remoteManifest) {
    try {
        $wc = New-Object System.Net.WebClient
        $manifestJson = $wc.DownloadString($manifestUrl)
        $remoteManifest = $manifestJson | ConvertFrom-Json
    } catch {
        Write-Host "Gagal mengambil manifest dari server: $($_.Exception.Message)" -ForegroundColor Red
        Wait-ForInternet -targetUrl $manifestUrl
    }
}

Write-Host "Manifest berhasil dimuat ($($remoteManifest.Count) berkas terdaftar di cloud)." -ForegroundColor Green

# 2. Pindai berkas lokal dan bandingkan (Hanya tandai yang berbeda/belum ada)
Write-Host "Menganalisis berkas lokal di $targetDir..." -ForegroundColor Yellow

$needsDownload = New-Object System.Collections.Generic.List[PSObject]
$alreadyUpToDate = 0

foreach ($item in $remoteManifest) {
    $localFilePath = Join-Path $targetDir ($item.Path -replace '/', '\')
    
    if (Test-Path $localFilePath) {
        $localItem = Get-Item -Path $localFilePath
        # Cek ukuran terlebih dahulu untuk efisiensi
        if ($localItem.Length -eq $item.Size) {
            # Jika ukuran sama, verifikasi hash MD5
            $localHash = (Get-FileHash -Path $localFilePath -Algorithm MD5).Hash
            if ($localHash -eq $item.Hash) {
                $alreadyUpToDate++
                continue
            }
        }
    }
    # Berkas belum ada atau berbeda
    $needsDownload.Add($item)
}

Write-Host "Status Analisis: $alreadyUpToDate berkas sudah cocok (Up-to-Date)." -ForegroundColor Green

# 3. Jika semua berkas sudah cocok
if ($needsDownload.Count -eq 0) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host " Semua berkas di $targetDir sudah versi TERBARU!" -ForegroundColor Green
    Write-Host " Tidak ada berkas yang perlu diunduh." -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    
    $force = Read-Host "Apakah Anda ingin memaksa unduh ulang seluruh berkas? (Y/N)"
    if ($force -eq 'Y' -or $force -eq 'y') {
        $needsDownload.AddRange($remoteManifest)
    } else {
        Write-Host ""
        Read-Host "Tekan Enter untuk menutup jendela..."
        exit
    }
}

# 4. Hitung total data yang perlu diunduh
$totalBytes = ($needsDownload | Measure-Object -Property Size -Sum).Sum
$totalSizeStr = Format-FileSize -Bytes $totalBytes

Write-Host ""
Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
Write-Host " Berkas yang akan diunduh : $($needsDownload.Count) berkas" -ForegroundColor Yellow
Write-Host " Total ukuran unduhan     : $totalSizeStr (Hanya berkas yang berubah)" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
Write-Host ""

# 5. Unduh berkas satu per satu
$currentIndex = 0
$totalCount = $needsDownload.Count

foreach ($item in $needsDownload) {
    $currentIndex++
    $localFilePath = Join-Path $targetDir ($item.Path -replace '/', '\')
    $parentDir = Split-Path $localFilePath -Parent
    
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $rawUrl = Get-GitHubRawUrl -RelativePath $item.Path
    $fileSizeStr = Format-FileSize -Bytes $item.Size

    Write-Host "[$currentIndex/$totalCount] ($fileSizeStr) $($item.Path)... " -NoNewline -ForegroundColor White

    $downloadSuccess = $false
    $tempFile = "$localFilePath.downloading"

    while (-not $downloadSuccess) {
        Wait-ForInternet -targetUrl $rawUrl
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($rawUrl, $tempFile)
            
            # Verifikasi integritas berkas hasil unduhan
            $downloadedSize = (Get-Item $tempFile).Length
            if ($downloadedSize -eq $item.Size) {
                if (Test-Path $localFilePath) {
                    Remove-Item $localFilePath -Force
                }
                Move-Item -Path $tempFile -Destination $localFilePath -Force
                $downloadSuccess = $true
                Write-Host "[OK]" -ForegroundColor Green
            } else {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                Write-Host "[Corrupt, Mengulang...]" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        } catch {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            Write-Host "[Gagal: $($_.Exception.Message)]" -ForegroundColor Red
            Wait-ForInternet -targetUrl $rawUrl
        }
    }
}

# 6. Pembersihan berkas usang (yang sudah dihapus di GitHub, selain cache user)
Write-Host ""
Write-Host "Membersihkan berkas usang..." -ForegroundColor Yellow
$manifestPaths = @{}
foreach ($item in $remoteManifest) {
    $norm = ($item.Path -replace '/', '\').ToLower()
    $manifestPaths[$norm] = $true
}

$localFiles = Get-ChildItem -Path $targetDir -Recurse -File | Where-Object {
    $rel = $_.FullName.Substring($targetDir.Length + 1).ToLower()
    # Pengecualian: jangan hapus file download sementara, README, atau cache winbox
    -not ($rel -like "*.downloading" -or 
          $rel -like "appportable\cachewinbox\*" -or
          $rel -eq "readme.md")
}

$deletedCount = 0
foreach ($lf in $localFiles) {
    $rel = $lf.FullName.Substring($targetDir.Length + 1).ToLower()
    if (-not $manifestPaths.ContainsKey($rel)) {
        Remove-Item $lf.FullName -Force -ErrorAction SilentlyContinue
        $deletedCount++
    }
}

if ($deletedCount -gt 0) {
    Write-Host "Berhasil menghapus $deletedCount berkas usang dari $targetDir." -ForegroundColor Yellow
}

# 7. Simpan manifest lokal & perbarui version.txt
$localManifestPath = Join-Path $targetDir "#updateallfiles\manifest.json"
$remoteManifest | ConvertTo-Json -Compress | Set-Content -Path $localManifestPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   SINKRONISASI SELESAI DENGAN SUKSES!" -ForegroundColor Green
Write-Host "   Semua berkas di $targetDir telah diperbarui." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Tekan Enter untuk menutup jendela..."
