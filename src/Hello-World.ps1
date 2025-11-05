<#
.SYNOPSIS
    A simple "Hello World" PowerShell script.

.DESCRIPTION
    This script demonstrates basic PowerShell functionality by displaying a greeting message
    and some basic system information.

.PARAMETER Name
    The name to include in the greeting. Defaults to "World".

.EXAMPLE
    .\Hello-World.ps1
    Displays "Hello, World!" and system information.

.EXAMPLE
    .\Hello-World.ps1 -Name "PowerShell"
    Displays "Hello, PowerShell!" and system information.

.NOTES
    Author: PowerShell Script Project
    Date: October 2025
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Name = "World"
)

# Display greeting
Write-Host "Hello, $Name!" -ForegroundColor Green

# Display basic system information
Write-Host "`nSystem Information:" -ForegroundColor Yellow
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "Operating System: $($PSVersionTable.OS)" -ForegroundColor Cyan
Write-Host "Current User: $($env:USERNAME)" -ForegroundColor Cyan
Write-Host "Computer Name: $($env:COMPUTERNAME)" -ForegroundColor Cyan
Write-Host "Current Date/Time: $(Get-Date)" -ForegroundColor Cyan

# Display current working directory
Write-Host "`nCurrent Location: $(Get-Location)" -ForegroundColor Magenta

Write-Host "`nScript completed successfully!" -ForegroundColor Green