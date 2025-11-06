# PowerShell Scripts Collection

A comprehensive collection of PowerShell scripts for automation, system administration, and WebView2 troubleshooting.

## 🚀 Available Scripts

### Core System Scripts
- **`src/Hello-World.ps1`** - Simple greeting script with system information display
- **`src/Get-SystemInfo.ps1`** - Comprehensive system information gathering with export options
- **`src/Backup-Files.ps1`** - File and directory backup utility with compression support

### WebView2 Management Scripts
- **`src/EdgeClean.ps1`** - Launch Microsoft Edge in clean state for testing and restore settings
- **`src/Get-WebView2Processes.ps1`** - List WebView2 processes with memory usage and export options
- **`src/Detect-Blocking-Window.ps1`** - Detect blocking windows in applications
- **`src/Dump-HostWebView2AndBlockingWindow.ps1`** - Advanced WebView2 diagnostics and window detection

## 📋 Prerequisites

- **Windows PowerShell 5.1** or **PowerShell 7+**
- **Appropriate execution policy** (see troubleshooting section below)
- **Administrator privileges** may be required for some scripts

## ⚡ Quick Start

1. **Download/Clone the repository**
2. **Open PowerShell** in the project directory
3. **Handle execution policy** (see troubleshooting section if needed)
4. **Run any script:**
   ```powershell
   .\src\Hello-World.ps1
   ```

## 🛠️ Troubleshooting Execution Policy Issues

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

### ⚠️ Important Notes:
- **Administrator privileges** may be required for some policy changes
- **Same session**: When using Method 2, ensure all operations are in the same PowerShell prompt
- **Confirmation required**: You may need to confirm policy changes with 'Y' (Yes)
- **Security consideration**: Only run scripts from trusted sources

## 📖 Script Usage Examples

### Hello World Script
```powershell
# Basic usage
.\src\Hello-World.ps1

# With custom name
.\src\Hello-World.ps1 -Name "PowerShell User"
```

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

### Backup Files Utility
```powershell
# Basic backup
.\src\Backup-Files.ps1 -SourcePath "C:\Important\Documents" -DestinationPath "D:\Backups"

# Multiple sources with timestamp and compression
.\src\Backup-Files.ps1 -SourcePath @("C:\File1.txt", "C:\Folder1") -DestinationPath "D:\Backups" -IncludeTimestamp -CompressBackup
```

## 🔧 Development

### Project Structure
```
├── .github/                 # GitHub specific files and workflows
├── src/                     # PowerShell scripts
│   ├── Hello-World.ps1
│   ├── Get-SystemInfo.ps1
│   ├── Backup-Files.ps1
│   ├── EdgeClean.ps1
│   ├── Get-WebView2Processes.ps1
│   └── ...
├── tests/                   # Test scripts (Pester tests)
├── docs/                    # Documentation
├── .gitignore              # Git ignore file
├── LICENSE                 # License file
└── README.md               # This file
```

### Contributing Guidelines

1. **Follow PowerShell best practices** - See `docs/Development-Guide.md`
2. **Include comment-based help** for all functions
3. **Add appropriate error handling** with try-catch blocks
4. **Test scripts thoroughly** before committing
5. **Update documentation** when adding new scripts

### Running Tests
```powershell
# Install Pester if needed
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run tests
Invoke-Pester .\tests\
```

## 📞 Support

If you encounter issues:

1. **Check execution policy** (see troubleshooting section above)
2. **Run as Administrator** if the script requires elevated privileges
3. **Check prerequisites** for each specific script
4. **Review error messages** and script documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🎯 Common Use Cases

- **System Administration**: Monitor system resources and gather information
- **WebView2 Troubleshooting**: Debug WebView2 applications and processes  
- **Development Testing**: Clean browser environments for testing
- **Backup & Maintenance**: Automated file backup and system maintenance
- **Reporting**: Generate HTML/CSV reports for process monitoring