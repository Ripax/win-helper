function Install-OhMyPosh {
    Write-Host "🚀 Installing Oh My Posh..."

    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Host "✅ Oh My Posh is already installed. Skipping."
        return
    }

    try {
        $wingetList = & winget list --id JanDeDobbeleer.OhMyPosh 2>$null
        if ($wingetList -and $wingetList -ne "") {
            Write-Host "✅ Oh My Posh is already installed (winget). Skipping."
            return
        }
    } catch {}

    winget install JanDeDobbeleer.OhMyPosh -s winget -e --accept-source-agreements --accept-package-agreements
    Write-Host "✅ Oh My Posh installed."
}

function Uninstall-OhMyPosh {
    Write-Host "🗑️ Uninstalling Oh My Posh..."
    try {
        winget uninstall JanDeDobbeleer.OhMyPosh -s winget -e
        Write-Host "✅ Oh My Posh removed."
    } catch {
        Write-Host "⚠️ Unable to uninstall via winget or not installed."
    }
}

function Test-FontInstalled {
    param([string]$FontName)

    if ([string]::IsNullOrWhiteSpace($FontName)) { return $false }

    # Check Fonts folder for matching files
    $fontsDir = "$env:WINDIR\Fonts"
    try {
        $match = Get-ChildItem -Path $fontsDir -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -like "*$FontName*" -or $_.Name -like "*Nerd Font*" } |
                 Select-Object -First 1
        if ($match) { return $true }
    } catch {}

    # Check registry for installed font names
    try {
        $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue
        if ($reg) {
            foreach ($prop in $reg.PSObject.Properties) {
                if ($prop.Name -like "*$FontName*" -or $prop.Name -like "*Nerd Font*") {
                    return $true
                }
            }
        }
    } catch {}

    return $false
}

function Install-NerdFont {
    param([string]$FontName = "FiraCode")

    Write-Host "🔤 Installing Nerd Font ($FontName)..."

    if (Test-FontInstalled -FontName $FontName) {
        Write-Host "✅ Font '$FontName' appears to be already installed. Skipping."
        return
    }

    $url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FontName.zip"
    $zipPath = "$env:TEMP\$FontName.zip"
    $extractPath = "$env:TEMP\$FontName"

    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    # Copy fonts into Windows Fonts (requires admin)
    $fonts = Get-ChildItem -Path $extractPath -Recurse -Include *.ttf,*.otf -ErrorAction SilentlyContinue
    foreach ($font in $fonts) {
        $target = "$env:WINDIR\Fonts\$($font.Name)"
        if (Test-Path $target) {
            Write-Host "ℹ️ Font file already present, skipping: $($font.Name)"
            continue
        }

        Write-Host "📥 Installing font: $($font.Name)"
        Copy-Item $font.FullName -Destination $target -Force
        # Register font with shell
        try {
            $shellApp = New-Object -ComObject Shell.Application
            $fontsFolder = $shellApp.Namespace(0x14)
            $fontsFolder.CopyHere($font.FullName, 0x10)
        } catch {}
    }

    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Nerd Font installed: $FontName"
}

function Uninstall-NerdFont {
    param([string]$FontName = "FiraCode")

    Write-Host "🗑️ Removing Nerd Font ($FontName)..."
    $fontDir = "$env:WINDIR\Fonts"
    try {
        $fonts = Get-ChildItem $fontDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$FontName*" -or $_.Name -like "*Nerd Font*" }
        foreach ($font in $fonts) {
            Write-Host "❌ Deleting: $($font.Name)"
            Remove-Item $font.FullName -Force -ErrorAction SilentlyContinue
        }

        # Optionally remove registry entries if present (best-effort)
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            $reg = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            if ($reg) {
                foreach ($prop in $reg.PSObject.Properties) {
                    if ($prop.Name -like "*$FontName*" -or $prop.Name -like "*Nerd Font*") {
                        Remove-ItemProperty -Path $regPath -Name $prop.Name -ErrorAction SilentlyContinue
                    }
                }
            }
        } catch {}
    } catch {
        Write-Host "⚠️ Error while removing fonts."
    }

    Write-Host "✅ Nerd Font removed: $FontName"
}

# New: show manual terminal configuration instructions instead of auto-editing settings.json
function Show-TerminalInstructions {
    param(
        [string]$FontFace = "FiraCode Nerd Font",
        [double]$Opacity = 0.8,
        [string]$ColorScheme = "Material Dark"
    )

    Write-Host "✨ Manual Windows Terminal configuration:"
    Write-Host "1) Open Windows Terminal settings (Ctrl+,) or Settings UI."
    Write-Host "2) For each profile, set the font face to: $FontFace"
    Write-Host "   - In Settings UI: Profile → Appearance → Font face"
    Write-Host "3) Enable 'Use acrylic' (Use Acrylic) and set opacity to: $Opacity"
    Write-Host "   - In Settings UI: Profile → Appearance → Use acrylic / Acrylic opacity"
    Write-Host "4) Add or pick a color scheme named '$ColorScheme' if you want that theme."
    Write-Host "5) Save and restart Windows Terminal for changes to take effect."
    Write-Host ""
    Write-Host "If you prefer automation later, re-run this script after adding safe JSON edits."
}

function Show-Menu {
    Clear-Host
    Write-Host "==============================="
    Write-Host " Oh My Posh Setup Menu"
    Write-Host "==============================="
    Write-Host "1. Install (oh-my-posh, nerd fonts) and show manual terminal config steps"
    Write-Host "2. Uninstall (oh-my-posh, remove nerd fonts) and show manual revert steps"
    Write-Host "==============================="
    Write-Host "0. Exit"
    Write-Host "==============================="
}

do {
    Show-Menu
    $choice = Read-Host "Select an option (0-2)"

    switch ($choice) {
        "1" {
            $font = Read-Host "Enter Nerd Font name (default: FiraCode)"
            if ([string]::IsNullOrWhiteSpace($font)) { $font = "FiraCode" }
            $fontFace = "$font Nerd Font"

            $opacityInput = Read-Host "Enter opacity (0.0 - 1.0, default: 0.8)"
            if ([string]::IsNullOrWhiteSpace($opacityInput)) { $opacity = 0.8 }
            else {
                try { $opacity = [double]::Parse($opacityInput) } catch { Write-Host "⚠️ Invalid input, using default 0.8"; $opacity = 0.8 }
            }

            Install-OhMyPosh
            Install-NerdFont -FontName $font

            # Show manual instructions instead of editing settings.json automatically
            Show-TerminalInstructions -FontFace $fontFace -Opacity $opacity -ColorScheme "Material Dark"
        }
        "2" {
            $font = Read-Host "Enter Nerd Font name to remove (default: FiraCode)"
            if ([string]::IsNullOrWhiteSpace($font)) { $font = "FiraCode" }

            Uninstall-OhMyPosh
            Uninstall-NerdFont -FontName $font

            Write-Host ""
            Write-Host "⚠️ Terminal settings were not modified by this script."
            Write-Host "If you manually changed Windows Terminal settings, open Settings and revert font to your preferred font (e.g., Consolas)."
        }
        "0" { Write-Host "👋 Exiting..."; break }
        default { Write-Host "❌ Invalid choice, try again." }
    }

    Pause
} while ($choice -ne "0")
# End of script
