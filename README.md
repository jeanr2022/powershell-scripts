# PowerShell Scripts Collection

A collection of PowerShell scripts for system administration and WebView2 troubleshooting.

## Disclaimer

**IMPORTANT: Please read before using these scripts**

These PowerShell scripts have been created for specific troubleshooting and diagnostic purposes. While they have been developed following PowerShell best practices, please note:

- These scripts are provided "AS IS" without warranty of any kind, express or implied
- They have been tested in limited scenarios and may not cover all edge cases or system configurations
- Use these scripts at your own risk
- It is recommended to test scripts in a non-production environment first
- Always review the script code before execution to understand what changes will be made to your system
- Some scripts modify system settings (registry, scheduled tasks, etc.) - ensure you understand the impact
- Back up important data and configurations before running scripts that make system changes
- The authors and contributors are not liable for any damages or issues arising from the use of these scripts

For production or enterprise use, thoroughly test these scripts in your specific environment and consider adapting them to your organization's standards and requirements.

---

## Available Scripts (in `src/` folder)

### **Get-SystemInfo.ps1**
Comprehensive system information gathering with export options (Console, JSON, CSV)

### **EdgeClean.ps1**
Launch Microsoft Edge in clean state for testing and restore original settings

### **Get-WebView2Processes.ps1**
List WebView2 processes with memory usage and export options (Console, CSV, HTML)

### **Check-EdgeUpdaterTasks.ps1**
Check Microsoft Edge updater scheduled tasks and optionally re-enable them if disabled

---

## Prerequisites

- Windows PowerShell 5.1 or PowerShell 7+
- Appropriate execution policy (see troubleshooting section below)
- Administrator privileges may be required for some scripts

## Quick Start

1. Download or clone the repository
2. Open PowerShell in the project directory
3. Handle execution policy if needed (see troubleshooting section below)
4. Run any script:
   ```powershell
   .\src\Get-SystemInfo.ps1
   ```

## Troubleshooting Execution Policy Issues

If you receive an error about execution policies when trying to run scripts, this is due to Windows security settings that block unsigned scripts. Here are the solutions:

### Method 1: Unblock Downloaded Files (Recommended)
If you downloaded the script from the internet:
```powershell
# Unblock a specific script (adjust path as needed)
Unblock-File -Path "C:\path\to\your\script.ps1"

# Or unblock all PowerShell scripts in the current directory
Get-ChildItem -Path .\src\*.ps1 | Unblock-File
```

### Method 2: Temporary Execution Policy Bypass
For a single PowerShell session:
```powershell
# Set execution policy for current session only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Then run your script
.\src\YourScript.ps1
```

### Method 3: Permanent User-Level Policy Change
For your user account (more permanent):
```powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Method 4: Run with Policy Bypass (One-time)
Run a single script with policy bypass:
```powershell
powershell -ExecutionPolicy Bypass -File ".\src\YourScript.ps1"
```

### Important Notes:
- Administrator privileges may be required for some policy changes
- When using Method 2, ensure all operations are in the same PowerShell prompt
- You may need to confirm policy changes with 'Y' (Yes)
- Only run scripts from trusted sources

## Script Usage Examples

### System Information Script
```powershell
# Display in console
.\src\Get-SystemInfo.ps1

# Export to JSON
.\src\Get-SystemInfo.ps1 -OutputFormat JSON -ExportPath "C:\temp\sysinfo.json"

# Export to CSV
.\src\Get-SystemInfo.ps1 -OutputFormat CSV -ExportPath "C:\temp\sysinfo.csv"
```

### WebView2 Process Monitor
```powershell
# Display in console
.\src\Get-WebView2Processes.ps1

# Export to CSV
.\src\Get-WebView2Processes.ps1 -ExportToCsv

# Export to HTML report
.\src\Get-WebView2Processes.ps1 -ExportToHtml

# Export to specific file
.\src\Get-WebView2Processes.ps1 -ExportToHtml -HtmlPath "C:\Reports\WebView2_Report.html"
```

### Edge Clean Utility
```powershell
# Start Edge in clean mode
.\src\EdgeClean.ps1

# With logging enabled
.\src\EdgeClean.ps1 EdgeClean -EnableLogging

# With performance isolation
.\src\EdgeClean.ps1 EdgeClean -PerformanceIsolation

# Restore original settings
.\src\EdgeClean.ps1 EdgeRestore
```

### Edge Updater Task Checker
```powershell
# Check Edge updater tasks and prompt to enable if disabled
.\src\Check-EdgeUpdaterTasks.ps1

# Check only mode (no changes)
.\src\Check-EdgeUpdaterTasks.ps1 -CheckOnly

# Auto-enable all disabled tasks (requires admin)
.\src\Check-EdgeUpdaterTasks.ps1 -AutoEnable
```

## Development

### Project Structure
```
├── .github/                 # GitHub specific files and workflows
├── src/                     # PowerShell scripts
│   ├── Get-SystemInfo.ps1
│   ├── EdgeClean.ps1
│   ├── Get-WebView2Processes.ps1
│   └── Check-EdgeUpdaterTasks.ps1
├── tests/                   # Test scripts (Pester tests)
├── docs/                    # Documentation
├── .gitignore              # Git ignore file
├── LICENSE                 # License file
└── README.md               # This file
```

### Contributing Guidelines

1. Follow PowerShell best practices - See `docs/Development-Guide.md`
2. Include comment-based help for all functions
3. Add appropriate error handling with try-catch blocks
4. Test scripts thoroughly before committing
5. Update documentation when adding new scripts

### Running Tests
```powershell
# Install Pester if needed
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run tests
Invoke-Pester .\tests\
```

## Support

If you encounter issues:

1. Check execution policy (see troubleshooting section above)
2. Run as Administrator if the script requires elevated privileges
3. Check prerequisites for each specific script
4. Review error messages and script documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Common Use Cases

- System Administration: Monitor system resources and gather information
- WebView2 Troubleshooting: Debug WebView2 applications and processes  
- Development Testing: Clean browser environments for testing
- Reporting: Generate HTML/CSV reports for process monitoring
- Update Management: Ensure Edge updater tasks are enabled for security updates