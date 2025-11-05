# PowerShell Script Project

A collection of PowerShell scripts for various automation tasks.

## Description

This project contains PowerShell scripts designed to help with common administrative and automation tasks. Each script is self-contained and includes proper documentation and error handling.

## Prerequisites

- Windows PowerShell 5.1 or PowerShell 7+
- Appropriate execution policy set (see [About Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies))

## Scripts

- `src/Hello-World.ps1` - A simple "Hello World" script to demonstrate basic PowerShell functionality
- `src/Get-SystemInfo.ps1` - Retrieves basic system information
- `src/Backup-Files.ps1` - Creates backups of specified directories

## Getting Started

1. Clone this repository
2. Open PowerShell in the project directory
3. Set execution policy if needed:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
4. Run any script:
   ```powershell
   .\src\Hello-World.ps1
   ```

## Development

### Project Structure
```
├── .github/                 # GitHub specific files
├── src/                     # PowerShell scripts
├── tests/                   # Test scripts (Pester tests)
├── docs/                    # Documentation
├── .gitignore              # Git ignore file
├── LICENSE                 # License file
└── README.md               # This file
```

### Contributing

1. Follow PowerShell best practices
2. Include comment-based help for all functions
3. Add appropriate error handling
4. Test scripts before committing

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.