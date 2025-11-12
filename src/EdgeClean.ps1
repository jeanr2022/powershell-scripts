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

.PARAMETER AcceptDisclaimer
    Automatically accept the disclaimer without interactive prompt.

.EXAMPLE
    EdgeClean -EnableLogging -PerformanceIsolation
    EdgeRestore

.EXAMPLE
    EdgeClean -AcceptDisclaimer
    Run EdgeClean accepting the disclaimer automatically

.NOTES
    WARNING: This script modifies Windows registry and file system.
    Use at your own risk. Test in non-production environments first.
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$AcceptDisclaimer
)

$EdgeTempProfile = "C:\Temp\EdgeProfile"
$EdgeExe = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

function Show-Disclaimer {
    Write-Host ""
    Write-Host "=================================================================================" -ForegroundColor Yellow
    Write-Host "                              DISCLAIMER" -ForegroundColor Yellow
    Write-Host "=================================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This script will make changes to your system:" -ForegroundColor White
    Write-Host "  - Modify Windows registry (Edge policies)" -ForegroundColor White
    Write-Host "  - Create and modify temporary folders" -ForegroundColor White
    Write-Host "  - Backup existing Edge policy registry keys" -ForegroundColor White
    Write-Host ""
    Write-Host "This script is provided 'AS IS' without warranty of any kind." -ForegroundColor White
    Write-Host "Use at your own risk. Test in non-production environments first." -ForegroundColor White
    Write-Host ""
    Write-Host "Changes can be reverted by running: EdgeRestore" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "=================================================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $response = Read-Host "Do you accept and want to continue? (Yes/No)"
    
    if ($response -notmatch '^(y|yes)$') {
        Write-Host ""
        Write-Host "Script execution cancelled by user." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    Write-Host "Disclaimer accepted. Proceeding..." -ForegroundColor Green
    Write-Host ""
}

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
    # Show disclaimer for EdgeClean (default action)
    if (-not $AcceptDisclaimer) {
        Show-Disclaimer
    }
    EdgeClean
} elseif ($args[0] -in @("/?", "/help", "help")) {
    Show-Help
} elseif ($args[0] -eq "EdgeRestore") {
    # No disclaimer needed for restore operation
    EdgeRestore
} elseif ($args[0] -eq "EdgeClean") {
    # Show disclaimer before EdgeClean
    if (-not $AcceptDisclaimer) {
        Show-Disclaimer
    }
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