# Requires Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script with administrator privileges..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- Configuration ---

# Define installation methods (Direct Download option removed)
$InstallMethods = @(
    @{ Name = "Winget"; Value = "Winget" },
    @{ Name = "Chocolatey"; Value = "Chocolatey" }
)

# Browser configurations including Winget and Chocolatey IDs only
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

# --- Method Selection ---

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

# --- Browser Selection ---

Write-Host "Opening browser selection dialog..."
$SelectedBrowsers = $Browsers | Out-GridView -Title "Select Browsers to Install (Ctrl+Click for multiple)" -PassThru

if (-not $SelectedBrowsers) {
    Write-Host "No browsers selected. Exiting..."
    Exit
}

# --- Installation ---

# Check for package managers if selected
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

# Install selected browsers
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
# MIIFZQYJKoZIhvcNAQcCoIIFVjCCBVICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyuRYGlz3Xbd9x8jmRKj+kboz
# miygggMJMIIDBTCCAe2gAwIBAgIQarWO3mvGpJRN1Q+NbbvA6TANBgkqhkiG9w0B
# AQsFADARMQ8wDQYDVQQDDAZRdWFydHowHhcNMjUwNDIzMjAyMzI3WhcNMjYwNDIz
# MjA0MzI3WjARMQ8wDQYDVQQDDAZRdWFydHowggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQDedaChcdJ+FWZuQzgcOlvPeHNIFJKOYYjPey7oHFy2VWD3IwhD
# fb3H068rfZ9SkZDFAJtrrO0dP4JdmfC31FbdIdD7rUeOjzqL1/wRu0SdfRmGsdhp
# /HHBOde05DcMXuBH2oDnEEuL+dcC7FWG2CcuW6OfXwvsX3gMBHKnc1VaGiy6q3GG
# Uu6GGA2Cu5l8Cu2/FTyOhqQ+c0nYACQF5eiyjE3eexp3ol7RC/bUkhQs3E2aX2HC
# YiCeJIGJkzrw0v5oWXQ2fqwUoUy2z/tqRy14VxWatqcf4nO537ISK2ixpos9qtyC
# Kr2/Wp9BTV2K9zHbK8B/Yn62YYbhw22HsqKxAgMBAAGjWTBXMA4GA1UdDwEB/wQE
# AwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzARBgNVHREECjAIggZRdWFydHowHQYD
# VR0OBBYEFNxCP2uqiTH9fmhoKnlV24Q1CAb3MA0GCSqGSIb3DQEBCwUAA4IBAQA+
# PTmTvvezzJwhWoYJCIpIRLqVHoHSomH5FjAw948WijC/Eof2yGX8cYD5siS7xf6k
# YNLDchVXyIrNh5E5Mo0mNckFXFTfAiFi+ZjujmE10bxxZ2RP/puzMZbKirRZsYvG
# nNegcShWin8m2BOeRY1W1+suRjk1a92NTk18Lf57B4ReArOUb6rI5YIIP/1ygXu9
# WJ3OlF9J6MAJrsP9BU6vgFWfQ37OaaHEtdbzw3htIxxuDRKlCOV0hXOkG9FbLxQE
# nKRyfke4vBobBdNJDI0j8rF7FNCeoOiUwXZY6TjkBrU329f6uR1kttojJ3KUEfYC
# EcQwu1CK80En/CkCsZGRMYIBxjCCAcICAQEwJTARMQ8wDQYDVQQDDAZRdWFydHoC
# EGq1jt5rxqSUTdUPjW27wOkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDzlKgXmn7EvG488FbyG
# w5tN+hCVMA0GCSqGSIb3DQEBAQUABIIBAKhvPLMIIrrjx+8C4ks9f1mdgWWRLHB4
# C7v1l+KDkYGdW4Vg/RFs7RYdHsRkte8FZjrOahgFyGCpreog9g6dxj9TUbobbfS6
# bskPChe0qcORnov37TV3DkizkZRXKr8MSKeFp1FamtIToHCRE/FketVG/KaLIjWW
# be3/LyzVxbQGRmAEetpWrrbL6jWm8K+KBOkXBa5rVuJfffNuhOYXHfNldpQoN8wM
# o5DgcoYdjDuIbGxTCS/87/ZdRbbft4Ktf2vI8JGY+wJH6zJjf6Dfi/DB84T7Tt1e
# +2/WW6+muPeX4TAXwJCkwxbgIOBBAuZzitxi75TI5caPx5Blptgl0mE=
# SIG # End signature block
