<#
.SYNOPSIS
    Lists all WebView2 processes with memory usage and filtered command line parameters.

.DESCRIPTION
    This script discovers all running msedgewebview2.exe processes and displays them
    sorted by memory usage. It extracts specific command line parameters that are
    most relevant for WebView2 debugging:
    - --webview-exe-name: Shows which application is hosting the WebView2
    - --type: Shows the process type (browser, renderer, utility, etc.)
    
    The script uses multiple methods to retrieve command line parameters, as WMI
    access can be restricted depending on process ownership and security settings.

.PARAMETER ExportToCsv
    Export the results to a CSV file instead of displaying on console.

.PARAMETER CsvPath
    Specify the path for the CSV export file. If not provided, defaults to 
    "WebView2Processes_YYYYMMDD_HHMMSS.csv" in the current directory.

.PARAMETER ExportToHtml
    Export the results to an HTML file instead of displaying on console.

.PARAMETER HtmlPath
    Specify the path for the HTML export file. If not provided, defaults to 
    "WebView2Processes_YYYYMMDD_HHMMSS.html" in the current directory.

.NOTES
    Author: PowerShell Script Project
    Date: November 2025
    Version: 1.1
    
    ADMIN PRIVILEGES:
    - NOT required for basic process enumeration
    - MAY be required to access command line parameters for processes running
      under different user accounts or with elevated privileges
    - If command line shows "[Command line not accessible]", try running as Administrator

.EXAMPLE
    .\Get-WebView2Processes.ps1
    Lists all WebView2 processes with memory usage and relevant command parameters

.EXAMPLE
    .\Get-WebView2Processes.ps1 -ExportToCsv
    Exports WebView2 process information to a timestamped CSV file

.EXAMPLE
    .\Get-WebView2Processes.ps1 -ExportToCsv -CsvPath "C:\Reports\WebView2_Report.csv"
    Exports to a specific CSV file path

.EXAMPLE
    .\Get-WebView2Processes.ps1 -ExportToHtml
    Exports WebView2 process information to a timestamped HTML file

.EXAMPLE
    .\Get-WebView2Processes.ps1 -ExportToHtml -HtmlPath "C:\Reports\WebView2_Report.html"
    Exports to a specific HTML file path

.EXAMPLE
    # Run as Administrator for full access to all process command lines
    Start-Process PowerShell -Verb RunAs -ArgumentList "-File .\Get-WebView2Processes.ps1"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$ExportToCsv,
    
    [Parameter(Mandatory = $false)]
    [string]$CsvPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportToHtml,
    
    [Parameter(Mandatory = $false)]
    [string]$HtmlPath
)

# Get all msedgewebview2.exe processes using both WMI and Get-Process
$processes = Get-Process -Name "msedgewebview2" -ErrorAction SilentlyContinue

if (-not $processes) {
    Write-Host "No WebView2 processes found." -ForegroundColor Yellow
    exit
}

Write-Host "Found $($processes.Count) WebView2 process(es):`n" -ForegroundColor Green

# Sort by memory usage (WorkingSet64)
$sortedProcesses = $processes | Sort-Object WorkingSet64 -Descending

# Initialize array to collect process data for CSV export
$processData = @()

