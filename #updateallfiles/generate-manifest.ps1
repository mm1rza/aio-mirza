# ==============================================================================
#  AIO MIRZA - MANIFEST & VERSION GENERATOR (MAINTAINER TOOL)
#  Dijalankan oleh pengembang / maintainer sebelum commit & push ke GitHub
# ==============================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  AIO Mirza - Unified Manifest & Version Generator" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Get-Item $scriptDir).Parent.FullName

Write-Host "Memindai seluruh berkas di: $rootDir..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$allFiles = Get-ChildItem -Path $rootDir -Recurse -File | Where-Object {
    $rel = $_.FullName.Substring($rootDir.Length + 1).Replace('\', '/')
    # Abaikan berkas dokumentasi, git, dan manifest generator
    if ($rel -match '^(README\.md|README/|\.git/|\.gitattributes|\.gitignore|#updateallfiles/manifest\.json)' -or 
        $_.Name -eq 'README.md' -or 
        $_.Name -eq '.gitattributes' -or 
        $_.Name -eq '.gitignore') {
        return $false
    }
    return $true
}

Write-Host "Ditemukan $($allFiles.Count) berkas valid. Menghitung MD5 Hash..." -ForegroundColor Yellow

$fileList = foreach ($f in $allFiles) {
    $relPath = $f.FullName.Substring($rootDir.Length + 1).Replace('\', '/')
    [PSCustomObject]@{
        Path = $relPath
        Size = $f.Length
        Hash = (Get-FileHash -Path $f.FullName -Algorithm MD5).Hash
    }
}

$sw.Stop()

$newVersion = (Get-Date).ToString("yyyyMMdd.HHmm")
$totalBytes = ($fileList | Measure-Object -Property Size -Sum).Sum
$totalMB = [math]::Round($totalBytes / 1MB, 2)

# Susun objek gabungan (Versi + Daftar Berkas)
$unifiedManifest = [PSCustomObject]@{
    version     = $newVersion
    generatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    totalFiles  = $fileList.Count
    totalBytes  = $totalBytes
    files       = $fileList
}

# 1. Simpan manifest.json utama (gabungan)
$manifestPath = Join-Path $scriptDir "manifest.json"
$unifiedManifest | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $manifestPath -Encoding UTF8 -Force

# 2. Simpan version.txt sebagai cadangan (backward compatibility untuk autounattend.xml)
$versionPath = Join-Path $scriptDir "version.txt"
$newVersion | Set-Content -Path $versionPath -NoNewline -Encoding UTF8 -Force

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Manifest & Versi Berhasil Digabungkan!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Versi Rilis  : $newVersion" -ForegroundColor White
Write-Host " Total Berkas : $($fileList.Count)" -ForegroundColor White
Write-Host " Total Ukuran : $totalMB MB" -ForegroundColor White
Write-Host " Waktu Proses : $([math]::Round($sw.Elapsed.TotalSeconds, 2)) detik" -ForegroundColor White
Write-Host " Berkas Utama : $manifestPath (Berisi versi & file)" -ForegroundColor Gray
Write-Host " Berkas Cadang: $versionPath (Kompatibilitas installer)" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Silakan lakukan commit & push ke GitHub:" -ForegroundColor Yellow
Write-Host "  git add ." -ForegroundColor Gray
Write-Host "  git commit -m 'Rilis versi $newVersion'" -ForegroundColor Gray
Write-Host "  git push origin main" -ForegroundColor Gray
Write-Host ""
