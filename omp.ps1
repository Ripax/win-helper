# Oh My Posh + Nerd Fonts + Windows Terminal Customizer
# Save this file as oh-my-posh-setup.ps1
# Run in ADMIN PowerShell:  Set-ExecutionPolicy Bypass -Scope Process -Force; ./oh-my-posh-setup.ps1

function Install-OhMyPosh {
    Write-Host "🚀 Installing Oh My Posh..."
    winget install JanDeDobbeleer.OhMyPosh -s winget -e --accept-source-agreements --accept-package-agreements
    Write-Host "✅ Oh My Posh installed."
}

function Uninstall-OhMyPosh {
    Write-Host "🗑️ Uninstalling Oh My Posh..."
    winget uninstall JanDeDobbeleer.OhMyPosh -s winget
    Write-Host "✅ Oh My Posh removed."
}

function Install-NerdFont {
    param([string]$FontName = "FiraCode")

    Write-Host "🔤 Installing Nerd Font ($FontName)..."
    $url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FontName.zip"
    $zipPath = "$env:TEMP\$FontName.zip"
    $extractPath = "$env:TEMP\$FontName"

    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    # Copy fonts into Windows Fonts (requires admin)
    $fonts = Get-ChildItem -Path $extractPath -Recurse -Include *.ttf,*.otf
    foreach ($font in $fonts) {
        Write-Host "📥 Installing font: $($font.Name)"
        $target = "$env:WINDIR\Fonts\$($font.Name)"
        Copy-Item $font.FullName -Destination $target -Force
        # Register font
        $shellApp = New-Object -ComObject Shell.Application
        $fontsFolder = $shellApp.Namespace(0x14)
        $fontsFolder.CopyHere($font.FullName, 0x10)
    }

    Remove-Item $zipPath -Force
    Remove-Item $extractPath -Recurse -Force
    Write-Host "✅ Nerd Font installed: $FontName"
}

function Uninstall-NerdFont {
    param([string]$FontName = "FiraCode")

    Write-Host "🗑️ Removing Nerd Font ($FontName)..."
    $fontDir = "$env:WINDIR\Fonts"
    $fonts = Get-ChildItem $fontDir | Where-Object { $_.Name -like "*$FontName Nerd Font*" }

    foreach ($font in $fonts) {
        Write-Host "❌ Deleting: $($font.Name)"
        Remove-Item $font.FullName -Force -ErrorAction SilentlyContinue
    }

    Write-Host "✅ Nerd Font removed: $FontName"
}

function Customize-Terminal {
    param(
        [string]$Font = "FiraCode Nerd Font",
        [double]$Opacity = 0.8
    )

    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $settingsPath)) {
        Write-Host "⚠️ Windows Terminal settings.json not found."
        return
    }

    $settings = Get-Content $settingsPath | Out-String | ConvertFrom-Json

    foreach ($profile in $settings.profiles.list) {
        # Ensure font object exists
        if (-not $profile.PSObject.Properties.Name.Contains("font")) {
            $profile | Add-Member -MemberType NoteProperty -Name "font" -Value @{}
        }
        $profile.font.face = $Font

        # Ensure acrylic + opacity
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
    }

    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8
    Write-Host "✨ Windows Terminal customized with $Font and opacity $Opacity"
}

function Show-Menu {
    Clear-Host
    Write-Host "==============================="
    Write-Host " Oh My Posh Setup Menu"
    Write-Host "==============================="
    Write-Host "1. Install Oh My Posh"
    Write-Host "2. Uninstall Oh My Posh"    // ...existing code...
    function Install-OhMyPosh {
        Write-Host "🚀 Installing Oh My Posh..."
    
        # Quick check: is the command already available?
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            Write-Host "✅ Oh My Posh is already installed. Skipping."
            return
        }
    
        # Fallback check via winget (in case binary name differs)
        try {
            $wingetList = & winget list --id JanDeDobbeleer.OhMyPosh 2>$null
            if ($wingetList -and $wingetList -ne "") {
                Write-Host "✅ Oh My Posh is already installed (winget). Skipping."
                return
            }
        } catch { 
            # ignore winget errors, proceed to install attempt
        }
    
        winget install JanDeDobbeleer.OhMyPosh -s winget -e --accept-source-agreements --accept-package-agreements
        Write-Host "✅ Oh My Posh installed."
    }
    
    # Helper to detect installed fonts
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
        $fonts = Get-ChildItem -Path $extractPath -Recurse -Include *.ttf,*.otf
        foreach ($font in $fonts) {
            # skip if this specific font file already exists
            $target = "$env:WINDIR\Fonts\$($font.Name)"
            if (Test-Path $target) {
                Write-Host "ℹ️ Font file already present, skipping: $($font.Name)"
                continue
            }
    
            Write-Host "📥 Installing font: $($font.Name)"
            Copy-Item $font.FullName -Destination $target -Force
            # Register font
            $shellApp = New-Object -ComObject Shell.Application
            $fontsFolder = $shellApp.Namespace(0x14)
            $fontsFolder.CopyHere($font.FullName, 0x10)
        }
    
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Nerd Font installed: $FontName"
    }
    # ...existing code...
    Write-Host "3. Install Nerd Font"
    Write-Host "4. Uninstall Nerd Font"
    Write-Host "5. Customize Windows Terminal"
    Write-Host "==============================="
    Write-Host "0. Exit"
    Write-Host "==============================="
}

do {
    Show-Menu
    $choice = Read-Host "Select an option (1-6)"

    switch ($choice) {
        "1" { Install-OhMyPosh }
        "2" { Uninstall-OhMyPosh }
        "3" {
            $font = Read-Host "Enter Nerd Font name (default: FiraCode)"
            if ([string]::IsNullOrWhiteSpace($font)) { $font = "FiraCode" }
            Install-NerdFont -FontName $font
        }
        "4" {
            $font = Read-Host "Enter Nerd Font name to remove (default: FiraCode)"
            if ([string]::IsNullOrWhiteSpace($font)) { $font = "FiraCode" }
            Uninstall-NerdFont -FontName $font
        }
        "5" {
            $font = Read-Host "Enter font for Windows Terminal (default: FiraCode Nerd Font)"
            if ([string]::IsNullOrWhiteSpace($font)) { $font = "FiraCode Nerd Font" }

            $opacityInput = Read-Host "Enter opacity (0.0 - 1.0, default: 0.8)"
            if ([string]::IsNullOrWhiteSpace($opacityInput)) {
                $opacity = 0.8
            }
            else {
                try {
                    $opacity = [double]::Parse($opacityInput)
                }
                catch {
                    Write-Host "⚠️ Invalid input, using default 0.8"
                    $opacity = 0.8
                }
            }

            Customize-Terminal -Font $font -Opacity $opacity
        }
        "0" { Write-Host "👋 Exiting..."; break }
        default { Write-Host "❌ Invalid choice, try again." }
    }

    Pause
} while ($choice -ne "0")
# End of script