foreach ($proc in $sortedProcesses) {
    # Convert size to MB
    $sizeMB = [Math]::Round($proc.WorkingSet64 / 1MB, 2)
    
    # Get executable path and version information
    try {
        $exePath = $proc.Path
        if ($exePath -and (Test-Path $exePath)) {
            $fileVersion = (Get-ItemProperty $exePath).VersionInfo.FileVersion
            if ([string]::IsNullOrEmpty($fileVersion)) {
                $fileVersion = (Get-ItemProperty $exePath).VersionInfo.ProductVersion
            }
        } else {
            $exePath = "[Path not accessible]"
            $fileVersion = "[Version not accessible]"
        }
    }
    catch {
        $exePath = "[Path not accessible]"
        $fileVersion = "[Version not accessible]"
    }
    
    # Try to get command line using WMI for this specific process
    try {
        $wmiProc = Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue
        $cmdLine = $wmiProc.CommandLine
        
        if ([string]::IsNullOrEmpty($cmdLine)) {
            # Alternative method using WMI Win32_Process
            $wmiProc2 = Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue
            $cmdLine = $wmiProc2.CommandLine
        }
    }
    catch {
        $cmdLine = $null
    }
    
    # Extract only --webview-exe-name and --type from CommandLine
    if ($cmdLine) {
        $cmdParams = ($cmdLine | Select-String -Pattern '--webview-exe-name[=\s]+[^\s]+|--type[=\s]+[^\s]+' -AllMatches).Matches.Value -join ' '
        
        # Clean up the parameters (remove extra spaces and format consistently)
        $cmdParams = $cmdParams -replace '--webview-exe-name[=\s]+', '--webview-exe-name=' -replace '--type[=\s]+', '--type='
        
        # Extract host process name from --webview-exe-name parameter
        if ($cmdLine -match '--webview-exe-name[=\s]+([^\s]+)') {
            $hostProcess = $matches[1]
            # Remove path if present and keep only the executable name
            $hostProcess = Split-Path -Leaf $hostProcess
        } else {
            $hostProcess = "[Not specified]"
        }
    } else {
        $cmdParams = "[Command line not accessible]"
        $hostProcess = "[Not accessible]"
    }

    # Create process data object for potential CSV export
    $processInfo = [PSCustomObject]@{
        ProcessId = $proc.Id
        ProcessName = $proc.ProcessName
        HostProcess = $hostProcess
        MemoryMB = $sizeMB
        FileVersion = $fileVersion
        ExecutablePath = $exePath
        Parameters = $cmdParams
        StartTime = if ($proc.StartTime) { $proc.StartTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "Unknown" }
    }
    $processData += $processInfo

    if (-not $ExportToCsv -and -not $ExportToHtml) {
        # Display process information with enhanced details (console output)
        Write-Host ("PID: {0} | Host: {1} | Size: {2} MB | Version: {3}" -f $proc.Id, $hostProcess, $sizeMB, $fileVersion) -ForegroundColor Cyan
        Write-Host ("  Path: {0}" -f $exePath) -ForegroundColor Gray
        Write-Host ("  Params: {0}" -f $cmdParams) -ForegroundColor White
        Write-Host "" # Empty line for better readability
    }
}

