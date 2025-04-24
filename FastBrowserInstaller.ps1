If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script with administrator privileges..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy RemoteSigned -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}


$InstallMethods = @(
    @{ Name = "Winget"; Value = "Winget" },
    @{ Name = "Chocolatey"; Value = "Chocolatey" }
)

$Browsers = @(
    [PSCustomObject]@{
        Name          = "Microsoft Edge Stable"
        WingetId      = "Microsoft.Edge"
        ChocolateyId  = "microsoftedge"
    },
    [PSCustomObject]@{
        Name          = "Microsoft Edge Beta"
        WingetId      = "Microsoft.Edge.Beta"
        ChocolateyId  = "microsoftedge.beta"
    },
    [PSCustomObject]@{
        Name          = "Microsoft Edge Dev"
        WingetId      = "Microsoft.Edge.Dev"
        ChocolateyId  = "microsoftedge.dev"
    },
    [PSCustomObject]@{
        Name          = "Microsoft Edge Canary"
        WingetId      = "Microsoft.Edge.Canary"
        ChocolateyId  = "microsoftedge.canary"
    },
    [PSCustomObject]@{
        Name          = "Google Chrome Stable"
        WingetId      = "Google.Chrome"
        ChocolateyId  = "googlechrome"
    },
     [PSCustomObject]@{
        Name          = "Google Chrome Beta"
        WingetId      = "Google.Chrome.Beta"
        ChocolateyId  = "googlechrome.beta"
    },
     [PSCustomObject]@{
        Name          = "Google Chrome Dev"
        WingetId      = "Google.Chrome.Dev"
        ChocolateyId  = "googlechrome.dev"
    },
     [PSCustomObject]@{
        Name          = "Google Chrome Canary"
        WingetId      = "Google.Chrome.Canary"
        ChocolateyId  = "googlechrome.canary"
    },
    [PSCustomObject]@{
        Name          = "Mozilla Firefox"
        WingetId      = "Mozilla.Firefox"
        ChocolateyId  = "firefox"
    },
    [PSCustomObject]@{
        Name          = "Brave Browser"
        WingetId      = "Brave.Brave"
        ChocolateyId  = "brave"
    },
    [PSCustomObject]@{
        Name          = "Opera Browser"
        WingetId      = "Opera.Opera"
        ChocolateyId  = "opera"
    }
)


Write-Host "Select an installation method:"
for ($i = 0; $i -lt $InstallMethods.Count; $i++) {
    Write-Host "$($i + 1). $($InstallMethods[$i].Name)"
}

$MethodChoice = Read-Host "Enter the number of your choice"
$SelectedMethod = $null

if ($MethodChoice -ge 1 -and $MethodChoice -le $InstallMethods.Count) {
    $SelectedMethod = $InstallMethods[$MethodChoice -1].Value
    Write-Host "You selected: $($InstallMethods[$MethodChoice -1].Name)" -ForegroundColor Green
} else {
    Write-Error "Invalid choice. Exiting."
    Exit
}


Write-Host "Opening browser selection dialog..."
$SelectedBrowsers = $Browsers | Out-GridView -Title "Select Browsers to Install (Ctrl+Click for multiple)" -PassThru

if (-not $SelectedBrowsers) {
    Write-Host "No browsers selected. Exiting..."
    Exit
}


if ($SelectedMethod -eq "Winget") {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "Winget is not found. Please install it or select another method."
        Write-Host "You can usually install Winget from the Microsoft Store (App Installer)."
        Exit
    }
} elseif ($SelectedMethod -eq "Chocolatey") {
     if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Warning "Chocolatey is not found. Attempting to install Chocolatey..."
        # Install Chocolatey - Official command from chocolatey.org
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "Chocolatey installed successfully." -ForegroundColor Green
        } catch {
            Write-Error "Failed to install Chocolatey. Please install it manually or select another method."
            Exit
        }
    }
}

