<#
.SYNOPSIS
    Checks Microsoft Edge updater scheduled tasks and optionally re-enables them if disabled.

.DESCRIPTION
    This script checks the status of Microsoft Edge updater scheduled tasks and identifies
    any that are disabled. If disabled tasks are found, it prompts the user to re-enable them.
    
    The script checks for common Edge update task names:
    - MicrosoftEdgeUpdateTaskMachineCore
    - MicrosoftEdgeUpdateTaskMachineUA
    - MicrosoftEdgeUpdateBrowserReplacementTask
    - MicrosoftEdgeUpdateTaskUser*

.PARAMETER AutoEnable
    Automatically re-enable all disabled Edge updater tasks without prompting.

.PARAMETER CheckOnly
    Only check the status of tasks without offering to enable them.

.EXAMPLE
    .\Check-EdgeUpdaterTasks.ps1
    Checks Edge updater tasks and prompts to re-enable any that are disabled.

.EXAMPLE
    .\Check-EdgeUpdaterTasks.ps1 -AutoEnable
    Automatically re-enables all disabled Edge updater tasks.

.EXAMPLE
    .\Check-EdgeUpdaterTasks.ps1 -CheckOnly
    Only displays the status of Edge updater tasks without prompting to enable.

.NOTES
    Author: PowerShell Script Project
    Date: November 2025
    Version: 1.0
    
    ADMIN PRIVILEGES:
    - Required to re-enable scheduled tasks
    - Check-only mode works without admin privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$AutoEnable,
    
    [Parameter(Mandatory = $false)]
    [switch]$CheckOnly
)

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Edge updater task name patterns
$edgeTaskPatterns = @(
    "MicrosoftEdgeUpdateTaskMachineCore",
    "MicrosoftEdgeUpdateTaskMachineUA",
    "MicrosoftEdgeUpdateBrowserReplacementTask",
    "MicrosoftEdgeUpdateTaskUser"
)

Write-Host "=== Microsoft Edge Updater Task Checker ===" -ForegroundColor Cyan
Write-Host ""

# Check for admin privileges if we might need to enable tasks
$isAdmin = Test-Administrator
if (-not $CheckOnly -and -not $isAdmin) {
    Write-Host "Note: Script is not running as Administrator." -ForegroundColor Yellow
    Write-Host "Task status can be checked, but re-enabling requires admin privileges." -ForegroundColor Yellow
    Write-Host ""
}

try {
    # Get all scheduled tasks
    Write-Host "Scanning for Edge updater scheduled tasks..." -ForegroundColor Gray
    $allTasks = Get-ScheduledTask -ErrorAction Stop
    
    # Filter Edge updater tasks
    $edgeTasks = $allTasks | Where-Object {
        $taskName = $_.TaskName
        $edgeTaskPatterns | Where-Object { $taskName -like "*$_*" }
    }
    
    if ($edgeTasks.Count -eq 0) {
        Write-Host "No Edge updater tasks found on this system." -ForegroundColor Yellow
        Write-Host "This may be normal if Edge updates are managed differently or Edge is not installed." -ForegroundColor Gray
        exit 0
    }
    
    Write-Host "Found $($edgeTasks.Count) Edge updater task(s):`n" -ForegroundColor Green
    
    # Categorize tasks by state
    $disabledTasks = @()
    $enabledTasks = @()
    $readyTasks = @()
    
    foreach ($task in $edgeTasks) {
        $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
        
        $status = $task.State
        $taskPath = $task.TaskPath.TrimEnd('\')
        $fullTaskName = if ($taskPath) { "$taskPath\$($task.TaskName)" } else { $task.TaskName }
        
        # Display task information
        switch ($status) {
            'Disabled' {
                Write-Host "  [DISABLED] $fullTaskName" -ForegroundColor Red
                $disabledTasks += $task
            }
            'Ready' {
                Write-Host "  [READY]    $fullTaskName" -ForegroundColor Green
                $readyTasks += $task
            }
            'Running' {
                Write-Host "  [RUNNING]  $fullTaskName" -ForegroundColor Cyan
                $enabledTasks += $task
            }
            default {
                Write-Host "  [$status]  $fullTaskName" -ForegroundColor Gray
                $enabledTasks += $task
            }
        }
        
        # Show last run time if available
        if ($taskInfo -and $taskInfo.LastRunTime) {
            Write-Host "             Last run: $($taskInfo.LastRunTime)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    
    # Summary
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Total tasks: $($edgeTasks.Count)" -ForegroundColor White
    Write-Host "  Enabled/Ready: $($enabledTasks.Count + $readyTasks.Count)" -ForegroundColor Green
    Write-Host "  Disabled: $($disabledTasks.Count)" -ForegroundColor $(if ($disabledTasks.Count -gt 0) { "Red" } else { "Green" })
    Write-Host ""
    
    # Handle disabled tasks
    if ($disabledTasks.Count -eq 0) {
        Write-Host "All Edge updater tasks are enabled. No action needed." -ForegroundColor Green
        exit 0
    }
    
    # Check-only mode
    if ($CheckOnly) {
        Write-Host "Check-only mode: No changes will be made." -ForegroundColor Yellow
        exit 0
    }
    
    # Prompt or auto-enable
    $shouldEnable = $false
    
    if ($AutoEnable) {
        Write-Host "Auto-enable mode: Re-enabling all disabled tasks..." -ForegroundColor Yellow
        $shouldEnable = $true
    } else {
        Write-Host "WARNING: $($disabledTasks.Count) Edge updater task(s) are disabled." -ForegroundColor Yellow
        Write-Host "Disabled update tasks may prevent Edge from receiving security and feature updates." -ForegroundColor Yellow
        Write-Host ""
        
        $response = Read-Host "Would you like to re-enable the disabled tasks? (Y/N)"
        $shouldEnable = $response -match '^[Yy]'
    }
    
    if ($shouldEnable) {
        if (-not $isAdmin) {
            Write-Host ""
            Write-Host "ERROR: Administrator privileges are required to enable scheduled tasks." -ForegroundColor Red
            Write-Host "Please run this script as Administrator." -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host ""
        Write-Host "Re-enabling disabled tasks..." -ForegroundColor Cyan
        
        $successCount = 0
        $failCount = 0
        
        foreach ($task in $disabledTasks) {
            try {
                Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop | Out-Null
                $fullTaskName = "$($task.TaskPath.TrimEnd('\'))\$($task.TaskName)"
                Write-Host "  [SUCCESS] Enabled: $fullTaskName" -ForegroundColor Green
                $successCount++
            }
            catch {
                Write-Host "  [FAILED]  Could not enable: $($task.TaskName)" -ForegroundColor Red
                Write-Host "            Error: $($_.Exception.Message)" -ForegroundColor Red
                $failCount++
            }
        }
        
        Write-Host ""
        Write-Host "Operation complete:" -ForegroundColor Cyan
        Write-Host "  Successfully enabled: $successCount" -ForegroundColor Green
        if ($failCount -gt 0) {
            Write-Host "  Failed to enable: $failCount" -ForegroundColor Red
        }
        
        if ($successCount -gt 0) {
            Write-Host ""
            Write-Host "Edge updater tasks have been re-enabled successfully." -ForegroundColor Green
        }
    } else {
        Write-Host ""
        Write-Host "No changes were made. Tasks remain disabled." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to check scheduled tasks." -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
