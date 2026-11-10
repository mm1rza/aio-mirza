# Skrip Generator Manifest untuk AIO Mirza
# Dijalankan oleh pengembang / maintainer sebelum commit & push ke GitHub

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  AIO Mirza - Manifest & Version Generator" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Get-Item $scriptDir).Parent.FullName

$excludePatterns = @(
    '\\.git\\',
    '\\README\\',
    'README\\.md$',
    '\\.gitattributes$',
    '\\.gitignore$',
    '#updateallfiles\\\\manifest\\.json$'
)

Write-Host "Memindai seluruh berkas di: $rootDir..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$allFiles = Get-ChildItem -Path $rootDir -Recurse -File | Where-Object {
    $full = $_.FullName
    $exclude = $false
    foreach ($p in $excludePatterns) {
        if ($full -match $p) { $exclude = $true; break }
    }
    -not $exclude
}

Write-Host "Ditemukan $($allFiles.Count) berkas. Menghitung MD5 Hash..." -ForegroundColor Yellow

$manifest = foreach ($f in $allFiles) {
    $relPath = $f.FullName.Substring($rootDir.Length + 1).Replace('\', '/')
    [PSCustomObject]@{
        Path = $relPath
        Size = $f.Length
        Hash = (Get-FileHash -Path $f.FullName -Algorithm MD5).Hash
    }
}

$sw.Stop()

# Simpan manifest.json
$manifestPath = Join-Path $scriptDir "manifest.json"
$manifest | ConvertTo-Json -Compress | Set-Content -Path $manifestPath -Encoding UTF8 -Force

# Perbarui version.txt dengan timestamp build saat ini
$versionPath = Join-Path $scriptDir "version.txt"
$newVersion = (Get-Date).ToString("yyyyMMdd.HHmm")
$newVersion | Set-Content -Path $versionPath -NoNewline -Encoding UTF8 -Force

$totalBytes = ($manifest | Measure-Object -Property Size -Sum).Sum
$totalMB = [math]::Round($totalBytes / 1MB, 2)

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Manifest berhasil dibuat!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Total Berkas : $($manifest.Count)" -ForegroundColor White
Write-Host " Total Ukuran : $totalMB MB" -ForegroundColor White
Write-Host " Versi Baru   : $newVersion" -ForegroundColor White
Write-Host " Waktu Proses : $([math]::Round($sw.Elapsed.TotalSeconds, 2)) detik" -ForegroundColor White
Write-Host " Berkas       : $manifestPath" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Silakan lakukan commit & push ke GitHub:" -ForegroundColor Yellow
Write-Host "  git add ." -ForegroundColor Gray
Write-Host "  git commit -m 'Release version $newVersion'" -ForegroundColor Gray
Write-Host "  git push origin main" -ForegroundColor Gray
Write-Host ""
