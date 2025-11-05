<#
.SYNOPSIS
    Creates backups of specified files and directories.

.DESCRIPTION
    This script creates backups of specified source paths to a destination directory.
    It supports both files and directories and includes timestamp-based naming.

.PARAMETER SourcePath
    The path(s) to backup. Can be files or directories.

.PARAMETER DestinationPath
    The destination directory where backups will be stored.

.PARAMETER IncludeTimestamp
    Include timestamp in backup folder name for versioning.

.PARAMETER CompressBackup
    Compress the backup into a ZIP file.

.EXAMPLE
    .\Backup-Files.ps1 -SourcePath "C:\Important\Documents" -DestinationPath "D:\Backups"
    Creates a backup of the Documents folder.

.EXAMPLE
    .\Backup-Files.ps1 -SourcePath @("C:\File1.txt", "C:\Folder1") -DestinationPath "D:\Backups" -IncludeTimestamp -CompressBackup
    Creates timestamped, compressed backups of multiple sources.

.NOTES
    Author: PowerShell Script Project
    Date: October 2025
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$SourcePath,
    
    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeTimestamp,
    
    [Parameter(Mandatory = $false)]
    [switch]$CompressBackup
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

try {
    # Validate destination path
    if (-not (Test-Path -Path $DestinationPath)) {
        Write-Log "Creating destination directory: $DestinationPath" "INFO"
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }
    
    # Create backup folder name
    $backupFolderName = "Backup"
    if ($IncludeTimestamp) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFolderName += "_$timestamp"
    }
    
    $backupPath = Join-Path -Path $DestinationPath -ChildPath $backupFolderName
    
    Write-Log "Starting backup process..." "INFO"
    Write-Log "Backup destination: $backupPath" "INFO"
    
    # Create backup directory
    if (-not (Test-Path -Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    }
    
    $totalItems = 0
    $successCount = 0
    $errorCount = 0
    
    # Process each source path
    foreach ($source in $SourcePath) {
        if (-not (Test-Path -Path $source)) {
            Write-Log "Source path not found: $source" "ERROR"
            $errorCount++
            continue
        }
        
        $totalItems++
        $sourceName = Split-Path -Path $source -Leaf
        $destinationItem = Join-Path -Path $backupPath -ChildPath $sourceName
        
        try {
            if (Test-Path -Path $source -PathType Container) {
                # It's a directory
                Write-Log "Copying directory: $source" "INFO"
                Copy-Item -Path $source -Destination $destinationItem -Recurse -Force
            } else {
                # It's a file
                Write-Log "Copying file: $source" "INFO"
                Copy-Item -Path $source -Destination $destinationItem -Force
            }
            
            Write-Log "Successfully backed up: $source" "SUCCESS"
            $successCount++
        }
        catch {
            Write-Log "Failed to backup $source : $($_.Exception.Message)" "ERROR"
            $errorCount++
        }
    }
    
    # Compress backup if requested
    if ($CompressBackup) {
        try {
            Write-Log "Compressing backup..." "INFO"
            $zipPath = "$backupPath.zip"
            
            # Use .NET compression if available (PowerShell 5.0+)
            if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
                Compress-Archive -Path "$backupPath\*" -DestinationPath $zipPath -Force
                Remove-Item -Path $backupPath -Recurse -Force
                Write-Log "Backup compressed to: $zipPath" "SUCCESS"
            } else {
                Write-Log "Compress-Archive not available. Backup left uncompressed." "WARNING"
            }
        }
        catch {
            Write-Log "Failed to compress backup: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Summary
    Write-Log "Backup process completed!" "SUCCESS"
    Write-Log "Total items processed: $totalItems" "INFO"
    Write-Log "Successful backups: $successCount" "SUCCESS"
    Write-Log "Failed backups: $errorCount" $(if ($errorCount -gt 0) { "ERROR" } else { "INFO" })
    
    if ($errorCount -eq 0) {
        Write-Log "All items backed up successfully!" "SUCCESS"
        exit 0
    } else {
        Write-Log "Some items failed to backup. Check the log above for details." "WARNING"
        exit 1
    }
}
catch {
    Write-Log "Critical error during backup process: $($_.Exception.Message)" "ERROR"
    exit 1
}