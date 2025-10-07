# --- Nerd Font Installer + Oh My Posh Setup ---

# Popular Nerd Fonts list
$fontsList = @{
    "1" = "CascadiaCode"
    "2" = "FiraCode"
    "3" = "Hack"
    "4" = "JetBrainsMono"
}

Write-Host "🎨 Choose a Nerd Font to install:"
$fontsList.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key). $($_.Value)" }

$choice = Read-Host "Enter number [1-4]"
if ($fontsList.ContainsKey($choice)) {
    $fontName = $fontsList[$choice]
    Write-Host "📦 Installing $fontName Nerd Font..."

    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$fontName.zip"
    $fontZip = "$env:TEMP\$fontName.zip"
    $fontDir = "$env:TEMP\$fontName-NF"

    Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip
    Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force

    $fonts = Get-ChildItem -Path $fontDir -Recurse -Include *.ttf
    foreach ($font in $fonts) {
        Copy-Item $font.FullName -Destination "$env:WINDIR\Fonts" -Force
        Write-Host "✅ Installed font: $($font.Name)"
    }
} else {
    Write-Host "❌ Invalid choice. Exiting."
    exit
}

# --- Setup Oh My Posh Theme ---
$themePath = "$HOME\Documents\PowerShell\material.omp.json"
oh-my-posh config export --config material --output $themePath

# Ensure PowerShell profile exists
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# Add oh-my-posh init line if not already present
$initLine = 'oh-my-posh init pwsh --config "$HOME\Documents\PowerShell\material.omp.json" | Invoke-Expression'
if (-not (Select-String -Path $PROFILE -Pattern 'oh-my-posh init pwsh' -Quiet)) {
    Add-Content -Path $PROFILE -Value "`n$initLine"
}

Write-Host "`n🎉 Setup complete!"
Write-Host "👉 Restart PowerShell, then go to terminal settings and change font to '$fontName Nerd Font'."
