<#
.SYNOPSIS
    Launch Microsoft Edge in a clean state for testing and restore original settings.

.DESCRIPTION
    This script provides two main functions:
    - EdgeClean: Launch Edge without policies, with optional logging and performance isolation.
    - EdgeRestore: Revert registry changes and remove temporary profile.

.REMARKS
    What this script does:
    • Backs up existing Edge policies by renaming registry keys
    • Adds temporary policies to disable sync and block all extensions
    • Deletes old temp profile and creates a fresh one for clean testing
    • Launches Edge with a new profile and optional flags for logging or performance isolation
    • Restores original state by removing temp policies and profile, and restoring backups

.PARAMETER EnableLogging
    Enable crashpad and verbose logging.

.PARAMETER PerformanceIsolation
    Disable updates and background networking for cleaner performance testing.

.EXAMPLE
    EdgeClean -EnableLogging -PerformanceIsolation
    EdgeRestore
#>

$EdgeTempProfile = "C:\Temp\EdgeProfile"
$EdgeExe = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

function Show-Help {
    Write-Host "`nUsage:"
    Write-Host "  EdgeClean [-EnableLogging] [-PerformanceIsolation]"
    Write-Host "  EdgeRestore"
    Write-Host "`nOptions:"
    Write-Host "  -EnableLogging          Enable crashpad and verbose logging"
    Write-Host "  -PerformanceIsolation   Disable updates and background networking"
}

function EdgeClean {
    param(
        [switch]$EnableLogging,
        [switch]$PerformanceIsolation
    )

    Write-Host "=== Starting Edge in Clean Mode ==="

    # Step 1: Remove old temp profile
    if (Test-Path $EdgeTempProfile) {
        Write-Host "Removing old temp profile..."
        Remove-Item $EdgeTempProfile -Recurse -Force
    }

    # Step 2: Backup existing policies
    Write-Host "Backing up existing policies..."
    try {
        Rename-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -NewName "Edge_backup" -ErrorAction SilentlyContinue
        Rename-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -NewName "Edge_backup" -ErrorAction SilentlyContinue
    } catch {
        Write-Host "No existing policy keys found or rename failed."
    }

    # Step 3: Add SyncDisabled policy
    Write-Host "Adding SyncDisabled policy..."
    New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Force | Out-Null
    New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "SyncDisabled" -Value 1 -PropertyType DWord -Force

    # Step 4: Block all extensions
    Write-Host "Blocking all extensions..."
    New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "ExtensionInstallBlocklist" -Value "*" -PropertyType MultiString -Force

    # Step 5: Create fresh temp profile folder
    New-Item -ItemType Directory -Path $EdgeTempProfile -Force | Out-Null

    # Step 6: Build arguments for Edge launch
    $args = "--user-data-dir=$EdgeTempProfile --no-first-run --disable-extensions --disable-sync"
    if ($EnableLogging) { $args += " --enable-crashpad --enable-logging --v=1" }
    if ($PerformanceIsolation) { $args += " --disable-component-update --disable-background-networking --disable-background-timer-throttling" }

    # Step 7: Launch Edge
    Write-Host "Launching Edge with arguments: $args"
    Start-Process $EdgeExe -ArgumentList $args
}

function EdgeRestore {
    Write-Host "=== Restoring Original Edge State ==="

    # Step 1: Remove temp profile
    if (Test-Path $EdgeTempProfile) {
        Write-Host "Removing temp profile folder..."
        Remove-Item $EdgeTempProfile -Recurse -Force
    }

    # Step 2: Delete temporary policies
    Write-Host "Deleting temporary policies..."
    Remove-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Recurse -Force -ErrorAction SilentlyContinue

    # Step 3: Restore backups
    if (Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge_backup") {
        Rename-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge_backup" -NewName "Edge"
    }
    if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge_backup") {
        Rename-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge_backup" -NewName "Edge"
    }

    Write-Host "Revert complete."
}

# Handle script invocation logic
if ($args.Count -eq 0) {
    EdgeClean
} elseif ($args[0] -in @("/?", "/help", "help")) {
    Show-Help
} elseif ($args[0] -eq "EdgeRestore") {
    EdgeRestore
} elseif ($args[0] -eq "EdgeClean") {
    if ($args.Count -gt 1) {
        # Use splatting to properly pass remaining arguments
        $remainingArgs = $args[1..($args.Count-1)]
        EdgeClean @remainingArgs
    } else {
        EdgeClean
    }
} else {
    Write-Host "Invalid command: $($args[0])`n"
    Show-Help
}