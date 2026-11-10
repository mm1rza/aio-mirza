# ==============================================================================
#  AIO MIRZA - AUTO UPDATER & INCREMENTAL MULTITHREADED SYNC (GITHUB)
#  - Mengunduh berkas satu per satu secara PARALEL (Multithreading 8 Thread)
#  - Memeriksa perubahan berkas (Hanya mengunduh file yang baru/berubah)
#  - Menggunakan manifest.json terpadu (Versi & Daftar Berkas dalam 1 File)
#  - Aman dari putus koneksi (Jika internet mati, menunggu dan melanjutkan sisa)
# ==============================================================================

# Aktifkan dukungan TLS 1.2 & 1.3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

$targetDir    = "C:\#mirza"
$manifestUrl  = "https://raw.githubusercontent.com/mm1rza/aio-mirza/main/%23updateallfiles/manifest.json"

# Otomatis deteksi CPU & tentukan thread optimal (minimal 8, maksimal 16)
$cpuCores     = [Environment]::ProcessorCount
$threadCount  = [math]::Min(16, [math]::Max(8, $cpuCores * 2))

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
Write-Host "     AIO MIRZA - SMART PARALLEL UPDATER (MULTITHREAD)     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Direktori Target : $targetDir" -ForegroundColor White
Write-Host "Deteksi Sistem   : $cpuCores CPU Threads -> Dialokasikan $threadCount Thread Paralel" -ForegroundColor Gray

