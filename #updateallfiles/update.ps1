# Set protokol keamanan ke TLS 1.2 agar koneksi ke GitHub lancar dan aman
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

$localVersionFile = "C:\#mirza\#updateallfiles\version.txt"
$remoteVersionUrl = "https://raw.githubusercontent.com/mm1rza/aio-mirza/main/%23updateallfiles/version.txt"
$downloadUrl = "https://github.com/mm1rza/aio-mirza/archive/refs/heads/main.zip"
$localPath = "C:\#mirza"
$zipFilePath = "C:\#mirza\aio-mirza.zip"

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
        Write-Host " [!] KONEKSI INTERNET TIDAK TERDETEKSI" -ForegroundColor Red
        Write-Host "==========================================================" -ForegroundColor Red
        Write-Host " Menunggu koneksi internet terhubung..." -ForegroundColor Yellow
        Write-Host " Harap sambungkan kabel LAN atau Wi-Fi pada komputer ini." -ForegroundColor Cyan
        Write-Host " Jendela TIDAK akan tertutup otomatis. (Tekan Ctrl+C untuk batal)" -ForegroundColor Gray
        Write-Host "==========================================================" -ForegroundColor Red

        $dotCount = 1
        while (-not (Test-Internet -url $targetUrl)) {
            Write-Host -NoNewline "`r Menunggu koneksi internet$('.' * $dotCount)      " -ForegroundColor Yellow
            $dotCount = ($dotCount % 5) + 1
            Start-Sleep -Seconds 3
        }
        Write-Host ""
        Write-Host "[OK] Koneksi internet terhubung! Melanjutkan proses..." -ForegroundColor Green
        Start-Sleep -Seconds 1
    }
}

function Get-RemoteVersion {
    param ($url)
    Wait-ForInternet -targetUrl $url
    while ($true) {
        try {
            $wc = New-Object net.webclient
            $data = $wc.DownloadString($url)
            return $data.Trim()
        } catch {
            Write-Host "Gagal mengambil data versi: $($_.Exception.Message)" -ForegroundColor Red
            Wait-ForInternet -targetUrl $url
        }
    }
}

# Cek versi lokal
if (Test-Path $localVersionFile) {
    $localVersion = (Get-Content $localVersionFile -Raw).Trim()
    Write-Host "Versi di komputer saat ini : $localVersion"
} else {
    Write-Host "File versi lokal tidak ditemukan (instalasi baru)."
    $localVersion = ""
}

# Ambil versi remote dari GitHub (otomatis menunggu jika belum ada internet)
$remoteVersion = Get-RemoteVersion $remoteVersionUrl
Write-Host "Versi di cloud : $remoteVersion"

# Bandingkan versi
if ($localVersion -and ($localVersion -eq $remoteVersion)) {
    Write-Host "Versi di komputer anda sudah terbaru."
    $response = Read-Host "Apakah Anda ingin memaksa update? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "Memaksa update..."
    } else {
        Write-Host "Tidak ada update dilakukan."
        Write-Host ""
        Read-Host "Tekan Enter untuk menutup jendela..."
        exit
    }
} else {
    Write-Host "Update tersedia. Mempersiapkan update files..."
}

$folder = "C:\#mirza"
if (Test-Path $folder) {
    Write-Host "Menghapus folder dan subfolder lama: $folder"
    Remove-Item $folder -Recurse -Force
}

Clear-Host

if (-Not (Test-Path $localPath)) {
    New-Item -ItemType Directory -Path $localPath -Force | Out-Null
}

# Unduh arsip zip dari GitHub (menunggu jika koneksi terputus di tengah jalan)
$downloadSuccess = $false
while (-not $downloadSuccess) {
    Wait-ForInternet -targetUrl $downloadUrl
    try {
        Write-Output "Download file dari $downloadUrl..."
        $wc = New-Object net.webclient
        $wc.DownloadFile($downloadUrl, $zipFilePath)
        $downloadSuccess = $true
    } catch {
        Write-Host "Download terputus/gagal: $($_.Exception.Message)" -ForegroundColor Red
        if (Test-Path $zipFilePath) { Remove-Item $zipFilePath -Force }
        Wait-ForInternet -targetUrl $downloadUrl
    }
}

Write-Output "Extract file ke $localPath..."
Expand-Archive -Path $zipFilePath -DestinationPath $localPath -Force
Write-Output "Membersihkan file arsip zip..."
Remove-Item $zipFilePath -Force
Write-Output "Download and extract selesai."

$sumber = "C:\#mirza\aio-mirza-main"
$tujuan = "C:\#mirza"
if (-not (Test-Path -Path $tujuan)) {
    Write-Host "Folder tujuan tidak ada. Membuat folder tujuan..."
    New-Item -Path $tujuan -ItemType Directory | Out-Null
} else {
    Write-Host "Folder tujuan sudah ada."
}

Write-Host "Memindahkan file dan folder dari $sumber ke $tujuan..."
Get-ChildItem -Path $sumber -Recurse | ForEach-Object {
    $targetPath = Join-Path -Path $tujuan -ChildPath $_.FullName.Substring($sumber.Length)
    if ($_.PSIsContainer) {
        if (-not (Test-Path -Path $targetPath)) {
            Write-Host "Membuat folder: $targetPath"
            New-Item -Path $targetPath -ItemType Directory | Out-Null
        }
    } else {
        Write-Host "Memindahkan file: $($_.FullName) ke $targetPath"
        Move-Item -Path $_.FullName -Destination $targetPath -Force
    }
}

Write-Host "Menghapus folder sumber sementara..."
Remove-Item -Path $sumber -Recurse -Force

# Bersihkan file dokumentasi / git attributes yang tidak dibutuhkan di lokal
$files = @("C:\#mirza\README.md", "C:\#mirza\.gitattributes")
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Menghapus file: $file"
        Remove-Item $file -Force
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Update selesai dengan sukses!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Read-Host "Tekan Enter untuk menutup jendela..."
