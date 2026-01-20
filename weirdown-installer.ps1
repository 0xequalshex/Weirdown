# =========================================
# WeirDownTool Automatic Installer (Fail-Safe Version)
# =========================================

# Force PowerShell to use TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ProgressPreference = 'Continue'
$installDir = "$HOME\WeirDownTool"

# 1️⃣ Create directory
if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# 2️⃣ Direct links
$appUrl    = "https://github.com/0xequalshex/Weirdown/releases/download/meow/WeirDown.exe"
$ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

Write-Host "⬇ Preparing Installation..." -ForegroundColor Cyan

# 3️⃣ Download WeirDown
try {
    Write-Host "Downloading WeirDown tool..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $appUrl -OutFile "$installDir\weirdown.exe" -UserAgent "Mozilla/5.0" -ErrorAction Stop
    Unblock-File "$installDir\weirdown.exe"
    Write-Host "✅ WeirDownTool ready." -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to download WeirDownTool. Please check your internet." -ForegroundColor Red
    Pause ; exit
}

# 4️⃣ Download FFmpeg
if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "⚠ FFmpeg not found. Starting download (approx 100MB)..." -ForegroundColor Yellow
    $zipPath = "$installDir\ffmpeg.zip"
    $tempDir = "$installDir\ffmpeg-temp"

    try {
        # Using a browser-like UserAgent is critical to avoid 403/404 errors
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
        
        Write-Host "Downloading FFmpeg ZIP..." -ForegroundColor Gray
        $webClient.DownloadFile($ffmpegUrl, $zipPath)
        
        Write-Host "📦 Extracting files..." -ForegroundColor Gray
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

        # Locate binaries
        $ffExe = Get-ChildItem -Path $tempDir -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
        $ffProbe = Get-ChildItem -Path $tempDir -Recurse -Filter "ffprobe.exe" | Select-Object -First 1

        if ($ffExe) {
            Move-Item -Path $ffExe.FullName -Destination $installDir -Force
            if ($ffProbe) { Move-Item -Path $ffProbe.FullName -Destination $installDir -Force }
            Write-Host "✅ FFmpeg installed successfully." -ForegroundColor Green
        } else {
            throw "ffmpeg.exe not found in ZIP."
        }
    }
    catch {
        Write-Host "❌ FFmpeg Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Try visiting: https://www.gyan.dev/ffmpeg/builds/ manually." -ForegroundColor White
        Pause ; exit
    }
    finally {
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }
}

# 5️⃣ Update PATH
$oldPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($oldPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$oldPath;$installDir", "User")
    $env:Path += ";$installDir"
}

Write-Host "`n🎉 DONE! Restart your terminal and type 'weirdown'." -ForegroundColor Cyan
Pause