# Pastikan folder target ada
if (-not (Test-Path $targetDir)) {
    Write-Host "Membuat direktori instalasi $targetDir..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# 1. Unduh manifest.json terpadu dari GitHub
Write-Host "Memeriksa manifest & versi terbaru dari GitHub..." -ForegroundColor Yellow
Wait-ForInternet -targetUrl $manifestUrl

$remoteData = $null
while ($null -eq $remoteData) {
    try {
        $wc = New-Object System.Net.WebClient
        $manifestJson = $wc.DownloadString($manifestUrl)
        $remoteData = $manifestJson | ConvertFrom-Json
    } catch {
        Write-Host "Gagal mengambil manifest dari server: $($_.Exception.Message)" -ForegroundColor Red
        Wait-ForInternet -targetUrl $manifestUrl
    }
}

# Dukung format baru (objek ber-versi) atau format lama (array berkas)
if ($remoteData.PSObject.Properties['version']) {
    $remoteVersion = $remoteData.version
    $remoteFiles   = $remoteData.files
} else {
    $remoteVersion = "Cloud"
    $remoteFiles   = $remoteData
}

Write-Host "Versi di Cloud   : $remoteVersion ($($remoteFiles.Count) berkas terdaftar)." -ForegroundColor Green

# 2. Cek versi lokal
$localManifestFile = Join-Path $targetDir "#updateallfiles\manifest.json"
$localVersion = $null

if (Test-Path $localManifestFile) {
    try {
        $localData = Get-Content $localManifestFile -Raw | ConvertFrom-Json
        if ($localData.PSObject.Properties['version']) {
            $localVersion = $localData.version
        }
    } catch {}
}

if ($localVersion) {
    Write-Host "Versi di Komputer: $localVersion" -ForegroundColor White
} else {
    Write-Host "Versi di Komputer: Belum terpasang (Instalasi Baru)" -ForegroundColor Gray
}

# 3. Pindai berkas lokal dan bandingkan (Hanya tandai yang berbeda/belum ada)
Write-Host "Menganalisis berkas lokal di $targetDir..." -ForegroundColor Yellow

$needsDownload = New-Object System.Collections.Generic.List[PSObject]
$alreadyUpToDate = 0

foreach ($item in $remoteFiles) {
    # Lewati berkas dokumentasi & git jika masih tercantum di manifest cloud
    if ($item.Path -eq 'README.md' -or 
        $item.Path -like 'README/*' -or 
        $item.Path -like '.git*' -or 
        $item.Path -eq '.gitattributes' -or 
        $item.Path -eq '.gitignore') {
        continue
    }

    $localFilePath = Join-Path $targetDir ($item.Path -replace '/', '\')
    
    if (Test-Path $localFilePath) {
        $localItem = Get-Item -Path $localFilePath
        # Cek ukuran terlebih dahulu untuk efisiensi kecepatan
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

Write-Host "Status Analisis  : $alreadyUpToDate berkas sudah cocok (Up-to-Date)." -ForegroundColor Green

# 4. Jika semua berkas sudah cocok
if ($needsDownload.Count -eq 0) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host " Semua berkas di $targetDir sudah versi TERBARU!" -ForegroundColor Green
    Write-Host " Tidak ada berkas yang perlu diunduh." -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    
    $force = Read-Host "Apakah Anda ingin memaksa unduh ulang seluruh berkas? (Y/N)"
    if ($force -eq 'Y' -or $force -eq 'y') {
        $needsDownload.AddRange($remoteFiles)
    } else {
        Write-Host ""
        Read-Host "Tekan Enter untuk menutup jendela..."
        exit
    }
}

# 5. Hitung total data yang perlu diunduh
$totalBytes = ($needsDownload | Measure-Object -Property Size -Sum).Sum
$totalSizeStr = Format-FileSize -Bytes $totalBytes

Write-Host ""
Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
Write-Host " Berkas yang akan diunduh : $($needsDownload.Count) berkas" -ForegroundColor Yellow
Write-Host " Total ukuran unduhan     : $totalSizeStr" -ForegroundColor Yellow
Write-Host " Kecepatan Unduh          : Multithread Paralel ($threadCount Thread)" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
Write-Host ""

# 6. Unduh berkas secara paralel menggunakan RunspacePool
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[psobject]'
foreach ($item in $needsDownload) {
    $queue.Enqueue($item)
}

$logQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$sync = [hashtable]::Synchronized(@{ Done = 0; Total = $needsDownload.Count })

$pool = [runspacefactory]::CreateRunspacePool(1, $threadCount)
$pool.Open()

$workerScript = {
    param ($q, $logs, $s, $destRoot)

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

    function Get-RawUrl {
        param ([string]$rel)
        $segs = $rel.Split('/') | ForEach-Object { [System.Uri]::EscapeDataString($_) }
        return "https://raw.githubusercontent.com/mm1rza/aio-mirza/main/" + ($segs -join '/')
    }

    function Format-Size {
        param ([long]$b)
        if ($b -ge 1MB) { return "$([math]::Round($b / 1MB, 2)) MB" }
        elseif ($b -ge 1KB) { return "$([math]::Round($b / 1KB, 1)) KB" }
        else { return "$b B" }
    }

    function Test-Net {
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

    $it = $null
    while ($q.TryDequeue([ref]$it)) {
        $localFilePath = Join-Path $destRoot ($it.Path -replace '/', '\')
        $parentDir = Split-Path $localFilePath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        $rawUrl = Get-RawUrl -rel $it.Path
        $fileSizeStr = Format-Size -b $it.Size
        $tempFile = "$localFilePath.downloading"
        $downloadSuccess = $false
        $corruptRetry = 0

        while (-not $downloadSuccess) {
            # Pastikan internet aktif sebelum mulai download
            while (-not (Test-Net -url $rawUrl)) {
                Start-Sleep -Seconds 2
            }

            try {
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($rawUrl, $tempFile)

                $downloadedSize = (Get-Item $tempFile).Length
                if ($downloadedSize -eq $it.Size) {
                    if (Test-Path $localFilePath) {
                        Remove-Item $localFilePath -Force
                    }
                    Move-Item -Path $tempFile -Destination $localFilePath -Force
                    $downloadSuccess = $true

                    # Hitung progres thread-safe
                    $cur = 0
                    [System.Threading.Monitor]::Enter($s)
                    try {
                        $s.Done++
                        $cur = $s.Done
                    } finally {
                        [System.Threading.Monitor]::Exit($s)
                    }

                    $logs.Enqueue("[$cur/$($s.Total) OK] ($fileSizeStr) $($it.Path)")
                } elseif ($downloadedSize -gt 0) {
                    # Jika ukuran berbeda (misal file teks CRLF vs LF di GitHub), tetap simpan file hasil unduhan
                    if (Test-Path $localFilePath) {
                        Remove-Item $localFilePath -Force
                    }
                    Move-Item -Path $tempFile -Destination $localFilePath -Force
                    $downloadSuccess = $true

                    $cur = 0
                    [System.Threading.Monitor]::Enter($s)
                    try {
                        $s.Done++
                        $cur = $s.Done
                    } finally {
                        [System.Threading.Monitor]::Exit($s)
                    }

                    $logs.Enqueue("[$cur/$($s.Total) DIF] ($fileSizeStr) $($it.Path)")
                } else {
                    $corruptRetry++
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                    if ($corruptRetry -ge 3) {
                        $cur = 0
                        [System.Threading.Monitor]::Enter($s)
                        try {
                            $s.Done++
                            $cur = $s.Done
                        } finally {
                            [System.Threading.Monitor]::Exit($s)
                        }
                        $logs.Enqueue("[$cur/$($s.Total) ERR] ($fileSizeStr) $($it.Path)")
                        break
                    } else {
                        Start-Sleep -Seconds 1
                    }
                }
            } catch {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
        }
    }
}

$workers = @()
1..$threadCount | ForEach-Object {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool
    $ps.AddScript($workerScript).AddArgument($queue).AddArgument($logQueue).AddArgument($sync).AddArgument($targetDir) | Out-Null
    $workers += @{ PS = $ps; Handle = $ps.BeginInvoke() }
}

# Tampilkan log unduhan secara real-time dari semua thread
while (($workers | Where-Object { -not $_.Handle.IsCompleted }).Count -gt 0) {
    $msg = $null
    while ($logQueue.TryDequeue([ref]$msg)) {
        if ($msg -like "* OK]*") {
            Write-Host $msg -ForegroundColor White
        } elseif ($msg -like "* DIF]*") {
            Write-Host $msg -ForegroundColor Yellow
        } else {
            Write-Host $msg -ForegroundColor Red
        }
    }
    Start-Sleep -Milliseconds 40
}

# Kuras sisa antrean log
$msg = $null
while ($logQueue.TryDequeue([ref]$msg)) {
    if ($msg -like "* OK]*") {
        Write-Host $msg -ForegroundColor White
    } elseif ($msg -like "* DIF]*") {
        Write-Host $msg -ForegroundColor Yellow
    } else {
        Write-Host $msg -ForegroundColor Red
    }
}

foreach ($w in $workers) {
    $w.PS.EndInvoke($w.Handle) | Out-Null
    $w.PS.Dispose()
}
$pool.Close()
$pool.Dispose()

$sw.Stop()
$elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)

# 7. Pembersihan berkas usang (yang sudah dihapus di GitHub, selain cache user)
Write-Host ""
Write-Host "Membersihkan berkas usang..." -ForegroundColor Yellow
$manifestPaths = @{}
foreach ($item in $remoteFiles) {
    $norm = ($item.Path -replace '/', '\').ToLower()
    $manifestPaths[$norm] = $true
}

$localFiles = Get-ChildItem -Path $targetDir -Recurse -File | Where-Object {
    $rel = $_.FullName.Substring($targetDir.Length + 1).ToLower()
    # Pengecualian: jangan hapus file download sementara, README, atau cache winbox
    -not ($rel -like "*.downloading" -or 
          $rel -like "appportable\cachewinbox\*" -or
          $rel -eq "readme.md" -or
          $rel -like "readme\*")
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

# 8. Simpan manifest lokal (berisi versi dan index file)
$localManifestPath = Join-Path $targetDir "#updateallfiles\manifest.json"
$remoteData | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $localManifestPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   SINKRONISASI PARALEL SELESAI DENGAN SUKSES!" -ForegroundColor Green
Write-Host "   Versi Terpasang : $remoteVersion" -ForegroundColor Green
Write-Host "   Waktu Unduh     : $elapsedSec detik" -ForegroundColor Green
Write-Host "   Semua berkas di $targetDir telah diperbarui." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Tekan Enter untuk menutup jendela..."
