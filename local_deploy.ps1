$wowAddonPath = "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\PeaversDynamicStats"

# Get the current directory
$currentDir = Get-Location

# Ensure paths don't have quotes which can cause issues with robocopy
$currentDirPath = $currentDir.Path
$wowAddonPathNormalized = $wowAddonPath

# Create the destination directory if it doesn't exist
if (!(Test-Path -Path $wowAddonPathNormalized)) {
    New-Item -ItemType Directory -Path $wowAddonPathNormalized -Force
}

# Use robocopy to synchronize directories
$result = robocopy $currentDirPath $wowAddonPathNormalized /MIR /FFT /Z /W:1 /R:1

# Display completion message
Write-Host "Directories synchronized successfully. Target directory now mirrors the source."
