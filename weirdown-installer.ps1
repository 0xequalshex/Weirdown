# =========================================
# WeirDownTool Automatic Installer
# =========================================

$ProgressPreference = 'Continue'
$installDir = "$HOME\WeirDownTool"

if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# 2️⃣ Updated URLs 
$appUrl    = "https://github.com/0xequalshex/Weirdown/releases/download/meow/WeirDown.exe"
$ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

Write-Host "⬇ Installing WeirDownTool..." -ForegroundColor Cyan

# 3️⃣ Download WeirDown
try {
    Invoke-WebRequest -Uri $appUrl -OutFile "$installDir\weirdown.exe" -ErrorAction Stop
    Unblock-File "$installDir\weirdown.exe"
    Write-Host "✅ WeirDownTool downloaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to download WeirDownTool. Check your internet connection." -ForegroundColor Red
    Pause
    exit
}

# 4️⃣ Check and install FFmpeg
if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "⚠ FFmpeg not found. Downloading dependency..." -ForegroundColor Yellow
    $zipPath  = "$installDir\ffmpeg.zip"
    $tempDir  = "$installDir\ffmpeg-temp"

    try {
        Invoke-WebRequest -Uri $ffmpegUrl -OutFile $zipPath -ErrorAction Stop
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

        # Search for the exe files specifically
        $ffExe = Get-ChildItem -Path $tempDir -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
        $ffProbe = Get-ChildItem -Path $tempDir -Recurse -Filter "ffprobe.exe" | Select-Object -First 1

        if ($ffExe -and $ffProbe) {
            Move-Item -Path $ffExe.FullName -Destination $installDir -Force
            Move-Item -Path $ffProbe.FullName -Destination $installDir -Force
            Write-Host "✅ FFmpeg & FFprobe installed successfully" -ForegroundColor Green
        } else {
            throw "Could not find ffmpeg.exe inside the downloaded ZIP."
        }

        Remove-Item $zipPath -Force
        Remove-Item $tempDir -Recurse -Force
    }
    catch {
        Write-Host "❌ FFmpeg Error: $($_.Exception.Message)" -ForegroundColor Red
        Pause
        exit
    }
}

# 5️⃣ Update PATH
$oldPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($oldPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$oldPath;$installDir", "User")
    $env:Path += ";$installDir"
    Write-Host "✅ PATH updated" -ForegroundColor Green
}

Write-Host "`n🎉 Installation Complete!" -ForegroundColor Cyan
Pause
