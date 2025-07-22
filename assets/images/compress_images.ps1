# PowerShell script to backup and compress/resize images in this folder
# Usage: Run this script from the assets/images directory

# Create backup folder if it doesn't exist
if (!(Test-Path -Path "./backup")) {
    New-Item -ItemType Directory -Path "./backup"
}

# Copy new images to backup (won't overwrite existing)
Get-ChildItem *.jpg,*.png | ForEach-Object {
    $dest = "./backup/$($_.Name)"
    if (!(Test-Path $dest)) {
        Copy-Item $_.FullName $dest
    }
}

# Compress and resize images
magick mogrify -resize 1080x -quality 75 *.jpg
magick mogrify -resize 1080x -quality 80 *.png
Write-Host "Image compression and backup complete." 