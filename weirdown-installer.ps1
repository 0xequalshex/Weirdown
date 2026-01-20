# =========================================
# WeirDownTool Automatic Installer
# =========================================

# Hide download progress for cleaner output
$ProgressPreference = 'SilentlyContinue'

# 1️⃣ Installation directory
$installDir = "$HOME\WeirDownTool"

# Create installation directory if it does not exist
if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# 2️⃣ Download URLs (CHANGE THESE)
$appUrl    = "https://github.com/0xequalshex/Weirdown/releases/download/meow/WeirDown.exe"
$ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

Write-Host "⬇ Installing WeirDownTool..." -ForegroundColor Cyan

# 3️⃣ Download WeirDown executable
try {
    Invoke-WebRequest -Uri $appUrl -OutFile "$installDir\weirdown.exe"
    Unblock-File "$installDir\weirdown.exe"
    Write-Host "✅ WeirDownTool downloaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to download WeirDownTool" -ForegroundColor Red
    exit
}

# 4️⃣ Check if FFmpeg exists
if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {

    Write-Host "⚠ FFmpeg not found. Downloading dependency..." -ForegroundColor Yellow

    $zipPath  = "$installDir\ffmpeg.zip"
    $tempDir  = "$installDir\ffmpeg-temp"

    try {
        # Download FFmpeg
        Invoke-WebRequest -Uri $ffmpegUrl -OutFile $zipPath

        # Extract archive
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

        # Move ffmpeg and ffprobe binaries
        Get-ChildItem $tempDir -Recurse -Include ffmpeg.exe, ffprobe.exe |
            Move-Item -Destination $installDir -Force

        # Clean up temporary files
        Remove-Item $zipPath -Force
        Remove-Item $tempDir -Recurse -Force

        Write-Host "✅ FFmpeg & FFprobe installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to install FFmpeg" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "✅ FFmpeg already installed. Skipping." -ForegroundColor Green
}

# 5️⃣ Add installation directory to USER PATH
$oldPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($oldPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$oldPath;$installDir",
        "User"
    )

    # Update current session PATH
    $env:Path += ";$installDir"

    Write-Host "✅ PATH environment variable updated" -ForegroundColor Green
}

# 6️⃣ Final message
Write-Host "`n========================================="
Write-Host "🎉 Installation Complete!" -ForegroundColor Cyan
Write-Host "Restart PowerShell and type:" -ForegroundColor White
Write-Host "weirdown" -ForegroundColor Yellow
Write-Host "========================================="