# Handle CSV export
if ($ExportToCsv) {
    # Generate default CSV filename if not provided
    if ([string]::IsNullOrEmpty($CsvPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $CsvPath = "WebView2Processes_$timestamp.csv"
    }
    
    try {
        # Export to CSV
        $processData | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "WebView2 process data exported successfully to: $CsvPath" -ForegroundColor Green
        Write-Host "Total processes exported: $($processData.Count)" -ForegroundColor Green
        
        # Show first few entries as preview
        if ($processData.Count -gt 0) {
            Write-Host "`nPreview of exported data:" -ForegroundColor Yellow
            $processData | Select-Object ProcessId, HostProcess, MemoryMB, FileVersion | Format-Table -AutoSize
        }
    }
    catch {
        Write-Error "Failed to export CSV: $($_.Exception.Message)"
        Write-Host "Falling back to console output..." -ForegroundColor Yellow
        
        # Display on console as fallback
        foreach ($proc in $processData) {
            Write-Host ("PID: {0} | Size: {1} MB | Version: {2}" -f $proc.ProcessId, $proc.MemoryMB, $proc.FileVersion) -ForegroundColor Cyan
            Write-Host ("  Path: {0}" -f $proc.ExecutablePath) -ForegroundColor Gray
            Write-Host ("  Params: {0}" -f $proc.Parameters) -ForegroundColor White
            Write-Host ""
        }
    }
}

# Handle HTML export
if ($ExportToHtml) {
    # Generate default HTML filename if not provided
    if ([string]::IsNullOrEmpty($HtmlPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $HtmlPath = "WebView2Processes_$timestamp.html"
    }
    
    try {
        # Generate HTML content
        $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WebView2 Processes Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background-color: #0078d4;
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .header p {
            margin: 5px 0 0 0;
            opacity: 0.9;
        }
        .summary {
            background-color: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background-color: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        th {
            background-color: #0078d4;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #e1e1e1;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        tr:hover {
            background-color: #e3f2fd;
        }
        .process-id {
            font-weight: bold;
            color: #0078d4;
        }
        .host-process {
            font-weight: 600;
            color: #107c10;
        }
        .memory {
            text-align: center;
            font-weight: 600;
        }
        .path {
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 12px;
            color: #666;
            word-break: break-all;
        }
        .params {
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 12px;
            background-color: #f0f0f0;
            padding: 4px 8px;
            border-radius: 4px;
        }
        .version {
            font-weight: 600;
            color: #16537e;
        }
        .footer {
            margin-top: 20px;
            text-align: center;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>WebView2 Processes Report</h1>
        <p>Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Total Processes: $($processData.Count)</p>
    </div>
    
    <div class="summary">
        <h3>Summary</h3>
        <p><strong>Total WebView2 Processes:</strong> $($processData.Count)</p>
        <p><strong>Total Memory Usage:</strong> $([Math]::Round(($processData | Measure-Object -Property MemoryMB -Sum).Sum, 2)) MB</p>
        <p><strong>Unique Versions:</strong> $(($processData | Select-Object -Property FileVersion -Unique | Where-Object { $_.FileVersion -ne "[Version not accessible]" }).Count)</p>
    </div>
    
    <table>
        <thead>
            <tr>
                <th>Process ID</th>
                <th>Host Process</th>
                <th>Memory (MB)</th>
                <th>Version</th>
                <th>Start Time</th>
                <th>Executable Path</th>
                <th>Parameters</th>
            </tr>
        </thead>
        <tbody>
"@

        # Function to encode HTML special characters
        function ConvertTo-HtmlEncoded {
            param([string]$Text)
            if ([string]::IsNullOrEmpty($Text)) { return $Text }
            return $Text -replace "&", "&amp;" -replace "<", "&lt;" -replace ">", "&gt;" -replace '"', "&quot;" -replace "'", "&#39;"
        }

        # Add table rows
        foreach ($proc in $processData) {
            $htmlContent += @"
            <tr>
                <td class="process-id">$($proc.ProcessId)</td>
                <td class="host-process">$(ConvertTo-HtmlEncoded $proc.HostProcess)</td>
                <td class="memory">$($proc.MemoryMB)</td>
                <td class="version">$(ConvertTo-HtmlEncoded $proc.FileVersion)</td>
                <td>$($proc.StartTime)</td>
                <td class="path">$(ConvertTo-HtmlEncoded $proc.ExecutablePath)</td>
                <td class="params">$(ConvertTo-HtmlEncoded $proc.Parameters)</td>
            </tr>
"@
        }

        # Close HTML
        $htmlContent += @"
        </tbody>
    </table>
    
    <div class="footer">
        <p>Report generated by Get-WebView2Processes.ps1</p>
    </div>
</body>
</html>
"@

        # Write HTML to file
        $htmlContent | Out-File -FilePath $HtmlPath -Encoding UTF8
        
        Write-Host "WebView2 process data exported successfully to: $HtmlPath" -ForegroundColor Green
        Write-Host "Total processes exported: $($processData.Count)" -ForegroundColor Green
        Write-Host "You can open this file in any web browser to view the report." -ForegroundColor Yellow
        
    }
    catch {
        Write-Error "Failed to export HTML: $($_.Exception.Message)"
        Write-Host "Falling back to console output..." -ForegroundColor Yellow
        
        # Display on console as fallback
        foreach ($proc in $processData) {
            Write-Host ("PID: {0} | Size: {1} MB | Version: {2}" -f $proc.ProcessId, $proc.MemoryMB, $proc.FileVersion) -ForegroundColor Cyan
            Write-Host ("  Path: {0}" -f $proc.ExecutablePath) -ForegroundColor Gray
            Write-Host ("  Params: {0}" -f $proc.Parameters) -ForegroundColor White
            Write-Host ""
        }
    }
}