foreach ($browser in $SelectedBrowsers) {
    Write-Host "`nAttempting to install $($browser.Name) using $($SelectedMethod)..."

    try {
        switch ($SelectedMethod) {
            "Winget" {
                 if ([string]::IsNullOrWhiteSpace($browser.WingetId)) {
                     Write-Warning "Winget ID not available for $($browser.Name). Skipping Winget installation."
                     continue
                 }
                 Write-Host "Installing $($browser.Name) using Winget (ID: $($browser.WingetId))..."
                 # Use -h for silent, --scope machine for system-wide install (requires admin)
                 # --exact matches the ID exactly
                 # --accept-package-agreements and --accept-source-agreements automate prompts
                 Start-Process winget -ArgumentList "install --id $($browser.WingetId) -h --scope machine --exact --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow -ErrorAction Stop
                 Write-Host "$($browser.Name) installed successfully (Winget)." -ForegroundColor Green
            }
            "Chocolatey" {
                 if ([string]::IsNullOrWhiteSpace($browser.ChocolateyId)) {
                     Write-Warning "Chocolatey ID not available for $($browser.Name). Skipping Chocolatey installation."
                     continue
                 }
                 Write-Host "Installing $($browser.Name) using Chocolatey (ID: $($browser.ChocolateyId))..."
                 # -y accepts prompts, --no-progress hides download progress which can be messy in scripts
                 Start-Process choco -ArgumentList "install $($browser.ChocolateyId) -y --no-progress" -Wait -NoNewWindow -ErrorAction Stop
                 Write-Host "$($browser.Name) installed successfully (Chocolatey)." -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Error "Failed to install $($browser.Name) using $($SelectedMethod): $_"
        # Decide if you want to stop or continue with the next browser
        # break # uncomment to stop on first error
    }
}

Write-Host "`nInstallation process finished." -ForegroundColor Cyan
# SIG # Begin signature block
# MIIF6QYJKoZIhvcNAQcCoIIF2jCCBdYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA4YB8tSvTUSpsK
# ceDjJeYdtarVdvpRau4ISOMNADhSZ6CCA00wggNJMIICMaADAgECAhBktf5gt/YO
# lUkig1srIhj8MA0GCSqGSIb3DQEBCwUAMCwxCzAJBgNVBAYTAlVBMR0wGwYDVQQD
# DBRGYXN0QnJvd3Nlckluc3RhbGxlcjAeFw0yNTA0MjQxMzQzNDRaFw0zMDA0MjQx
# MzUzMzhaMCwxCzAJBgNVBAYTAlVBMR0wGwYDVQQDDBRGYXN0QnJvd3Nlckluc3Rh
# bGxlcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALA9aYfVzs8nU07u
# kspxfiSyZ2P1YN3fps6972Dho9BmuOhnPMmdzfITTn/GnsfLYsQkGihTMacIvdXB
# I1W+SMaQY1+Cm/UvaNY13Bx8Gw/8fNEn8PuCpOg44ryYrvEKFyhiM1MpAI25TWk7
# vlFDXIUwdIVSjGzfjBXjZYyR4mad1GZUyvvWz4XQSCHkluYIzB7s3/sEY3P4THBP
# hVNxVozvFQe7ou4xsFmLSf/8GSpkzAtYZS7Fhtrome698P4QHSCM0z/rxiJstrl+
# cklOVVUtFK/5kxFcJea+pVbAHWKi8PPZhJr2WhatatejB+56Bb3L+UeBHw/kd/jP
# 57xK2DUCAwEAAaNnMGUwDgYDVR0PAQH/BAQDAgeAMB8GA1UdEQQYMBaCFEZhc3RC
# cm93c2VySW5zdGFsbGVyMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBTb
# O9oPxo0XQMSwsjsPZLJSne8voTANBgkqhkiG9w0BAQsFAAOCAQEAbS2WlLlur5o2
# cApxYsaKW0InJBYjzxol4VnE+OqF+kvIBswNd/iYEauTljO+wyR/nujYkMfbdraz
# L6iLRV1mUle7DWyqCwKObou8+dxtNXpzgWIHAvs5VCfFZs3vDTapmU/O89ziEPjw
# Mje8a53G7IGixLJ+XCgLfG0DocJVMWRk4LaJV6JEYOv3x5DQq139vk4J4cAYPHDA
# D3qJLeOhZemTmlHm14237ZXHENpS6uM9QZcM/e862lJygUErCDIY8iYdREEFnm3D
# hj4PqUFkbVD5lK/pdYLFi7bzLqGhNmOC3jW1b+/izyWshg4lY/1gL9g2KMPl3wIw
# feUfHRwCsjGCAfIwggHuAgEBMEAwLDELMAkGA1UEBhMCVUExHTAbBgNVBAMMFEZh
# c3RCcm93c2VySW5zdGFsbGVyAhBktf5gt/YOlUkig1srIhj8MA0GCWCGSAFlAwQC
# AQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
# hvcNAQkEMSIEIL+Sp+TSLAvPfXWXm+I3p2i/pv05FTUh2DZ3/ATU3mDsMA0GCSqG
# SIb3DQEBAQUABIIBAI9+y6exQq4wOO3TtZRm0a1/SR+3AQLEDgMRIcihdCJ3N53X
# uRlYe3RV8LdPB9uOkZHRc1IUvE9qYmacS38v3WfcGNpeFsYTvCiHRkxbwsxqSAHh
# T4ImGynMqu0mJal/g+FNkL2AvD+zkZp3X5h7ZzaJMDCtfZdNN676PBYIqNHYV8SK
# NSg4g5vZwsrkeyCXVLHM2c3bZlfb1Aj20w6UmKb/0u6+Zu7VCfcao2vsbtLdP1rr
# sg3ix8guePQJC+fSB2RLqg+i/P2DcVEoplGyQtvbdXAJA5nZyRz5h6bLxeBYQ4bX
# rl8O2Qbq4my2U02iTJhVPM+iO9EreZnbWANGtmw=
# SIG # End signature block
