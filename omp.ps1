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

function Customize-Terminal {
    param(
        [string]$Font = "FiraCode Nerd Font",
        [double]$Opacity = 0.8,
        [string]$ColorSchemeName = "Material Dark"
    )

    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $settingsPath)) {
        Write-Host "⚠️ Windows Terminal settings.json not found."
        return
    }

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    # Ensure schemes array exists
    if (-not $settings.PSObject.Properties.Name.Contains("schemes")) {
        $settings | Add-Member -MemberType NoteProperty -Name "schemes" -Value @()
    }

    # Add a simple Material Dark scheme if missing
    $exists = $false
    foreach ($s in $settings.schemes) {
        if ($s.name -eq $ColorSchemeName) { $exists = $true; break }
    }
    if (-not $exists) {
        $mdScheme = @{
            name = $ColorSchemeName
            background = "#263238"
            foreground = "#ECEFF1"
            black = "#263238"
            red = "#ff5370"
            green = "#c3e88d"
            yellow = "#ffcb6b"
            blue = "#82aaff"
            purple = "#c792ea"
            cyan = "#89ddff"
            white = "#eceff1"
            brightBlack = "#546e7a"
            brightRed = "#ff8ba7"
            brightGreen = "#e6ffcb"
            brightYellow = "#ffe082"
            brightBlue = "#b3d4ff"
            brightPurple = "#e6ccff"
            brightCyan = "#d6fbff"
            brightWhite = "#ffffff"
        }
        $settings.schemes += $mdScheme
    }

    foreach ($profile in $settings.profiles.list) {
        if (-not $profile.PSObject.Properties.Name.Contains("font")) {
            $profile | Add-Member -MemberType NoteProperty -Name "font" -Value @{}
        }
        $profile.font.face = $Font

        if (-not $profile.PSObject.Properties.Name.Contains("useAcrylic")) {
            $profile | Add-Member -MemberType NoteProperty -Name "useAcrylic" -Value $true
        } else {
            $profile.useAcrylic = $true
        }

        if (-not $profile.PSObject.Properties.Name.Contains("acrylicOpacity")) {
            $profile | Add-Member -MemberType NoteProperty -Name "acrylicOpacity" -Value $Opacity
        } else {
            $profile.acrylicOpacity = $Opacity
        }

        # Set color scheme
        $profile.colorScheme = $ColorSchemeName
    }

    $settings | ConvertTo-Json -Depth 20 | Set-Content $settingsPath -Encoding utf8
    Write-Host "✨ Windows Terminal customized with font '$Font', opacity $Opacity and color scheme '$ColorSchemeName'"
}

function Reset-TerminalCustomization {
    param(
        [string]$DefaultFont = "Consolas",
        [string]$ColorSchemeToRemove = "Material Dark"
    )

    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $settingsPath)) {
        Write-Host "⚠️ Windows Terminal settings.json not found."
        return
    }

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    foreach ($profile in $settings.profiles.list) {
        if ($profile.PSObject.Properties.Name.Contains("font")) {
            $profile.font.face = $DefaultFont
        } else {
            $profile | Add-Member -MemberType NoteProperty -Name "font" -Value @{ face = $DefaultFont }
        }

        if ($profile.PSObject.Properties.Name.Contains("useAcrylic")) {
            $profile.useAcrylic = $false
        }
        if ($profile.PSObject.Properties.Name.Contains("acrylicOpacity")) {
            $profile.acrylicOpacity = 1.0
        }
        if ($profile.PSObject.Properties.Name.Contains("colorScheme") -and $profile.colorScheme -eq $ColorSchemeToRemove) {
            $profile.PSObject.Properties.Remove("colorScheme")
        }
    }

    # Remove the Material Dark scheme if present
    if ($settings.PSObject.Properties.Name.Contains("schemes")) {
        $newSchemes = @()
        foreach ($s in $settings.schemes) {
            if ($s.name -ne $ColorSchemeToRemove) {
                $newSchemes += $s
            }
        }
        $settings.schemes = $newSchemes
    }

    $settings | ConvertTo-Json -Depth 20 | Set-Content $settingsPath -Encoding utf8
    Write-Host "♻️ Windows Terminal customization reset (font -> $DefaultFont, removed scheme '$ColorSchemeToRemove' if present)."
}

function Show-Menu {
    Clear-Host
    Write-Host "==============================="
    Write-Host " Oh My Posh Setup Menu"
    Write-Host "==============================="
    Write-Host "1. Install (oh-my-posh, nerd fonts, customize terminal -> Material Dark + opacity)"
    Write-Host "2. Uninstall (oh-my-posh, remove nerd fonts, reset terminal customization)"
    Write-Host "==============================="
    Write-Host "0. Exit"
    Write-Host "==============================="
}
# ...existing code...

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
            Customize-Terminal -Font $fontFace -Opacity $opacity -ColorSchemeName "Material Dark"
        }
        "2" {
            $font = Read-Host "Enter Nerd Font name to remove (default: FiraCode)"
            if ([string]::IsNullOrWhiteSpace($font)) { $font = "FiraCode" }

            Uninstall-OhMyPosh
            Uninstall-NerdFont -FontName $font
            Reset-TerminalCustomization -DefaultFont "Consolas" -ColorSchemeToRemove "Material Dark"
        }
        "0" { Write-Host "👋 Exiting..."; break }
        default { Write-Host "❌ Invalid choice, try again." }
    }

    Pause
} while ($choice -ne "0")
# End of script
