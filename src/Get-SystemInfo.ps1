<#
.SYNOPSIS
    Retrieves comprehensive system information.

.DESCRIPTION
    This script gathers and displays detailed system information including hardware,
    operating system, network, and performance details.

.PARAMETER OutputFormat
    Specifies the output format. Valid values are 'Console', 'JSON', 'CSV'.
    Default is 'Console'.

.PARAMETER ExportPath
    Path to export the results when using JSON or CSV format.

.EXAMPLE
    .\Get-SystemInfo.ps1
    Displays system information in the console.

.EXAMPLE
    .\Get-SystemInfo.ps1 -OutputFormat JSON -ExportPath "C:\temp\sysinfo.json"
    Exports system information to a JSON file.

.NOTES
    Author: PowerShell Script Project
    Date: October 2025
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Console', 'JSON', 'CSV')]
    [string]$OutputFormat = 'Console',
    
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    Write-Host "Gathering system information..." -ForegroundColor Yellow
    
    # Collect system information
    $systemInfo = @{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        OperatingSystem = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
        OSVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
        Architecture = $env:PROCESSOR_ARCHITECTURE
        TotalMemoryGB = [Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        Processor = (Get-CimInstance -ClassName Win32_Processor).Name
        LogicalProcessors = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        TimeZone = (Get-TimeZone).DisplayName
        LastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        SystemUptime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        IPAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*", "Wi-Fi*" | Where-Object {$_.IPAddress -ne "127.0.0.1"}).IPAddress -join ", "
        Timestamp = Get-Date
    }
    
    # Output based on format
    switch ($OutputFormat) {
        'Console' {
            Write-Host "`n=== SYSTEM INFORMATION ===" -ForegroundColor Green
            Write-Host "Computer Name: $($systemInfo.ComputerName)" -ForegroundColor Cyan
            Write-Host "User Name: $($systemInfo.UserName)" -ForegroundColor Cyan
            Write-Host "Domain: $($systemInfo.Domain)" -ForegroundColor Cyan
            Write-Host "Operating System: $($systemInfo.OperatingSystem)" -ForegroundColor Cyan
            Write-Host "OS Version: $($systemInfo.OSVersion)" -ForegroundColor Cyan
            Write-Host "Architecture: $($systemInfo.Architecture)" -ForegroundColor Cyan
            Write-Host "Total Memory (GB): $($systemInfo.TotalMemoryGB)" -ForegroundColor Cyan
            Write-Host "Processor: $($systemInfo.Processor)" -ForegroundColor Cyan
            Write-Host "Logical Processors: $($systemInfo.LogicalProcessors)" -ForegroundColor Cyan
            Write-Host "PowerShell Version: $($systemInfo.PowerShellVersion)" -ForegroundColor Cyan
            Write-Host "Time Zone: $($systemInfo.TimeZone)" -ForegroundColor Cyan
            Write-Host "Last Boot Time: $($systemInfo.LastBootTime)" -ForegroundColor Cyan
            Write-Host "System Uptime: $($systemInfo.SystemUptime.Days) days, $($systemInfo.SystemUptime.Hours) hours, $($systemInfo.SystemUptime.Minutes) minutes" -ForegroundColor Cyan
            Write-Host "IP Address: $($systemInfo.IPAddress)" -ForegroundColor Cyan
            Write-Host "Report Generated: $($systemInfo.Timestamp)" -ForegroundColor Cyan
        }
        
        'JSON' {
            $jsonOutput = $systemInfo | ConvertTo-Json -Depth 3
            if ($ExportPath) {
                $jsonOutput | Out-File -FilePath $ExportPath -Encoding UTF8
                Write-Host "System information exported to: $ExportPath" -ForegroundColor Green
            } else {
                Write-Output $jsonOutput
            }
        }
        
        'CSV' {
            $csvOutput = New-Object PSObject -Property $systemInfo
            if ($ExportPath) {
                $csvOutput | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
                Write-Host "System information exported to: $ExportPath" -ForegroundColor Green
            } else {
                $csvOutput | ConvertTo-Csv -NoTypeInformation
            }
        }
    }
    
    Write-Host "`nSystem information gathering completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred while gathering system information: $($_.Exception.Message)"
    exit 1
}