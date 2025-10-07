# --- Full Automatic Oh My Posh + Nerd Font + Windows Terminal Setup (Smart Font Check) ---
# Save this as setup-omp.ps1 and run in PowerShell (Run as Admin)

# 1. Install Oh My Posh if not installed
if (-not (Get-Command "oh-my-posh.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing Oh My Posh..."
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements -h
} else {
    Write-Host "✅ Oh My Posh already installed."
}

# 2. Choose Nerd Font
$fontsList = @{
    "1" = "CascadiaCode"
    "2" = "FiraCode"
    "3" = "Hack"
    "4" = "JetBrainsMono"
}

Write-Host "`n🎨 Choose a Nerd Font to install:"
$fontsList.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key). $($_.Value)" }

$choice = Read-Host "Enter number [1-4]"
if ($fontsList.ContainsKey($choice)) {
    $fontName = $fontsList[$choice]

    # Check if font already installed
    $installedFonts = @(Get-ChildItem "$env:WINDIR\Fonts" -Include "*.ttf","*.otf" -Recurse | Select-Object -ExpandProperty BaseName)
    if ($installedFonts -match "$fontName") {
        Write-Host "ℹ️ $fontName Nerd Font already installed. Skipping download."
    } else {
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
    }
} else {
    Write-Host "❌ Invalid choice. Exiting."
    exit
}

# 3. Export Oh My Posh theme
$themePath = "$HOME\Documents\PowerShell\material.omp.json"
oh-my-posh config export --config jandedobbeleer --output $themePath

# 4. Ensure PowerShell profile exists
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# 5. Add init line to profile
$initLine = 'oh-my-posh init pwsh --config "$HOME\Documents\PowerShell\material.omp.json" | Invoke-Expression'
if (-not (Select-String -Path $PROFILE -Pattern 'oh-my-posh init pwsh' -Quiet)) {
    Add-Content -Path $PROFILE -Value "`n$initLine"
    Write-Host "✅ Oh My Posh init added to PowerShell profile."
} else {
    Write-Host "ℹ️ Oh My Posh already configured in PowerShell profile."
}

# 6. Color Schemes Library
$colorSchemes = @{
    "1" = "Dracula"
    "2" = "One Half Dark"
    "3" = "Solarized Dark"
    "4" = "Gruvbox Dark"
}

$schemeDefs = @{
    "Dracula" = @{
        name="Dracula"; cursorColor="#F8F8F2"; selectionBackground="#44475A"; background="#282A36"; foreground="#F8F8F2";
        black="#21222C"; blue="#BD93F9"; cyan="#8BE9FD"; green="#50FA7B"; purple="#FF79C6"; red="#FF5555"; white="#F8F8F2"; yellow="#F1FA8C";
        brightBlack="#6272A4"; brightBlue="#D6ACFF"; brightCyan="#A4FFFF"; brightGreen="#69FF94"; brightPurple="#FF92DF"; brightRed="#FF6E6E"; brightWhite="#FFFFFF"; brightYellow="#FFFFA5"
    }
    "One Half Dark" = @{
        name="One Half Dark"; background="#282C34"; foreground="#DCDFE4"; cursorColor="#FFFFFF"; selectionBackground="#FFFFFF";
        black="#282C34"; red="#E06C75"; green="#98C379"; yellow="#E5C07B"; blue="#61AFEF"; purple="#C678DD"; cyan="#56B6C2"; white="#DCDFE4";
        brightBlack="#5A6374"; brightRed="#E06C75"; brightGreen="#98C379"; brightYellow="#E5C07B"; brightBlue="#61AFEF"; brightPurple="#C678DD"; brightCyan="#56B6C2"; brightWhite="#FFFFFF"
    }
    "Solarized Dark" = @{
        name="Solarized Dark"; background="#002B36"; foreground="#839496"; cursorColor="#93A1A1"; selectionBackground="#073642";
        black="#073642"; red="#DC322F"; green="#859900"; yellow="#B58900"; blue="#268BD2"; purple="#D33682"; cyan="#2AA198"; white="#EEE8D5";
        brightBlack="#002B36"; brightRed="#CB4B16"; brightGreen="#586E75"; brightYellow="#657B83"; brightBlue="#839496"; brightPurple="#6C71C4"; brightCyan="#93A1A1"; brightWhite="#FDF6E3"
    }
    "Gruvbox Dark" = @{
        name="Gruvbox Dark"; background="#282828"; foreground="#EBDBB2"; cursorColor="#FE8019"; selectionBackground="#3C3836";
        black="#282828"; red="#CC241D"; green="#98971A"; yellow="#D79921"; blue="#458588"; purple="#B16286"; cyan="#689D6A"; white="#A89984";
        brightBlack="#928374"; brightRed="#FB4934"; brightGreen="#B8BB26"; brightYellow="#FABD2F"; brightBlue="#83A598"; brightPurple="#D3869B"; brightCyan="#8EC07C"; brightWhite="#EBDBB2"
    }
}

# 7. Choose color scheme
Write-Host "`n🎨 Choose a color scheme for Windows Terminal:"
$colorSchemes.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key). $($_.Value)" }
$schemeChoice = Read-Host "Enter number [1-4]"
if ($colorSchemes.ContainsKey($schemeChoice)) {
    $schemeName = $colorSchemes[$schemeChoice]
    Write-Host "🎨 Applying $schemeName color scheme..."
} else {
    Write-Host "❌ Invalid choice. Using Dracula as default."
    $schemeName = "Dracula"
}

# 8. Ask for custom acrylic opacity
$opacityInput = Read-Host "Enter acrylic opacity (0.0 - 1.0, e.g., 0.5 or 0.85)"
if ([double]::TryParse($opacityInput,[ref]$null) -and $opacityInput -ge 0 -and $opacityInput -le 1) {
    $opacity = [double]$opacityInput
} else {
    Write-Host "❌ Invalid input. Using default opacity 0.85"
    $opacity = 0.85
}

# 9. Apply to Windows Terminal
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $settingsPath) {
    $json = Get-Content $settingsPath -Raw | ConvertFrom-Json

    # Add color scheme if missing
    if (-not ($json.schemes | Where-Object { $_.name -eq $schemeName })) {
        $json.schemes += $schemeDefs[$schemeName]
        Write-Host "✅ Added $schemeName scheme to Windows Terminal."
    }

    # Apply to PowerShell profile
    foreach ($profile in $json.profiles.list) {
        if ($profile.name -match "PowerShell") {
            $profile.fontFace = "$fontName Nerd Font"
            $profile.colorScheme = $schemeName
            $profile.useAcrylic = $true
            $profile.acrylicOpacity = $opacity
            $profile.cursorShape = "bar"
        }
    }

    $json | ConvertTo-Json -Depth 5 | Set-Content -Path $settingsPath -Encoding utf8
    Write-Host "✅ Windows Terminal customized with $fontName Nerd Font + $schemeName + acrylic opacity $opacity."
} else {
    Write-Host "⚠️ Windows Terminal settings.json not found. Please configure manually."
}

Write-Host "`n🎉 Setup complete!"
Write-Host "👉 Restart PowerShell + Windows Terminal to see your new look."
